module cvt_48232 (
    input clk,
    input rd_clk,

    input [47:0] rah_data_size,
    input valid_data_size,
    
    input [8:0] rah_fifo_occupants,
    input rah_data_queue_empty,
    input rah_data_queue_almost_empty,
    input [RAH_PACKET_WIDTH-1:0] rah_data,
    output reg rah_request_data = 0,
    output reg rah_request_datasize = 0,

    input rd_enable,
    
    output data_queue_empty,
    output data_queue_almost_empty,
    output [DATA_WIDTH-1:0] data,
    output valid_32
);

parameter RAH_PACKET_WIDTH = 48;
parameter DATA_WIDTH = 32;
parameter DATA_LEN_WIDTH = 24;

reg fifo_we = 0;
reg [DATA_WIDTH-1:0] w_data = 0;
reg [RAH_PACKET_WIDTH-1:0] r_data = 0;
reg [3:0] state = 0;
reg [3:0] prev_state = 0;
reg [1:0] cnt = 2;
reg if_MSB = 0;
reg delayed_data_queue_empty = 0;
reg take_last_data = 0;
wire valid_32;

// reg [DATA_LEN_WIDTH-1:0] rah_packet_length_f1, rah_packet_length_f2;
// always @(posedge clk) begin
//     rah_packet_length_f1 <= rah_packet_length;
//     rah_packet_length_f2 <= rah_packet_length_f1;
// end

// reg [8:0] rah_fifo_occupants_f1,rah_fifo_occupants_f2;
// always@(posedge clk) begin
//     rah_fifo_occupants_f1 <= rah_fifo_occupants;
//     rah_fifo_occupants_f2 <= rah_fifo_occupants_f1;
// end

// reg rah_eof1,rah_eof2;
// always@(posedge clk) begin
//     rah_eof1 <= rah_eof;
//     rah_eof2 <= rah_eof1;
// end

// reg rah_eof = 0;
// reg flag = 0;
// reg r_rah_eof = 0;
// always@(posedge clk) begin
//     if(rah_eof) r_rah_eof <= 1;
//     else if(flag) r_rah_eof <= 0;
// end

async_fifo_32bit af32bit (
    .a_rst_i        (1'b0),
    .wr_clk_i       (clk),
    .wr_en_i        (fifo_we),
    .wdata          (w_data),
    .rd_clk_i       (rd_clk),
    .rd_en_i        (rd_enable),
    .rdata          (data),
    .full_o         (),
    .empty_o        (data_queue_empty),
    .almost_empty_o (data_queue_almost_empty),
    .rd_valid_o     (valid_32)
);

reg [47:0] rah_data_cnt = 0;
reg [1:0] state1 = 0;

always@(posedge clk) begin
    case(state1)
        0: begin
            if(valid_data_size) begin
                rah_data_cnt <= rah_data_size;
                state1 <= 1;
            end
        end

        1:begin
            if(rah_data_cnt==0) begin
                rah_data_cnt <= 0;
                state1 <= 0;
            end
            else if(rah_data_cnt<6) begin
                if(rah_request_data) begin
                    rah_data_cnt <= 0;
                    // state1 <= 0;
                end
            end
            else begin
                if(rah_request_data) begin
                    rah_data_cnt = rah_data_cnt-6;
                    state1 <= 1;
                end
            end
        end
    endcase
end

always @(posedge clk) begin
    prev_state <= state;
    delayed_data_queue_empty <= rah_data_queue_empty;

    case (state)
        // 0: begin
        //     if(valid_data_size) begin
        //         rah_data_cnt <= rah_data_size;
        //         state <= 1;
        //     end
        // end
        0: begin
            r_data <= 0;

            if(rah_data_cnt==0) begin
                state <= 0;
                rah_request_data <= 0;
            end
            else if(rah_data_cnt<6) begin
                state <= 4;
                rah_request_data <= 1;
            end
            else begin
                // if (~rah_data_queue_empty) begin
                if(rah_fifo_occupants>=2) begin
                    rah_request_data <= 1;
                    state <= 1;
                end
                else if(rah_fifo_occupants==1 && rah_data_cnt<6) begin
                    rah_request_data <= 1;
                    state <= 4;
                end
                else begin
                    rah_request_data <= 0;
                    state <= state;
                end
            end

            if (prev_state == 2) begin
                w_data <= {r_data[15:0], 16'h0};
                fifo_we <= 1;
            end else if (prev_state == 3) begin
                if (take_last_data) begin
                    w_data <= rah_data[31:0];
                    fifo_we <= 1;
                end else begin
                    w_data <= 16'h0;
                    fifo_we <= 0;
                end
            end else begin
                fifo_we <= 0;
                w_data <= 0;
            end
        end

        1: begin
            state <= 2;
            rah_request_data <= ~rah_data_queue_empty;

            // rah_request_data <= (rah_fifo_occupants_f2>=2);
            if (prev_state == 3) begin
                w_data <= r_data[31:0];
                fifo_we <= 1;
            end else begin
                fifo_we <= 0;
            end
        end

        2: begin
            rah_request_data <= 0;
            state <= rah_request_data ? 3 : 0;
            r_data <= rah_data;
            w_data <= rah_data[47:16];
            fifo_we <= 1;
        end

        3: begin
            r_data <= rah_data;
            fifo_we <= 1;
            // rah_request_data <= ~rah_data_queue_empty;

            rah_request_data <= (rah_fifo_occupants>=2);
            take_last_data <= ~delayed_data_queue_empty;

            // if (~rah_data_queue_empty) begin
            if (rah_fifo_occupants>=2) begin
                state <= 1;
                w_data <= {r_data[15:0], rah_data[47:32]};
            end else begin
                w_data <= {
                    r_data[15:0],
                    ~delayed_data_queue_empty ? rah_data[47:32] : 16'h0
                };
                state <= 0;
            end
        end

        4: begin
            state <= 5;
            rah_request_data <= 0;
            fifo_we <= 0;
        end

        5: begin
            rah_request_data <= 0;
            w_data <= rah_data[47:16];
            r_data <= rah_data;
            state <= 0;
            fifo_we <= 1;
        end
    endcase
end

endmodule

module cvt (
    input clk,

    input [31:0] data_size_rah,
    input data_queue_empty,
    input data_queue_almost_empty,
    input [9:0] fifo_occupants,
    input [DATA_WIDTH-1:0] data,
    output reg data_request = 0,
    input rah_dispatch,
    input rd_enable,

    input dc_fifo_empty,
    input dc_rd_valid,
    output reg dc_rd_en = 0,

    output cvt_data_queue_empty,
    output cvt_data_queue_almost_empty,
    output cvt_data_valid,
    output [RAH_PACKET_WIDTH-1:0] cvt_data
);

parameter DATA_WIDTH = 32;
parameter RAH_PACKET_WIDTH = 48;

reg [2:0] state = 0;
reg [2:0] prev_state = 0;
reg [2:0] st = 0;
reg [31:0] data_cnt = 0;
reg [29:0] rd_count = 0;
reg [47:0] w_data = 0;
reg fifo_we = 0;
reg delayed_data_request = 0;
reg [15:0] tmp_data = 0;

wire cvt_data_queue_prog_full;

async_fifo af48 (
    .a_rst_i        (1'b0),
    .wr_clk_i       (clk),
    .wr_en_i        (fifo_we),
    .wdata          (w_data),
    .rd_clk_i       (clk),
    .rd_en_i        (rd_enable),
    .rdata          (cvt_data),
    .rd_valid_o     (cvt_data_valid),
    .prog_full_o    (cvt_data_queue_prog_full),
    .empty_o        (cvt_data_queue_empty),
    .almost_empty_o (cvt_data_queue_almost_empty)
);

always @(posedge clk) begin

    delayed_data_request <= data_request;
    prev_state <= state;

    case (state)
        0: begin
            st <= 0;
            rd_count <= 0;
            data_request <= 0;
            fifo_we <= 0;
            dc_rd_en <= 0;

            if (!dc_fifo_empty & rah_dispatch) begin
                dc_rd_en <= 1;
                state <= 1;
            end
        end

        1: begin
            dc_rd_en <= 0;
            rd_count <= 0;
            data_request <= 0;
            if (dc_rd_valid) begin
                data_cnt <= data_size_rah;
                state <= 2;
            end else begin
                state <= 1;
            end
        end

        2: begin
            if ((prev_state != state) | (data_cnt > 0)) begin
                if (rd_count == (data_size_rah>>2)) begin
                    rd_count <= rd_count;
                    data_request <= 0;
                end
                else begin
                    if (cvt_data_queue_prog_full) begin
                        data_request <= 0;
                        rd_count <= rd_count;
                    end
                    else if (data_request & data_queue_almost_empty) begin
                        data_request <= 0; 
                        rd_count <= rd_count;
                    end
                    else if (~data_queue_empty) begin
                        data_request <= 1;
                        rd_count <= rd_count + 1;
                    end
                end
            end

            if (data_cnt > 4 & delayed_data_request) begin
                data_cnt <= data_cnt - 4;

                case (st)
                    0: begin
                        w_data <= {data, 16'h0};
                        fifo_we <= 0;
                        st <= 1;
                    end

                    1: begin
                        w_data[15:0] <= data[31:16];
                        tmp_data <= data[15:0];
                        fifo_we <= 1;
                        st <= 2;
                    end

                    2: begin
                        w_data[47:32] <= tmp_data;
                        w_data[31:0] <= data;
                        fifo_we <= 1;
                        st <= 0;
            // have some ack to see if the fifo actually read the data 
                    end
                endcase
            end else if (data_cnt <= 4 & delayed_data_request) begin
                data_cnt <= data_cnt - 4;
                fifo_we <= 1;

                case (st)
                    0: begin
                        w_data[47:16] <= {data, 16'h0};
                        state <= 0;
                    end

                    1: begin
                        case (data_cnt - 1)
                            0: begin
                                w_data[15:0] <= {data[31:24], 8'h0};
                                state <= 0;
                            end

                            1: begin
                                w_data[15:0] <= data[31:16];
                                state <= 0;
                            end

                            default: begin
                                w_data[15:0] <= data[31:16];
                                tmp_data <= data[15:0];
                                state <= 3;
                            end
                        endcase
                    end

                    2: begin
                        w_data <= {tmp_data, data};
                        state <= 0;
                    end
                endcase
            end else begin
                fifo_we <= 0;
            end
        end

        3: begin
            state <= 0;
            fifo_we <= 1;
            w_data <= {tmp_data, 32'h0};
        end
    endcase

end

endmodule

