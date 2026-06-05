module meta_app #(
  parameter RAH_PACKET_WIDTH = 48
)(
	input  clk,
	input  i_empty,
	input  [RAH_PACKET_WIDTH-1:0] i_data,
	input  i_rd_valid,
	output o_rd_en,
	output o_valid_size,
	output [RAH_PACKET_WIDTH-1:0] o_data_size,
	output o_rst,
	output o_uart_en,
	output o_rah_dispatch,
	output o_spi_en
);

`include "../gati/src/rtl/common/instructions.vh"

// FSM States
localparam IDLE = 3'b000;
localparam CHECK = 3'b001;
localparam DISPATCH = 3'b011;
localparam WAIT_SOF = 3'b100;
localparam VALIDATE = 3'b101;


reg [2:0] next_state = IDLE;
reg [RAH_PACKET_WIDTH-1:0] data_size = 48'b0;
reg uart_en = 0;
reg spi_en = 0;
reg rah_dispatch ;
reg valid_size =0;
reg reset = 1;
reg enable =0;
reg rd_en =0;
reg meta_data =0;

reg need_read;

// FSM Logic
always @(posedge clk) begin
 
    case (next_state)       
        IDLE: begin       
            meta_data <=0;
            enable <= 0;
            reset <= 1;
            data_size <= 48'b0;
            valid_size <= 1'b0;
            if (~i_empty) begin
                rd_en <= 1'b1;
                next_state <= WAIT_SOF;
                need_read <= 0;
            end else begin
                rd_en <= 0;
                next_state <= IDLE;
            end
        end

        WAIT_SOF: begin
            meta_data <=0;
            enable <= 0;
            reset <= 1;
            if (need_read && ~i_empty) begin 
                rd_en <=1 ;
                need_read <= 0;
            end 
            else if (!need_read) begin 
            rd_en <= 0;
                if (i_rd_valid) begin 
                    if (i_data == `META_SOP) begin
                        next_state <= CHECK;
                        if (~i_empty) begin 
                            rd_en <=1;
                        end 
                        else need_read <= 1;
                    end else begin 
                        next_state <= WAIT_SOF;  
                    end 
                end
            end    
            else begin
                next_state <= WAIT_SOF;            
            end 
        end

        CHECK: begin
            reset <=1; 
            if (need_read && ~i_empty) begin 
                rd_en <=1 ;
                need_read <= 0;
            end 
            else if (!need_read) begin
                rd_en <= 1'b0;
                if (i_rd_valid) begin
                    if (i_data == 48'h0) 
                    begin
                        next_state <= VALIDATE;
                        enable <= 1; // Enable when i_data is 48'h0
                        if (~i_empty) begin 
                            rd_en <=1;
                        end 
                        else need_read <= 1;
                    end 
                    else begin
                        enable <= 0;                    //6
                        next_state <= VALIDATE;
                        if (~i_empty) begin 
                            rd_en <=1;
                        end 
                        else need_read <= 1;
                    end
                end 
                else next_state <= CHECK;
            end 
            else   
            begin 
                next_state <= CHECK; 
            end
        end

        VALIDATE: begin   
            reset <= 1'b1;
            meta_data <= 1'b0; // Explicitly setting default for meta_data
            next_state <= VALIDATE;
            if (need_read && ~i_empty) begin 
                rd_en <=1 ;
                need_read <= 0;
            end 
            else if (!need_read)begin 
                rd_en <= 1'b0;
                if (i_rd_valid) begin
                    if (enable) begin
                        enable <= 0;
                        if (i_data == `META_TYPE_RESET) begin                 
                            reset <= 1'b0;
                            next_state <= IDLE;
                            rd_en <= 1;
                        end else begin
                            reset <= 1'b1;
                            next_state <= WAIT_SOF;
                            if (~i_empty) begin 
                                rd_en <=1;
                            end 
                            else need_read <= 1;
                        end
                    end else begin
                        case (i_data)
                            `META_TYPE_DISPATCH: begin // Type 1: Dispatch
                                next_state <= DISPATCH;
                                reset <= 1'b1;
                                if (~i_empty) begin 
                                    rd_en <=1;
                                end 
                                else need_read <= 1;
                            end
                            `META_TYPE_PAYLOAD_SIZE: begin // Type 2: Payload Size
                                meta_data <= 1;
                                next_state <= DISPATCH;
                                if (~i_empty) begin 
                                    rd_en <=1;
                                end 
                                else need_read <= 1;           
                            end
                            default: begin
                                next_state <= WAIT_SOF; // Default case to handle unexpected inputs
                            end
                            //---------------------------------------------------//
                            // ADD YOUR NEW TYPE HERE ---------------------------//
                            //---------------------------------------------------//
                        endcase
                    end
                end
            end


        end

        DISPATCH: begin
            reset <= 1'b1;
            if (need_read && ~i_empty) begin 
                rd_en <=1 ;
                need_read <= 0;
            end 
            else if (!need_read) begin  
                rd_en <=0;
                if (i_rd_valid) begin
                    if (meta_data) begin
                        meta_data <= 0;
                        data_size <= i_data;
                        valid_size <= 1'b1;            
                    end 
                   // else begin
                     //   data_size <= 48'b0;
                       // valid_size <= 1'b0; 
                    //end
                            //DISPATCH Logic for new type --------------------------//
                            // else if(flag )   begin   logic    end----------------//
                            //------------------------------------------------------//   
                    if (meta_data) begin
                        next_state <= IDLE;
                        if(uart_en) begin
                            uart_en <= 1'b1;    
                            rah_dispatch <= 1'b0;
                            spi_en <= 1'b0;
                        end else if (spi_en) begin
                            uart_en <= 1'b0;    
                            rah_dispatch <= 1'b0;
                            spi_en <= 1'b1;
                        end else begin
                            uart_en <= 1'b0;
                            rah_dispatch <= 1'b1;
                            spi_en <= 1'b0;
                        end
                    end else begin
                        case (i_data)
                            `META_CONST_DISPATCH_UART: begin // UART Dispatch
                                uart_en <= 1'b1;
                                rah_dispatch <= 1'b0;
                                spi_en <= 1'b0;
                            end
                            `META_CONST_DISPATCH_RAH: begin // RAH Dispatch
                                uart_en <= 1'b0;
                                rah_dispatch <= 1'b1;
                                spi_en <= 1'b0;
                            end
                            `META_CONST_DISPATCH_SPI: begin // SPI Dispatch
                                uart_en <= 1'b0;
                                rah_dispatch <= 1'b0;
                                spi_en <= 1'b1;
                            end 
                            default: begin // Default to RAH Dispatch
                                uart_en <= 1'b0;
                                rah_dispatch <= 1'b1;
                                spi_en <= 1'b0;
                            end
                        endcase
                        next_state <= IDLE; // Transition to IDLE after dispatch
                    end
                end 
            end else begin
                rd_en <= 1'b0;
                next_state <= DISPATCH;
            end
        end       
    endcase    
end

// Output assignments
assign o_rd_en = rd_en;
assign o_uart_en = uart_en;
assign o_spi_en = spi_en;
assign o_rah_dispatch = rah_dispatch;
assign o_data_size = data_size;
assign o_valid_size = valid_size;
assign o_rst = reset;

endmodule