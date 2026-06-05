`include "../rah-bit/rtl/rah_var_defs.vh"

module top #(parameter GATI_DATA_WIDTH=32)
	(
/* Clocks of MIPI TX and RX parallel interfaces */
    input                       rx_pixel_clk,
    input                       tx_pixel_clk,
    input                       tx_vga_clk,
	
    input                       i_clk,
    input                       s_clk,
    input                       m_clk,
    input                       clk_81mhz,
    // input                       i_rst,
/* signals used by the MIPI RX Interface Designer instance */
    input                       my_mipi_rx_VALID,
    input [3:0]                 my_mipi_rx_HSYNC,
    input [3:0]                 my_mipi_rx_VSYNC,
    input [63:0]                my_mipi_rx_DATA,
    input [5:0]                 my_mipi_rx_TYPE,
    input [1:0]                 my_mipi_rx_VC,
    input [3:0]                 my_mipi_rx_CNT,
    input [17:0]                my_mipi_rx_ERROR,
    input                       my_mipi_rx_ULPS_CLK,
    input [3:0]                 my_mipi_rx_ULPS,

    output                      my_mipi_rx_DPHY_RSTN,
    output                      my_mipi_rx_RSTN,
    output                      my_mipi_rx_CLEAR,
    output [1:0]                my_mipi_rx_LANES,
    output [3:0]                my_mipi_rx_VC_ENA,

/* Signals used by the MIPI TX Interface Designer instance */
    output                      my_mipi_tx_DPHY_RSTN,
    output                      my_mipi_tx_RSTN,
    output                      my_mipi_tx_VALID,
    output                      my_mipi_tx_HSYNC,
    output                      my_mipi_tx_VSYNC,
    output [63:0]               my_mipi_tx_DATA,
    output [5:0]                my_mipi_tx_TYPE,
    output [1:0]                my_mipi_tx_LANES,
    output                      my_mipi_tx_FRAME_MODE,
    output [15:0]               my_mipi_tx_HRES,
    output [1:0]                my_mipi_tx_VC,
    output [3:0]                my_mipi_tx_ULPS_ENTER,
    output [3:0]                my_mipi_tx_ULPS_EXIT,
    output                      my_mipi_tx_ULPS_CLK_ENTER,
    output                      my_mipi_tx_ULPS_CLK_EXIT,
    
/* Periplex Connections to the GPIOs */
    input   [ 1:0]  PllLocked ,

    output      DdrCtrl_CFG_RST_N     ,                        //(O)[Control]DDR Controner Reset(Low Active)     
    output      DdrCtrl_CFG_SEQ_RST   ,                       //(O)[Control]DDR Controner Sequencer Reset 
    output      DdrCtrl_CFG_SEQ_START ,                       //(O)[Control]DDR Controner Sequencer Start 
    output      d_done           ,

	output     uart_tx_pin,
    output     debug_pin,
    output     o_TX_Serial, //UART_Tx serial data out
    // output [31:0] mipi_fifo_data_out,
    // output [47:0] rah_data,

    input  spi_sclk,          
    input  spi_mosi,          
    output spi_miso,          
    input spi_cs_n,

    output              layer_debug_pin,
	output  [      7:0] aid     ,
    output  [     31:0] aaddr   , 
    output  [      7:0] alen    , 
    output  [      2:0] asize   , 
    output  [      1:0] aburst  , 
    output  [      1:0] alock   , 
    output              avalid  , 
    input               aready  , 
    output              atype   ,
    output  [      7:0] wid     , 
    output  [ABN_C-1:0] wstrb   , 
    output              wlast   , 
    output              wvalid  , 
    input               wready  , 
    output  [ADW_C-1:0] wdata   , 
    input   [      7:0] rid     , 
    input               rlast   , 
    input               rvalid  , 
    output              rready  , 
    input   [      1:0] rresp   , 
    input   [ADW_C-1:0] rdata   , 
    input   [      7:0] bid     , 
    input               bvalid  , 
    output              bready  ,
    //io signals
    output [6:0] kernal_count, // represents the current kernal iteration number 
    output [6:0] channel_count, // represents the current channel iteration number
    output soft_start, //user_start from top_gati_module
    output [3:0] layer_count,
    output layer_done,
    output eop,

    output [31:0] layer_cycles_count,
    output [59:0] stall_cycles_count
);
parameter   AXI_DATA_WIDTH      = 256 ;                       // Axi data width 
parameter   AXI_BYTE_NUMBER     = AXI_DATA_WIDTH/8  ;                                  
parameter   ADW_C               = AXI_DATA_WIDTH; 
parameter   ABN_C               = AXI_BYTE_NUMBER;   

parameter RAH_PACKET_WIDTH = 48;
parameter ACTIVE_VID_WIDTH = 320;
parameter ACTIVE_VID_HEIGHT = 240;
parameter TOTAL_APPS = `TOTAL_APPS + 1;


/* Rah Decoder definition for multiple Apps */
assign my_mipi_rx_DPHY_RSTN = 1'b1;
assign my_mipi_rx_RSTN = 1'b1;
assign my_mipi_rx_CLEAR = 1'b0;
assign my_mipi_rx_LANES = 2'b11;
assign my_mipi_rx_VC_ENA = 4'b0001;

wire [TOTAL_APPS-1:0] rd_clk;
wire [TOTAL_APPS-1:0] request_data;

wire [TOTAL_APPS-1:0] data_queue_empty;
wire [TOTAL_APPS-1:0] data_queue_almost_empty;
wire [TOTAL_APPS-1:0] rd_error;

wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] rd_data;

wire [RAH_PACKET_WIDTH-1:0] aligned_data;
wire end_of_packet;

wire [(TOTAL_APPS*9)-1:0]  rah_fifo_occupants;


wire [TOTAL_APPS-1:0]rd_valid;
wire rst;

/* Align the data for the decoding process */
data_aligner #(
    .DATA_WIDTH(RAH_PACKET_WIDTH)
) da (
    .clk            (rx_pixel_clk),

    .mipi_data      (my_mipi_rx_DATA),
    .end_of_packet  (end_of_packet),
    .rx_valid       (my_mipi_rx_VALID),

    .aligned_data   (aligned_data)
);

/* Depacketizing the recevied data */
rah_decoder #(
    .DATA_WIDTH(RAH_PACKET_WIDTH),
    .TOTAL_APPS(TOTAL_APPS)
) rd (
    /* rah raw input variables */
    .clk                        (rx_pixel_clk),

    .mipi_data                  (aligned_data),
    .mipi_rx_valid              (my_mipi_rx_VALID),

    .rd_clk                     (rd_clk),
    .request_data               (request_data),

    .end_of_packet              (end_of_packet),
    .data_queue_empty           (data_queue_empty),
    .data_queue_almost_empty    (data_queue_almost_empty),
    .rd_data                    (rd_data),
    .error                      (rd_error),

    .data_fifo_occupants        (rah_fifo_occupants),
    .rd_valid_o                  (rd_valid)
);

assign rd_clk[0] = rx_pixel_clk;
assign wr_clk[0] = rx_pixel_clk;

/* Rah Version verifier */
rah_version_check #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) rvc (
    .clk            (rx_pixel_clk),
    .in_data        (`GET_DATA_RAH(0)),
    .q_empty        (data_queue_empty[0]),

    .request_data   (request_data[0]),
    .w_en           (write_apps_data[0]),
    .out_data       (`SET_DATA_RAH(0))
);

/* Periplex instantiation for multiplexing peripherals */
//assign rd_clk[`EXAMPLE] = rx_pixel_clk; 
assign rd_clk[`GATI_META_APP] = clk_81mhz; 
assign rd_clk[`GATI]= clk_81mhz;
wire rah_dispatch;
wire spi_en;
/* change this module as your app */
meta_app #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) meta (
    .clk(clk_81mhz),
    .i_empty(data_queue_empty[`GATI_META_APP]),
    //.data_queue_almost_empty(data_queue_almost_empty[`GATI_META_APP]),
    .o_rd_en(request_data[`GATI_META_APP]),
    .i_data(`GET_DATA_RAH(`GATI_META_APP)),
    .o_valid_size(valid_data_size),
    .o_data_size(rah_data_size),
    .o_uart_en(uart_en),
    .o_rah_dispatch(rah_dispatch),
    .o_spi_en(spi_en),
    .o_rst(rst),
    .i_rd_valid(rd_valid[`GATI_META_APP])
);

wire valid_32;
wire [RAH_PACKET_WIDTH-1:0] rah_data_size;
wire valid_data_size;

cvt_48232 #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH),
    .DATA_WIDTH(GATI_DATA_WIDTH)
) cvt (
    .clk (clk_81mhz),
    .rd_clk (clk_81mhz),

    .rah_data_size (rah_data_size),
    .valid_data_size (valid_data_size),
    .rah_fifo_occupants (rah_fifo_occupants[`GATI*9 + : 9]),

    .rah_data_queue_empty (data_queue_empty[`GATI]),
    .rah_data_queue_almost_empty (data_queue_almost_empty[`GATI]),
    .rah_data (`GET_DATA_RAH(`GATI)),
    .rah_request_data (request_data[`GATI]),
    
    .valid_32(valid_32),
    .rd_enable (data_rd_enable),
    .data_queue_empty (gati_queue_empty),
    .data_queue_almost_empty (gati_queue_almost_empty),
    .data (gati_data)
);
wire gati_queue_almost_empty,gati_queue_empty,data_rd_enable;
wire [31:0] gati_data;

wire mipi_fifo_almost_empty,mipi_fifo_empty;
wire mipi_fifo_rd_en;
wire mipi_fifo_data_valid;
wire [31:0] mipi_fifo_data_out;
wire [9:0] mipi_rd_fifo_occupants; 

wire valid_data_size_rah;
wire [31:0] data_size_rah;

wire mipi_fifo_rd_en_u;
wire mipi_fifo_rd_en_r; 

wire i_rstn;

//Todo: CDC for reset signal (For now, stretch the pulse for 3 clock cycles and apply to the GATI)
reg [2:0] reset = 3'h0;

always@(posedge clk_81mhz) begin
    reset[2] <= reset[1];
    reset[1] <= reset[0];
    reset[0] <= rst;
end
assign i_rstn = reset[2] & reset[1] & reset[0] & rst;

rah_gati gati
(
	
    .i_clk(i_clk),
    .s_clk(s_clk),
    .i_rst(i_rstn),
    .c_81_clk(clk_81mhz),
    .m_clk(i_clk),
    .empty(gati_queue_empty),
    .data(gati_data),
    .valid_32(valid_32),
    .rden(data_rd_enable),
    .layer_debug_pin(layer_debug_pin),

    //Data from GATI to cvt32248
    .mipi_fifo_rd_en(mipi_fifo_rd_en),
    .mipi_fifo_empty(mipi_fifo_empty),
    .mipi_fifo_almost_empty(mipi_fifo_almost_empty),
    .mipi_rd_fifo_occupants(mipi_rd_fifo_occupants),
    .mipi_fifo_data_out(mipi_fifo_data_out),
    .mipi_fifo_data_valid(mipi_fifo_data_valid),
    .data_size_rah(data_size_rah),
    .valid_data_size_rah(valid_data_size_rah),

    //DRAM ctrler signals
    .PllLocked(PllLocked),
    .DdrCtrl_CFG_RST_N(DdrCtrl_CFG_RST_N),
    .DdrCtrl_CFG_SEQ_RST(DdrCtrl_CFG_SEQ_RST),
    .DdrCtrl_CFG_SEQ_START(DdrCtrl_CFG_SEQ_START),
    .d_done(d_done),
    .aid(aid),
    .aaddr(aaddr),
    .alen(alen),
    .asize(asize),
    .aburst(aburst),
    .alock(alock),
    .avalid(avalid),
    .aready(aready),
    .atype(atype),
    .wid(wid),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
    .wdata(wdata),
    .rid(rid),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
    .rresp(rresp),
    .rdata(rdata),
    .bid(bid) ,
    .bvalid(bvalid),
    .bready(bready),
    	
    //for io signals
    .kernal_count(kernal_count), // represents the current kernal iteration number 
    .channel_count(channel_count), // represents the current channel iteration number 
    .soft_start(soft_start),
    .layer_count(layer_count),
    .layer_done(layer_done),
    .eop(eop),

    .layer_cycles_count(layer_cycles_count),
    .stall_cycles_count(stall_cycles_count)
);

reg cvt_32248_rden = 0;
wire rah_data_queue_empty; 
wire rah_data_queue_almost_empty;
wire [RAH_PACKET_WIDTH-1:0] gati_data_out;
/*
reg mipi_fifo_rd_en;

always@(posedge clk_81mhz) begin
    if(mipi_fifo_rd_en & mipi_fifo_almost_empty) mipi_fifo_rd_en <= 0;
    else if(~mipi_fifo_empty) mipi_fifo_rd_en <= 1;
end
*/

wire data_cnt_full_o;
wire data_cnt_empt_o;

reg data_cnt_wr_en_i;  

wire data_cnt_rd_en_i;  // 2-cycle long rd_en
wire data_cnt_rd_en_i1; // From SPI/RAH
reg data_cnt_rd_en_i2;  // Delayed rd_en

wire data_cnt_rd_val_o; // From data_cnt_async_fifo
reg data_cnt_rd_val_o1; // To SPI/RAH

reg first_word;

wire spi_dc_rd_en;
wire rah_dc_rd_en;

reg [15:0] data_cnt_wdata; // To data_cnt_async_fifo

wire [15:0] data_cnt_rdata; // 16 bit fractured data size
reg [31:0] data_cnt_rdata1; // 32 bit data size

reg write_state;

assign data_cnt_rd_en_i1 = (spi_en) ? spi_dc_rd_en : rah_dc_rd_en;
assign data_cnt_rd_en_i = data_cnt_rd_en_i1 | data_cnt_rd_en_i2;

always @(posedge clk_81mhz) begin
    data_cnt_rd_en_i2 <= data_cnt_rd_en_i1;

    if (data_cnt_rd_val_o && !first_word) begin
        data_cnt_rdata1[31:16] <= data_cnt_rdata;
        data_cnt_rd_val_o1 <= 0;
        first_word <= 1;
    end else if (data_cnt_rd_val_o && first_word) begin
        data_cnt_rdata1[15:0] <= data_cnt_rdata;
        data_cnt_rd_val_o1 <= 1;
        first_word <= 0;
    end else begin
        data_cnt_rd_val_o1 <= 0;
        first_word <= 0;
    end

end

always @(posedge i_clk) begin

    case(write_state)
    0:begin
        if (valid_data_size_rah && !data_cnt_full_o) begin
            data_cnt_wdata <= data_size_rah[31:16];
            data_cnt_wr_en_i <= 1;
            write_state <= 1; 
        end else begin
            data_cnt_wr_en_i <= 0;
            write_state <= 0;
        end
    end

    1:begin
        data_cnt_wdata <= data_size_rah[15:0];
        data_cnt_wr_en_i <= 1;
        write_state <= 0; 
    end
    
    default: begin
        data_cnt_wr_en_i <= 0;
        write_state <= 0;
    end
    endcase

end


async_81 #(
    .W_DATA(16),
    .W_ADDR(7),     // 128 layers
    .OUTPUT_REG(1)
) data_cnt_async_fifo (
    .full_o(data_cnt_full_o), 
    .empty_o(data_cnt_empt_o),
    .o_valid(data_cnt_rd_val_o),
    .wr_clk_i(i_clk),
    .rd_clk_i(clk_81mhz),
    .wr_en_i(data_cnt_wr_en_i),
    .rd_en_i(data_cnt_rd_en_i),
    .wdata(data_cnt_wdata),
    .rdata(data_cnt_rdata),
    .a_rst_i(~i_rstn)
);

// Bypassing RAH and sending the GATI 32-bit output to other host CPU(or Vaaman CPU) via UART
wire UART_tx_done;
wire [7:0] UART_data;
wire UART_data_valid;

Dispatch_UART #(
    .DATA_WIDTH_IN(32),
    .DATA_WIDTH_OUT(8)
) Dispatch_UART_inst(
    .clk(clk_81mhz),
    .rst(i_rstn),
    .i_data(mipi_fifo_data_out),
    .i_data_valid(mipi_fifo_data_valid), 
    .fifo_almost_empty(mipi_fifo_almost_empty), 
    .fifo_empty(mipi_fifo_empty),
    .tx_done(UART_tx_done), 
    .uart_en(uart_en),
    .fifo_rden(mipi_fifo_rd_en_u), 
    .o_data(UART_data), 
    .o_data_valid(UART_data_valid) 
);

UART_TRANSMITTER # (
    .CLKS_PER_BIT(352) // clk_freq = 81MHz, Baud rate = 115200,230400,921600,1000000,1500000
  )
  UART_TRANSMITTER_inst (
    .i_Rst(i_rstn),
    .i_Clock(clk_81mhz),
    .i_TX_Valid(UART_data_valid),
    .i_TX_Byte(UART_data),
    .o_TX_Active(uart_led),
    .o_TX_Serial(o_TX_Serial),
    .o_TX_Done(UART_tx_done)
  );

wire uart_led;
assign debug_pin = (spi_en) ? (!spi_cs_n) : uart_led;

SPI_Slave #(
    .DATA_WIDTH_OUT (256), //bits
    .DATA_WIDTH_IN (32)    //bits
) spi_slave (
    .clk(clk_81mhz),           
    .rst_n(i_rstn),           
    .sclk(spi_sclk),          
    .mosi(spi_mosi),          
    .miso(spi_miso),          
    .cs_n(spi_cs_n), 
    .spi_fifo_empty(data_cnt_empt_o),
    .spi_fifo_rd_valid(data_cnt_rd_val_o1),
    .spi_fifo_rd_data(data_cnt_rdata1),
    .spi_fifo_rd_en(spi_dc_rd_en),
    .i_data(mipi_fifo_data_out), 
    .i_data_valid(mipi_fifo_data_valid),
    .fifo_empty(mipi_fifo_empty),
    .rd_datacount(mipi_rd_fifo_occupants),
    .fifo_rden(mipi_fifo_rd_en_s)
);

/* This is optional Debug bridge */
/*
mipi_uart_bridge #(
    .CLKS_PER_BIT(54)
) udb (
    .clk(rx_pixel_clk),
    .my_mipi_rx_VALID(my_mipi_rx_VALID & (my_mipi_rx_DATA != 0)),
    .my_mipi_rx_DATA(my_mipi_rx_DATA),
    .uart_tx_pin(debug_pin)
);
*/

/* Send data to processor */
wire [TOTAL_APPS-1:0] wr_clk;
wire [(TOTAL_APPS*RAH_PACKET_WIDTH)-1:0] wr_data;
wire [TOTAL_APPS-1:0] write_apps_data;
wire [TOTAL_APPS-1:0] wr_fifo_full;
wire [TOTAL_APPS-1:0] wr_almost_fifo_full;
wire [TOTAL_APPS-1:0] wr_prog_fifo_full;

wire vid_gen_clk;
assign vid_gen_clk = tx_vga_clk;

wire mipi_out_rst;
wire mipi_valid;
wire [RAH_PACKET_WIDTH-1:0] mipi_out_data;
wire hsync;
wire vsync;

rah_encoder #(
    .WIDTH(ACTIVE_VID_WIDTH),
    .HEIGHT(ACTIVE_VID_HEIGHT),
    .DATA_WIDTH(RAH_PACKET_WIDTH),
    .TOTAL_APPS(TOTAL_APPS)
) re (
    .clk                    (tx_pixel_clk),
    .vid_gen_clk            (vid_gen_clk),

    .send_data              (write_apps_data),
    .wr_clk                 (wr_clk),
    .wr_data                (wr_data),

    .wr_fifo_full           (wr_fifo_full),
    .wr_almost_fifo_full    (wr_almost_fifo_full),
    .wr_prog_fifo_full      (wr_prog_fifo_full),

    .mipi_rst               (mipi_out_rst),
    .mipi_valid             (mipi_valid),
    .mipi_data              (mipi_out_data),
    .hsync_patgen           (hsync),
    .vsync_patgen           (vsync)
);

//assign wr_clk[`EXAMPLE] = tx_pixel_clk;
assign wr_clk[`GATI] = clk_81mhz; //Disabled cvt on 28-10-24 to byapss rah and send via UART
/* Include your module */

always@(posedge clk_81mhz) begin
    if(wr_prog_fifo_full[`GATI]) cvt_32248_rden <= 0;
    else if(cvt_32248_rden & rah_data_queue_almost_empty) cvt_32248_rden <= 0;
    else if(~rah_data_queue_empty) cvt_32248_rden <= 1;
end

/* 32 to 48 bit converter */
cvt cvt_32248_inst
(
    .clk(clk_81mhz), //write clk

    // signals from 32-bit fifo of gati
    .data_size_rah(data_cnt_rdata1),
    .data_queue_empty(mipi_fifo_empty), 
    .data_queue_almost_empty(mipi_fifo_almost_empty),
    .fifo_occupants(mipi_rd_fifo_occupants),
    .data(mipi_fifo_data_out), 
    .data_request(mipi_fifo_rd_en_r), //read enable to 32-bit fifo GATI

    //signals for rah encoder
    .rd_enable(cvt_32248_rden), //read enable to read it into rah encoder

    .dc_fifo_empty(data_cnt_empt_o),
    .dc_rd_valid(data_cnt_rd_val_o1),
    .dc_rd_en(rah_dc_rd_en),

    .cvt_data_queue_empty(rah_data_queue_empty),
    .cvt_data_queue_almost_empty(rah_data_queue_almost_empty),
    .cvt_data_valid(write_apps_data[`GATI]),
    .cvt_data(`SET_DATA_RAH(`GATI)),
    .rah_dispatch(rah_dispatch)
);


/*
example_trans #(
    .RAH_PACKET_WIDTH(RAH_PACKET_WIDTH)
) et (
    .clk        (tx_pixel_clk),
    .data       (`SET_DATA_RAH(`EXAMPLE)),
    .send_data  (write_apps_data[`EXAMPLE])
);
*/

assign mipi_fifo_rd_en = (uart_en) ? mipi_fifo_rd_en_u : 
                         ((spi_en) ? mipi_fifo_rd_en_s : mipi_fifo_rd_en_r);
assign my_mipi_tx_DPHY_RSTN = ~mipi_out_rst;
assign my_mipi_tx_RSTN = ~mipi_out_rst;
assign my_mipi_tx_VALID = mipi_valid;
assign my_mipi_tx_HSYNC = hsync;
assign my_mipi_tx_VSYNC = vsync;
assign my_mipi_tx_DATA = mipi_out_data;
assign my_mipi_tx_TYPE = 6'h24;
assign my_mipi_tx_LANES = 2'b11;
assign my_mipi_tx_FRAME_MODE = 1'b0;
assign my_mipi_tx_HRES = ACTIVE_VID_WIDTH;
assign my_mipi_tx_VC = 2'b00;
assign my_mipi_tx_ULPS_ENTER = 4'b0000;
assign my_mipi_tx_ULPS_EXIT = 4'b0000;
assign my_mipi_tx_ULPS_CLK_ENTER = 1'b0;
assign my_mipi_tx_ULPS_CLK_EXIT = 1'b0;

endmodule

