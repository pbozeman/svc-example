`ifndef MEM_TEST_ARBITER_ICE40_SRAM_SV
`define MEM_TEST_ARBITER_ICE40_SRAM_SV

`include "svc_axi_arbiter.sv"
`include "svc_axi_null.sv"
`include "svc_ice40_axi_sram.sv"

`include "mem_test_axi.sv"

// This is just a smoke test of synthesis using the svc_axi_arbiter. It sets
// up an arbiter with a null axi and an ice40 sram axi, and then just does the
// normal axi mem test.

module mem_test_arbiter_ice40_sram #(
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
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

  localparam AXI_ID_WIDTH = 4;
  localparam A_AXI_ID_WIDTH = AXI_ID_WIDTH + 1;

  // the axi sram signals for both the null and the mem test managers
  logic [               1:0]                     m_axi_awvalid;
  logic [               1:0][AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic [               1:0][  AXI_ID_WIDTH-1:0] m_axi_awid;
  logic [               1:0][               7:0] m_axi_awlen;
  logic [               1:0][               2:0] m_axi_awsize;
  logic [               1:0][               1:0] m_axi_awburst;
  logic [               1:0]                     m_axi_awready;
  logic [               1:0]                     m_axi_wvalid;
  logic [               1:0][AXI_DATA_WIDTH-1:0] m_axi_wdata;
  logic [               1:0][AXI_STRB_WIDTH-1:0] m_axi_wstrb;
  logic [               1:0]                     m_axi_wlast;
  logic [               1:0]                     m_axi_wready;
  logic [               1:0]                     m_axi_bvalid;
  logic [               1:0][  AXI_ID_WIDTH-1:0] m_axi_bid;
  logic [               1:0][               1:0] m_axi_bresp;
  logic [               1:0]                     m_axi_bready;

  logic [               1:0]                     m_axi_arvalid;
  logic [               1:0][  AXI_ID_WIDTH-1:0] m_axi_arid;
  logic [               1:0][AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic [               1:0][               7:0] m_axi_arlen;
  logic [               1:0][               2:0] m_axi_arsize;
  logic [               1:0][               1:0] m_axi_arburst;
  logic [               1:0]                     m_axi_arready;
  logic [               1:0]                     m_axi_rvalid;
  logic [               1:0][  AXI_ID_WIDTH-1:0] m_axi_rid;
  logic [               1:0][AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0][               1:0] m_axi_rresp;
  logic [               1:0]                     m_axi_rlast;
  logic [               1:0]                     m_axi_rready;

  // the axi signals coming out of the arbiter and into the sram
  logic                                          a_axi_awvalid;
  logic [AXI_ADDR_WIDTH-1:0]                     a_axi_awaddr;
  logic [A_AXI_ID_WIDTH-1:0]                     a_axi_awid;
  logic [               7:0]                     a_axi_awlen;
  logic [               2:0]                     a_axi_awsize;
  logic [               1:0]                     a_axi_awburst;
  logic                                          a_axi_awready;
  logic                                          a_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0]                     a_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0]                     a_axi_wstrb;
  logic                                          a_axi_wlast;
  logic                                          a_axi_wready;
  logic                                          a_axi_bvalid;
  logic [A_AXI_ID_WIDTH-1:0]                     a_axi_bid;
  logic [               1:0]                     a_axi_bresp;
  logic                                          a_axi_bready;

  logic                                          a_axi_arvalid;
  logic [A_AXI_ID_WIDTH-1:0]                     a_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0]                     a_axi_araddr;
  logic [               7:0]                     a_axi_arlen;
  logic [               2:0]                     a_axi_arsize;
  logic [               1:0]                     a_axi_arburst;
  logic                                          a_axi_arready;
  logic                                          a_axi_rvalid;
  logic [A_AXI_ID_WIDTH-1:0]                     a_axi_rid;
  logic [AXI_DATA_WIDTH-1:0]                     a_axi_rdata;
  logic [               1:0]                     a_axi_rresp;
  logic                                          a_axi_rlast;
  logic                                          a_axi_rready;

  svc_axi_null #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_axi_null_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .m_axi_awvalid(m_axi_awvalid[0]),
      .m_axi_awaddr (m_axi_awaddr[0]),
      .m_axi_awid   (m_axi_awid[0]),
      .m_axi_awlen  (m_axi_awlen[0]),
      .m_axi_awsize (m_axi_awsize[0]),
      .m_axi_awburst(m_axi_awburst[0]),
      .m_axi_awready(m_axi_awready[0]),
      .m_axi_wdata  (m_axi_wdata[0]),
      .m_axi_wstrb  (m_axi_wstrb[0]),
      .m_axi_wlast  (m_axi_wlast[0]),
      .m_axi_wvalid (m_axi_wvalid[0]),
      .m_axi_wready (m_axi_wready[0]),
      .m_axi_bresp  (m_axi_bresp[0]),
      .m_axi_bid    (m_axi_bid[0]),
      .m_axi_bvalid (m_axi_bvalid[0]),
      .m_axi_bready (m_axi_bready[0]),
      .m_axi_arvalid(m_axi_arvalid[0]),
      .m_axi_araddr (m_axi_araddr[0]),
      .m_axi_arid   (m_axi_arid[0]),
      .m_axi_arready(m_axi_arready[0]),
      .m_axi_arlen  (m_axi_arlen[0]),
      .m_axi_arsize (m_axi_arsize[0]),
      .m_axi_arburst(m_axi_arburst[0]),
      .m_axi_rvalid (m_axi_rvalid[0]),
      .m_axi_rid    (m_axi_rid[0]),
      .m_axi_rresp  (m_axi_rresp[0]),
      .m_axi_rlast  (m_axi_rlast[0]),
      .m_axi_rdata  (m_axi_rdata[0]),
      .m_axi_rready (m_axi_rready[0])
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

      .m_axi_awvalid(m_axi_awvalid[1]),
      .m_axi_awaddr (m_axi_awaddr[1]),
      .m_axi_awid   (m_axi_awid[1]),
      .m_axi_awlen  (m_axi_awlen[1]),
      .m_axi_awsize (m_axi_awsize[1]),
      .m_axi_awburst(m_axi_awburst[1]),
      .m_axi_awready(m_axi_awready[1]),
      .m_axi_wdata  (m_axi_wdata[1]),
      .m_axi_wstrb  (m_axi_wstrb[1]),
      .m_axi_wlast  (m_axi_wlast[1]),
      .m_axi_wvalid (m_axi_wvalid[1]),
      .m_axi_wready (m_axi_wready[1]),
      .m_axi_bresp  (m_axi_bresp[1]),
      .m_axi_bid    (m_axi_bid[1]),
      .m_axi_bvalid (m_axi_bvalid[1]),
      .m_axi_bready (m_axi_bready[1]),
      .m_axi_arvalid(m_axi_arvalid[1]),
      .m_axi_araddr (m_axi_araddr[1]),
      .m_axi_arid   (m_axi_arid[1]),
      .m_axi_arready(m_axi_arready[1]),
      .m_axi_arlen  (m_axi_arlen[1]),
      .m_axi_arsize (m_axi_arsize[1]),
      .m_axi_arburst(m_axi_arburst[1]),
      .m_axi_rvalid (m_axi_rvalid[1]),
      .m_axi_rid    (m_axi_rid[1]),
      .m_axi_rdata  (m_axi_rdata[1]),
      .m_axi_rresp  (m_axi_rresp[1]),
      .m_axi_rlast  (m_axi_rlast[1]),
      .m_axi_rready (m_axi_rready[1])
  );

  svc_axi_arbiter #(
      .NUM_M         (2),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_axi_arbiter_i (
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

      .m_axi_awvalid(a_axi_awvalid),
      .m_axi_awaddr (a_axi_awaddr),
      .m_axi_awid   (a_axi_awid),
      .m_axi_awlen  (a_axi_awlen),
      .m_axi_awsize (a_axi_awsize),
      .m_axi_awburst(a_axi_awburst),
      .m_axi_awready(a_axi_awready),
      .m_axi_wdata  (a_axi_wdata),
      .m_axi_wstrb  (a_axi_wstrb),
      .m_axi_wlast  (a_axi_wlast),
      .m_axi_wvalid (a_axi_wvalid),
      .m_axi_wready (a_axi_wready),
      .m_axi_bresp  (a_axi_bresp),
      .m_axi_bid    (a_axi_bid),
      .m_axi_bvalid (a_axi_bvalid),
      .m_axi_bready (a_axi_bready),
      .m_axi_arvalid(a_axi_arvalid),
      .m_axi_araddr (a_axi_araddr),
      .m_axi_arid   (a_axi_arid),
      .m_axi_arready(a_axi_arready),
      .m_axi_arlen  (a_axi_arlen),
      .m_axi_arsize (a_axi_arsize),
      .m_axi_arburst(a_axi_arburst),
      .m_axi_rvalid (a_axi_rvalid),
      .m_axi_rid    (a_axi_rid),
      .m_axi_rresp  (a_axi_rresp),
      .m_axi_rlast  (a_axi_rlast),
      .m_axi_rdata  (a_axi_rdata),
      .m_axi_rready (a_axi_rready)
  );

  svc_ice40_axi_sram #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (A_AXI_ID_WIDTH)
  ) svc_ice40_axi_sram_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(a_axi_awvalid),
      .s_axi_awaddr (a_axi_awaddr),
      .s_axi_awid   (a_axi_awid),
      .s_axi_awlen  (a_axi_awlen),
      .s_axi_awsize (a_axi_awsize),
      .s_axi_awburst(a_axi_awburst),
      .s_axi_awready(a_axi_awready),
      .s_axi_wdata  (a_axi_wdata),
      .s_axi_wstrb  (a_axi_wstrb),
      .s_axi_wlast  (a_axi_wlast),
      .s_axi_wvalid (a_axi_wvalid),
      .s_axi_wready (a_axi_wready),
      .s_axi_bresp  (a_axi_bresp),
      .s_axi_bid    (a_axi_bid),
      .s_axi_bvalid (a_axi_bvalid),
      .s_axi_bready (a_axi_bready),
      .s_axi_arvalid(a_axi_arvalid),
      .s_axi_araddr (a_axi_araddr),
      .s_axi_arid   (a_axi_arid),
      .s_axi_arready(a_axi_arready),
      .s_axi_arlen  (a_axi_arlen),
      .s_axi_arsize (a_axi_arsize),
      .s_axi_arburst(a_axi_arburst),
      .s_axi_rvalid (a_axi_rvalid),
      .s_axi_rid    (a_axi_rid),
      .s_axi_rresp  (a_axi_rresp),
      .s_axi_rlast  (a_axi_rlast),
      .s_axi_rdata  (a_axi_rdata),
      .s_axi_rready (a_axi_rready),
      .sram_io_addr (sram_io_addr),
      .sram_io_data (sram_io_data),
      .sram_io_we_n (sram_io_we_n),
      .sram_io_oe_n (sram_io_oe_n),
      .sram_io_ce_n (sram_io_ce_n)
  );

endmodule

`endif
