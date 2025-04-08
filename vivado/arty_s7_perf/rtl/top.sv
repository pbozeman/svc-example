`include "svc.sv"
`include "axi_perf.sv"

module top (
    input  wire        CLK100MHZ,
    input  wire        reset,
    input  wire        UART_RX,
    output wire        UART_TX,
    output wire [ 3:0] led,
    output wire [13:0] ddr3_addr,
    output wire [ 2:0] ddr3_ba,
    output wire        ddr3_cas_n,
    output wire [ 0:0] ddr3_ck_n,
    output wire [ 0:0] ddr3_ck_p,
    output wire [ 0:0] ddr3_cke,
    output wire [ 0:0] ddr3_cs_n,
    output wire [ 1:0] ddr3_dm,
    inout  wire [15:0] ddr3_dq,
    inout  wire [ 1:0] ddr3_dqs_n,
    inout  wire [ 1:0] ddr3_dqs_p,
    output wire [ 0:0] ddr3_odt,
    output wire        ddr3_ras_n,
    output wire        ddr3_reset_n,
    output wire        ddr3_we_n
);
  localparam NAME = "axi_perf_ddr";

  // We are using the DDR MIG gen UI clock, not the system clock
  localparam CLOCK_FREQ = 85_250_000;
  localparam CLOCK_FREQ_STR = "85.25";
  localparam BAUD_RATE = 115_200;

  localparam AXI_ADDR_WIDTH = 28;
  localparam AXI_DATA_WIDTH = 128;
  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;
  localparam AXI_ID_WIDTH = 4;

  wire                      clk;
  wire                      ui_clk_rst;
  wire                      rst_n;

  wire                      mmcm_locked;
  wire                      init_calib_complete;

  wire [AXI_ADDR_WIDTH-1:0] ddr_axi_araddr;
  wire [               1:0] ddr_axi_arburst;
  wire [               3:0] ddr_axi_arcache;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_arid;
  wire [               7:0] ddr_axi_arlen;
  wire                      ddr_axi_arlock;
  wire [               2:0] ddr_axi_arprot;
  wire [               3:0] ddr_axi_arqos;
  wire                      ddr_axi_arready;
  wire [               2:0] ddr_axi_arsize;
  wire                      ddr_axi_arvalid;
  wire [AXI_ADDR_WIDTH-1:0] ddr_axi_awaddr;
  wire [               1:0] ddr_axi_awburst;
  wire [               3:0] ddr_axi_awcache;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_awid;
  wire [               7:0] ddr_axi_awlen;
  wire                      ddr_axi_awlock;
  wire [               2:0] ddr_axi_awprot;
  wire [               3:0] ddr_axi_awqos;
  wire                      ddr_axi_awready;
  wire [               2:0] ddr_axi_awsize;
  wire                      ddr_axi_awvalid;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_bid;
  wire                      ddr_axi_bready;
  wire [               1:0] ddr_axi_bresp;
  wire                      ddr_axi_bvalid;
  wire [AXI_DATA_WIDTH-1:0] ddr_axi_rdata;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_rid;
  wire                      ddr_axi_rlast;
  wire                      ddr_axi_rready;
  wire [               1:0] ddr_axi_rresp;
  wire                      ddr_axi_rvalid;
  wire [AXI_DATA_WIDTH-1:0] ddr_axi_wdata;
  wire                      ddr_axi_wlast;
  wire                      ddr_axi_wready;
  wire [AXI_STRB_WIDTH-1:0] ddr_axi_wstrb;
  wire                      ddr_axi_wvalid;

  assign led[3]          = mmcm_locked;
  assign led[2]          = init_calib_complete;
  assign led[1]          = 1'b0;
  assign led[0]          = 1'b0;

  assign rst_n           = !ui_clk_rst;

  assign ddr_axi_arcache = 4'b1111;
  assign ddr_axi_arlock  = 1'b0;
  assign ddr_axi_arprot  = 3'd0;
  assign ddr_axi_arqos   = 4'd0;

  assign ddr_axi_awcache = 4'b1111;
  assign ddr_axi_awlock  = 1'b0;
  assign ddr_axi_awprot  = 3'd0;
  assign ddr_axi_awqos   = 4'd0;

  arty_s7_perf_bd arty_s7_perf_bd_i (
      .s_axi_araddr       (ddr_axi_araddr),
      .s_axi_arburst      (ddr_axi_arburst),
      .s_axi_arcache      (ddr_axi_arcache),
      .s_axi_arid         (ddr_axi_arid),
      .s_axi_arlen        (ddr_axi_arlen),
      .s_axi_arlock       (ddr_axi_arlock),
      .s_axi_arprot       (ddr_axi_arprot),
      .s_axi_arqos        (ddr_axi_arqos),
      .s_axi_arready      (ddr_axi_arready),
      .s_axi_arsize       (ddr_axi_arsize),
      .s_axi_arvalid      (ddr_axi_arvalid),
      .s_axi_awaddr       (ddr_axi_awaddr),
      .s_axi_awburst      (ddr_axi_awburst),
      .s_axi_awcache      (ddr_axi_awcache),
      .s_axi_awid         (ddr_axi_awid),
      .s_axi_awlen        (ddr_axi_awlen),
      .s_axi_awlock       (ddr_axi_awlock),
      .s_axi_awprot       (ddr_axi_awprot),
      .s_axi_awqos        (ddr_axi_awqos),
      .s_axi_awready      (ddr_axi_awready),
      .s_axi_awsize       (ddr_axi_awsize),
      .s_axi_awvalid      (ddr_axi_awvalid),
      .s_axi_bid          (ddr_axi_bid),
      .s_axi_bready       (ddr_axi_bready),
      .s_axi_bresp        (ddr_axi_bresp),
      .s_axi_bvalid       (ddr_axi_bvalid),
      .s_axi_rdata        (ddr_axi_rdata),
      .s_axi_rid          (ddr_axi_rid),
      .s_axi_rlast        (ddr_axi_rlast),
      .s_axi_rready       (ddr_axi_rready),
      .s_axi_rresp        (ddr_axi_rresp),
      .s_axi_rvalid       (ddr_axi_rvalid),
      .s_axi_wdata        (ddr_axi_wdata),
      .s_axi_wlast        (ddr_axi_wlast),
      .s_axi_wready       (ddr_axi_wready),
      .s_axi_wstrb        (ddr_axi_wstrb),
      .s_axi_wvalid       (ddr_axi_wvalid),
      .aresetn            (rst_n),
      .ddr3_addr          (ddr3_addr),
      .ddr3_ba            (ddr3_ba),
      .ddr3_cas_n         (ddr3_cas_n),
      .ddr3_ck_n          (ddr3_ck_n),
      .ddr3_ck_p          (ddr3_ck_p),
      .ddr3_cke           (ddr3_cke),
      .ddr3_cs_n          (ddr3_cs_n),
      .ddr3_dm            (ddr3_dm),
      .ddr3_dq            (ddr3_dq),
      .ddr3_dqs_n         (ddr3_dqs_n),
      .ddr3_dqs_p         (ddr3_dqs_p),
      .ddr3_odt           (ddr3_odt),
      .ddr3_ras_n         (ddr3_ras_n),
      .ddr3_reset_n       (ddr3_reset_n),
      .ddr3_we_n          (ddr3_we_n),
      .init_calib_complete(init_calib_complete),
      .mmcm_locked        (mmcm_locked),
      .reset              (reset),
      .clk_100            (CLK100MHZ),
      .ui_clk             (clk),
      .ui_clk_rst         (ui_clk_rst)
  );

  axi_perf #(
      .CLOCK_FREQ    (CLOCK_FREQ),
      .BAUD_RATE     (BAUD_RATE),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) axi_perf_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX),

      .m_axi_awvalid(ddr_axi_awvalid),
      .m_axi_awaddr (ddr_axi_awaddr),
      .m_axi_awid   (ddr_axi_awid),
      .m_axi_awlen  (ddr_axi_awlen),
      .m_axi_awsize (ddr_axi_awsize),
      .m_axi_awburst(ddr_axi_awburst),
      .m_axi_awready(ddr_axi_awready),
      .m_axi_wvalid (ddr_axi_wvalid),
      .m_axi_wdata  (ddr_axi_wdata),
      .m_axi_wstrb  (ddr_axi_wstrb),
      .m_axi_wlast  (ddr_axi_wlast),
      .m_axi_wready (ddr_axi_wready),
      .m_axi_bvalid (ddr_axi_bvalid),
      .m_axi_bid    (ddr_axi_bid),
      .m_axi_bresp  (ddr_axi_bresp),
      .m_axi_bready (ddr_axi_bready),

      .m_axi_arvalid(ddr_axi_arvalid),
      .m_axi_arid   (ddr_axi_arid),
      .m_axi_araddr (ddr_axi_araddr),
      .m_axi_arlen  (ddr_axi_arlen),
      .m_axi_arsize (ddr_axi_arsize),
      .m_axi_arburst(ddr_axi_arburst),
      .m_axi_arready(ddr_axi_arready),
      .m_axi_rvalid (ddr_axi_rvalid),
      .m_axi_rid    (ddr_axi_rid),
      .m_axi_rdata  (ddr_axi_rdata),
      .m_axi_rresp  (ddr_axi_rresp),
      .m_axi_rlast  (ddr_axi_rlast),
      .m_axi_rready (ddr_axi_rready)
  );

endmodule
