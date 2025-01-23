`ifndef MEM_TEST_ICE40_SRAM_SV
`define MEM_TEST_ICE40_SRAM_SV

`include "svc_ice40_axi_sram.sv"

`include "mem_test_axi.sv"

module mem_test_ice40_sram #(
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 16,
    parameter NUM_BURSTS      = 8,
    parameter NUM_BEATS       = 3
) (
    // tester signals
    input logic clk,
    input logic rst_n,

    output logic test_done,
    output logic test_pass,

    // debug/output signals
    output logic [7:0] debug0,
    output logic [7:0] debug1,
    output logic [7:0] debug2,

    // sram controller to io pins
    output logic [SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [SRAM_DATA_WIDTH-1:0] sram_io_data,
    output logic                       sram_io_we_n,
    output logic                       sram_io_oe_n,
    output logic                       sram_io_ce_n
);
  localparam AXI_ADDR_WIDTH = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam AXI_DATA_WIDTH = SRAM_DATA_WIDTH;
  localparam AXI_ID_WIDTH = 4;
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

  logic                      m_axi_awvalid;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic [  AXI_ID_WIDTH-1:0] m_axi_awid;
  logic [               7:0] m_axi_awlen;
  logic [               2:0] m_axi_awsize;
  logic [               1:0] m_axi_awburst;
  logic                      m_axi_awready;
  logic                      m_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] m_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb;
  logic                      m_axi_wlast;
  logic                      m_axi_wready;
  logic                      m_axi_bvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_bid;
  logic [               1:0] m_axi_bresp;
  logic                      m_axi_bready;

  logic                      m_axi_arvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic [               7:0] m_axi_arlen;
  logic [               2:0] m_axi_arsize;
  logic [               1:0] m_axi_arburst;
  logic                      m_axi_arready;
  logic                      m_axi_rvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0] m_axi_rresp;
  logic                      m_axi_rlast;
  logic                      m_axi_rready;

  svc_ice40_axi_sram #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_ice40_axi_sram_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(m_axi_awvalid),
      .s_axi_awaddr (m_axi_awaddr),
      .s_axi_awid   (m_axi_awid),
      .s_axi_awlen  (m_axi_awlen),
      .s_axi_awsize (m_axi_awsize),
      .s_axi_awburst(m_axi_awburst),
      .s_axi_awready(m_axi_awready),
      .s_axi_wdata  (m_axi_wdata),
      .s_axi_wstrb  (m_axi_wstrb),
      .s_axi_wlast  (m_axi_wlast),
      .s_axi_wvalid (m_axi_wvalid),
      .s_axi_wready (m_axi_wready),
      .s_axi_bresp  (m_axi_bresp),
      .s_axi_bid    (m_axi_bid),
      .s_axi_bvalid (m_axi_bvalid),
      .s_axi_bready (m_axi_bready),
      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_araddr (m_axi_araddr),
      .s_axi_arid   (m_axi_arid),
      .s_axi_arready(m_axi_arready),
      .s_axi_arlen  (m_axi_arlen),
      .s_axi_arsize (m_axi_arsize),
      .s_axi_arburst(m_axi_arburst),
      .s_axi_rvalid (m_axi_rvalid),
      .s_axi_rid    (m_axi_rid),
      .s_axi_rresp  (m_axi_rresp),
      .s_axi_rlast  (m_axi_rlast),
      .s_axi_rdata  (m_axi_rdata),
      .s_axi_rready (m_axi_rready),
      .sram_io_addr (sram_io_addr),
      .sram_io_data (sram_io_data),
      .sram_io_we_n (sram_io_we_n),
      .sram_io_oe_n (sram_io_oe_n),
      .sram_io_ce_n (sram_io_ce_n)
  );

  mem_test_axi #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH),
      .NUM_BURSTS    (NUM_BURSTS),
      .NUM_BEATS     (NUM_BEATS)
  ) mem_test_axi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .test_done(test_done),
      .test_pass(test_pass),
      .debug0   (debug0),
      .debug1   (debug1),
      .debug2   (debug2),

      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wlast  (m_axi_wlast),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wready (m_axi_wready),
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bid    (m_axi_bid),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bready (m_axi_bready),
      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_araddr (m_axi_araddr),
      .m_axi_arid   (m_axi_arid),
      .m_axi_arready(m_axi_arready),
      .m_axi_arlen  (m_axi_arlen),
      .m_axi_arsize (m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_rvalid (m_axi_rvalid),
      .m_axi_rid    (m_axi_rid),
      .m_axi_rdata  (m_axi_rdata),
      .m_axi_rresp  (m_axi_rresp),
      .m_axi_rlast  (m_axi_rlast),
      .m_axi_rready (m_axi_rready)
  );


endmodule

`endif
