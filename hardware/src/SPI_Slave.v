// Refer https://github.com/vicharak-in/Gati/issues/220
// WARNING: DATA_WIDTH_OUT >= DATA_WIDTH_IN

module SPI_Slave #(
    parameter DATA_WIDTH_OUT = 128, //bits
    parameter DATA_WIDTH_IN = 32    //bits
)(
    // System signals
    input  wire clk,           
    input  wire rst_n,           
    
    // SPI interface
    input  wire sclk,
    input  wire mosi,
    output reg  miso,
    input  wire cs_n, 

    input spi_fifo_empty,
    input spi_fifo_rd_valid,
    input [31:0] spi_fifo_rd_data,
    output reg spi_fifo_rd_en = 0,
       
    // output reg  [DATA_WIDTH_OUT-1:0] rx_data,
    // outptu reg rx_valid,                    
    
    input [31:0] i_data, 
    input i_data_valid,
    input fifo_empty,
    input [9:0] rd_datacount,
    output reg fifo_rden

);
    wire cpol;
    wire cpha;
    
    // SPI Mode
    assign cpol = 1'b0;
    assign cpha = 1'b0;

    reg [DATA_WIDTH_OUT-1:0] tx_data;
    reg [4:0] counter0;   // For i_data_valid
    reg padding_done;

    
    // Internal signals
    reg [2:0] sclk_sync;       
    reg [2:0] cs_n_sync;       
    reg sclk_prev;             
    reg cs_active;             
    
    // Shift registers
    reg [DATA_WIDTH_OUT-1:0] tx_shift_reg;
    //reg [DATA_WIDTH_OUT-1:0] rx_shift_reg;
    
    // Bit counter
    reg [$clog2(DATA_WIDTH_OUT):0] bit_count;
    
    // Edge detection
    wire sclk_posedge, sclk_negedge;
    wire sample_edge, shift_edge;
    wire cs_falling, cs_rising;
    
    // Synchronize external signals to system clock
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b000;
            cs_n_sync <= 3'b111;
        end else begin
            sclk_sync <= {sclk_sync[1:0], sclk};
            cs_n_sync <= {cs_n_sync[1:0], cs_n};
        end
    end
    
    // Edge detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_prev <= 1'b0;
        end else begin
            sclk_prev <= sclk_sync[2];
        end
    end
    
    assign sclk_posedge = !sclk_prev && sclk_sync[2];
    assign sclk_negedge = sclk_prev && !sclk_sync[2];
    assign cs_falling = cs_n_sync[2:1] == 2'b10;
    assign cs_rising = cs_n_sync[2:1] == 2'b01;
    
    // Determine sampling and shifting edges based on CPOL and CPHA
    assign sample_edge = (cpol == cpha) ? sclk_posedge : sclk_negedge;
    assign shift_edge = (cpol == cpha) ? sclk_negedge : sclk_posedge;
    
    // Chip select active detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cs_active <= 1'b0;
        end else begin
            if (cs_falling) begin
                cs_active <= 1'b1;
            end else if (cs_rising) begin
                cs_active <= 1'b0;
            end
        end
    end
    
    // Bit counter
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        bit_count <= {($clog2(DATA_WIDTH_OUT)+1){1'b0}};
      end else begin
        if (!cs_active) begin
          bit_count <= {($clog2(DATA_WIDTH_OUT)+1){1'b0}};
        end else if (sample_edge && cs_active) begin
          if (bit_count == DATA_WIDTH_OUT - 1) begin
            bit_count <= {($clog2(DATA_WIDTH_OUT)+1){1'b0}};
          end else begin
            bit_count <= bit_count + 1;
          end
        end
      end
    end
    
    // Transmit shift register and MISO output
    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        tx_shift_reg <= {DATA_WIDTH_OUT{1'b0}};
        miso <= 1'b0;
        counter0 <= 1'b0;
        tx_data <= {DATA_WIDTH_OUT{1'b0}};
      end else begin
        if (cs_falling) begin
          tx_shift_reg <= tx_data;
          miso <= tx_data[DATA_WIDTH_OUT-1];
        end else if (shift_edge && cs_active) begin
          tx_shift_reg <= {tx_shift_reg[DATA_WIDTH_OUT-2:0], 1'b0};
          miso <= tx_shift_reg[DATA_WIDTH_OUT-2];
        end else if (!cs_active) begin
          miso <= 1'b0;
        end

        if (clear_buffer) begin
          tx_data <= {DATA_WIDTH_OUT{1'b0}};
        end

        if(i_data_valid) begin
          padding_done <= 1'b0;
          tx_data [(DATA_WIDTH_OUT-1)-(counter0*DATA_WIDTH_IN) -: DATA_WIDTH_IN] <= i_data;
          if (counter0 < ((DATA_WIDTH_OUT/DATA_WIDTH_IN)-1)) begin
            counter0 <= counter0 + 1;
          end else begin
            counter0 <= 0;
          end
        end else if ((data_cnt == 32'd0) && (state == SEND) && (padding_done == 0)) begin
          tx_data [(DATA_WIDTH_OUT-1)-(counter0*DATA_WIDTH_IN) -: DATA_WIDTH_IN] <= {DATA_WIDTH_IN{1'b0}};
          if (counter0 < ((DATA_WIDTH_OUT/DATA_WIDTH_IN)-1)) begin
            counter0 <= counter0 + 1;
          end else begin
            counter0 <= 0;
            padding_done <= 1'b1;
          end
        end else begin
          counter0 <= counter0;
          padding_done <= padding_done;
        end
      end
    end 

    reg [4:0] counter1;   // For fifo_rden
    reg [2:0] counter2; 
    reg [31:0] data_cnt;  // Total data to be sent
    reg clear_buffer;

    reg [1:0] state = 0;
    localparam IDLE = 2'b00;
    localparam FILL = 2'b01;
    localparam SEND = 2'b10;

    reg rd_en_cond;  // For generating one-pluse SPI FIFO rd_en

    always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
        fifo_rden <= 0;
        counter1 <= 0;
        counter2 <= 0;
        state <= IDLE;
        data_cnt <= 0;
        clear_buffer <= 0;
        rd_en_cond <= 0;
        spi_fifo_rd_en <= 0;
      end else begin 
        
        if (spi_fifo_rd_valid) begin
          data_cnt <= spi_fifo_rd_data;
        end

        case(state)
          IDLE: begin
            clear_buffer <= 0;
            if (rd_datacount > 10)  begin 
              if (counter2 <= 6) begin
                fifo_rden <= 1'b0;
                counter1 <= 0;
                counter2 <= counter2 + 1'b1;
                state <= IDLE;
              end else begin
                fifo_rden <= 1'b0;
                counter1 <= 0;
                counter2 <= 0;
                state <= FILL;
              end
            end else begin
              fifo_rden <= 1'b0;
              counter1 <= 0;
              counter2 <= 0;
              state <= IDLE;
            end
          end
        
          FILL: begin
            clear_buffer <= 0;
            if (data_cnt <= (DATA_WIDTH_OUT/8)) begin
              if (data_cnt != 0) begin
                fifo_rden <= 1;
                state <= FILL;
                counter1 <= counter1 + 1;
                data_cnt <= data_cnt - (DATA_WIDTH_IN/8);
              end else begin
                fifo_rden <= 1'b0;
                counter1 <= 0;
                state <= SEND;
              end 
            end else begin
              if (counter1 < (DATA_WIDTH_OUT/DATA_WIDTH_IN)) begin
                fifo_rden <= 1'b1;
                counter1 <= counter1 + 1;
                state <= FILL; 
              end else begin
                fifo_rden <= 1'b0;
                counter1 <= 1'b0;
                state <= SEND;
              end
            end
          end
          
          SEND: begin
            if (cs_falling) begin
              fifo_rden <= 1'b0;
              counter1 <= 1'b0;
              state <= FILL;
              clear_buffer <= 0; 
              if (data_cnt >= (DATA_WIDTH_OUT/8)) begin 
                data_cnt <= data_cnt - (DATA_WIDTH_OUT/8);
              end else begin
                data_cnt <= 0;
                state <= IDLE;
                fifo_rden <= 0;
                clear_buffer <= 1;
              end
            end else begin
              fifo_rden <= 1'b0;
              counter1 <= 1'b0;
              state <= SEND;
              clear_buffer <= 0;
            end
          end

          default: begin
            fifo_rden <= 0;
            counter1 <= 0;
            state <= IDLE;
            data_cnt <= 0;
            clear_buffer <= 0;
          end
        endcase

        rd_en_cond <= (state == IDLE) & (!spi_fifo_empty);
        spi_fifo_rd_en <= (state == IDLE) & (!spi_fifo_empty) & (!rd_en_cond);

      end
    end
    

    // // Receive shift register
    // always @(posedge clk or negedge rst_n) begin
    //   if (!rst_n) begin
    //     rx_shift_reg <= {DATA_WIDTH_OUT{1'b0}};
    //     rx_valid <= 0;
    //   end else begin
    //     rx_valid <= sample_edge && cs_active && (bit_count == DATA_WIDTH - 1);
    //     if (sample_edge && cs_active) begin
    //       rx_shift_reg <= {rx_shift_reg[DATA_WIDTH_OUT-2:0], mosi};
    //     end
    //   end
    // end
    
    // // Output received data
    // always @(posedge clk or negedge rst_n) begin
    //   if (!rst_n) begin
    //     rx_data <= {DATA_WIDTH_OUT{1'b0}};
    //   end else begin
    //     if (sample_edge && cs_active && (bit_count == DATA_WIDTH_OUT - 1)) begin
    //       rx_data <= {rx_shift_reg[DATA_WIDTH_OUT-2:0], mosi};
    //     end
    //   end
    // end

endmodule

