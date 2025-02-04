`ifndef MEM_TEST_ICE40_SRAM_SV
`define MEM_TEST_ICE40_SRAM_SV

`include "svc_axi_arbiter.sv"
`include "svc_ice40_axi_sram.sv"
`include "svc_axi_null.sv"
`include "svc_axi_stripe.sv"

`include "mem_test_axi.sv"

module mem_test_striped_arbiter_ice40_sram #(
    parameter NUM_S            = 2,
    parameter SRAM_ADDR_WIDTH  = 20,
    parameter SRAM_DATA_WIDTH  = 16,
    parameter SRAM_RDATA_WIDTH = SRAM_DATA_WIDTH,
    parameter NUM_BURSTS       = 8,
    parameter NUM_BEATS        = 8
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
    output logic [NUM_S-1:0][ SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [NUM_S-1:0][SRAM_RDATA_WIDTH-1:0] sram_io_data,
    output logic [NUM_S-1:0]                       sram_io_we_n,
    output logic [NUM_S-1:0]                       sram_io_oe_n,
    output logic [NUM_S-1:0]                       sram_io_ce_n
);

  localparam AW = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam DW = SRAM_DATA_WIDTH;
  localparam IW = 4;
  localparam STRBW = SRAM_DATA_WIDTH / 8;

  // arbiter id width
  localparam AIW = IW + 1;

  // stripe addr width (this is the top/big side, which is the inverse
  // of how it's done in svc)
  localparam SAW = AW + $clog2(NUM_S);

  // axi signals for each sram
  logic [NUM_S-1:0]            sram_axi_awvalid;
  logic [NUM_S-1:0][   AW-1:0] sram_axi_awaddr;
  logic [NUM_S-1:0][  AIW-1:0] sram_axi_awid;
  logic [NUM_S-1:0][      7:0] sram_axi_awlen;
  logic [NUM_S-1:0][      2:0] sram_axi_awsize;
  logic [NUM_S-1:0][      1:0] sram_axi_awburst;
  logic [NUM_S-1:0]            sram_axi_awready;
  logic [NUM_S-1:0]            sram_axi_wvalid;
  logic [NUM_S-1:0][   DW-1:0] sram_axi_wdata;
  logic [NUM_S-1:0][STRBW-1:0] sram_axi_wstrb;
  logic [NUM_S-1:0]            sram_axi_wlast;
  logic [NUM_S-1:0]            sram_axi_wready;
  logic [NUM_S-1:0]            sram_axi_bvalid;
  logic [NUM_S-1:0][  AIW-1:0] sram_axi_bid;
  logic [NUM_S-1:0][      1:0] sram_axi_bresp;
  logic [NUM_S-1:0]            sram_axi_bready;

  logic [NUM_S-1:0]            sram_axi_arvalid;
  logic [NUM_S-1:0][  AIW-1:0] sram_axi_arid;
  logic [NUM_S-1:0][   AW-1:0] sram_axi_araddr;
  logic [NUM_S-1:0][      7:0] sram_axi_arlen;
  logic [NUM_S-1:0][      2:0] sram_axi_arsize;
  logic [NUM_S-1:0][      1:0] sram_axi_arburst;
  logic [NUM_S-1:0]            sram_axi_arready;
  logic [NUM_S-1:0]            sram_axi_rvalid;
  logic [NUM_S-1:0][  AIW-1:0] sram_axi_rid;
  logic [NUM_S-1:0][   DW-1:0] sram_axi_rdata;
  logic [NUM_S-1:0][      1:0] sram_axi_rresp;
  logic [NUM_S-1:0]            sram_axi_rlast;
  logic [NUM_S-1:0]            sram_axi_rready;

  // null signal for each arbiter
  logic [NUM_S-1:0]            null_axi_awvalid;
  logic [NUM_S-1:0][   AW-1:0] null_axi_awaddr;
  logic [NUM_S-1:0][   IW-1:0] null_axi_awid;
  logic [NUM_S-1:0][      7:0] null_axi_awlen;
  logic [NUM_S-1:0][      2:0] null_axi_awsize;
  logic [NUM_S-1:0][      1:0] null_axi_awburst;
  logic [NUM_S-1:0]            null_axi_awready;
  logic [NUM_S-1:0]            null_axi_wvalid;
  logic [NUM_S-1:0][   DW-1:0] null_axi_wdata;
  logic [NUM_S-1:0][STRBW-1:0] null_axi_wstrb;
  logic [NUM_S-1:0]            null_axi_wlast;
  logic [NUM_S-1:0]            null_axi_wready;
  logic [NUM_S-1:0]            null_axi_bvalid;
  logic [NUM_S-1:0][   IW-1:0] null_axi_bid;
  logic [NUM_S-1:0][      1:0] null_axi_bresp;
  logic [NUM_S-1:0]            null_axi_bready;

  logic [NUM_S-1:0]            null_axi_arvalid;
  logic [NUM_S-1:0][   IW-1:0] null_axi_arid;
  logic [NUM_S-1:0][   AW-1:0] null_axi_araddr;
  logic [NUM_S-1:0][      7:0] null_axi_arlen;
  logic [NUM_S-1:0][      2:0] null_axi_arsize;
  logic [NUM_S-1:0][      1:0] null_axi_arburst;
  logic [NUM_S-1:0]            null_axi_arready;
  logic [NUM_S-1:0]            null_axi_rvalid;
  logic [NUM_S-1:0][   IW-1:0] null_axi_rid;
  logic [NUM_S-1:0][   DW-1:0] null_axi_rdata;
  logic [NUM_S-1:0][      1:0] null_axi_rresp;
  logic [NUM_S-1:0]            null_axi_rlast;
  logic [NUM_S-1:0]            null_axi_rready;

  // stripe signals into arbiter
  logic [NUM_S-1:0]            stripe_axi_awvalid;
  logic [NUM_S-1:0][   AW-1:0] stripe_axi_awaddr;
  logic [NUM_S-1:0][   IW-1:0] stripe_axi_awid;
  logic [NUM_S-1:0][      7:0] stripe_axi_awlen;
  logic [NUM_S-1:0][      2:0] stripe_axi_awsize;
  logic [NUM_S-1:0][      1:0] stripe_axi_awburst;
  logic [NUM_S-1:0]            stripe_axi_awready;
  logic [NUM_S-1:0]            stripe_axi_wvalid;
  logic [NUM_S-1:0][   DW-1:0] stripe_axi_wdata;
  logic [NUM_S-1:0][STRBW-1:0] stripe_axi_wstrb;
  logic [NUM_S-1:0]            stripe_axi_wlast;
  logic [NUM_S-1:0]            stripe_axi_wready;
  logic [NUM_S-1:0]            stripe_axi_bvalid;
  logic [NUM_S-1:0][   IW-1:0] stripe_axi_bid;
  logic [NUM_S-1:0][      1:0] stripe_axi_bresp;
  logic [NUM_S-1:0]            stripe_axi_bready;

  logic [NUM_S-1:0]            stripe_axi_arvalid;
  logic [NUM_S-1:0][   IW-1:0] stripe_axi_arid;
  logic [NUM_S-1:0][   AW-1:0] stripe_axi_araddr;
  logic [NUM_S-1:0][      7:0] stripe_axi_arlen;
  logic [NUM_S-1:0][      2:0] stripe_axi_arsize;
  logic [NUM_S-1:0][      1:0] stripe_axi_arburst;
  logic [NUM_S-1:0]            stripe_axi_arready;
  logic [NUM_S-1:0]            stripe_axi_rvalid;
  logic [NUM_S-1:0][   IW-1:0] stripe_axi_rid;
  logic [NUM_S-1:0][   DW-1:0] stripe_axi_rdata;
  logic [NUM_S-1:0][      1:0] stripe_axi_rresp;
  logic [NUM_S-1:0]            stripe_axi_rlast;
  logic [NUM_S-1:0]            stripe_axi_rready;

  // axi signals for the stripe / mem test
  logic                        m_axi_awvalid;
  logic [  SAW-1:0]            m_axi_awaddr;
  logic [   IW-1:0]            m_axi_awid;
  logic [      7:0]            m_axi_awlen;
  logic [      2:0]            m_axi_awsize;
  logic [      1:0]            m_axi_awburst;
  logic                        m_axi_awready;
  logic                        m_axi_wvalid;
  logic [   DW-1:0]            m_axi_wdata;
  logic [STRBW-1:0]            m_axi_wstrb;
  logic                        m_axi_wlast;
  logic                        m_axi_wready;
  logic                        m_axi_bvalid;
  logic [   IW-1:0]            m_axi_bid;
  logic [      1:0]            m_axi_bresp;
  logic                        m_axi_bready;

  logic                        m_axi_arvalid;
  logic [   IW-1:0]            m_axi_arid;
  logic [  SAW-1:0]            m_axi_araddr;
  logic [      7:0]            m_axi_arlen;
  logic [      2:0]            m_axi_arsize;
  logic [      1:0]            m_axi_arburst;
  logic                        m_axi_arready;
  logic                        m_axi_rvalid;
  logic [   IW-1:0]            m_axi_rid;
  logic [   DW-1:0]            m_axi_rdata;
  logic [      1:0]            m_axi_rresp;
  logic                        m_axi_rlast;
  logic                        m_axi_rready;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_subs
    //
    // the sram
    //
    svc_ice40_axi_sram #(
        .AXI_ADDR_WIDTH  (AW),
        .AXI_DATA_WIDTH  (DW),
        .AXI_ID_WIDTH    (AIW),
        .SRAM_RDATA_WIDTH(SRAM_RDATA_WIDTH)
    ) svc_ice40_axi_sram_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_axi_awvalid(sram_axi_awvalid[i]),
        .s_axi_awaddr (sram_axi_awaddr[i]),
        .s_axi_awid   (sram_axi_awid[i]),
        .s_axi_awlen  (sram_axi_awlen[i]),
        .s_axi_awsize (sram_axi_awsize[i]),
        .s_axi_awburst(sram_axi_awburst[i]),
        .s_axi_awready(sram_axi_awready[i]),
        .s_axi_wdata  (sram_axi_wdata[i]),
        .s_axi_wstrb  (sram_axi_wstrb[i]),
        .s_axi_wlast  (sram_axi_wlast[i]),
        .s_axi_wvalid (sram_axi_wvalid[i]),
        .s_axi_wready (sram_axi_wready[i]),
        .s_axi_bresp  (sram_axi_bresp[i]),
        .s_axi_bid    (sram_axi_bid[i]),
        .s_axi_bvalid (sram_axi_bvalid[i]),
        .s_axi_bready (sram_axi_bready[i]),
        .s_axi_arvalid(sram_axi_arvalid[i]),
        .s_axi_araddr (sram_axi_araddr[i]),
        .s_axi_arid   (sram_axi_arid[i]),
        .s_axi_arready(sram_axi_arready[i]),
        .s_axi_arlen  (sram_axi_arlen[i]),
        .s_axi_arsize (sram_axi_arsize[i]),
        .s_axi_arburst(sram_axi_arburst[i]),
        .s_axi_rvalid (sram_axi_rvalid[i]),
        .s_axi_rid    (sram_axi_rid[i]),
        .s_axi_rresp  (sram_axi_rresp[i]),
        .s_axi_rlast  (sram_axi_rlast[i]),
        .s_axi_rdata  (sram_axi_rdata[i]),
        .s_axi_rready (sram_axi_rready[i]),
        .sram_io_addr (sram_io_addr[i]),
        .sram_io_data (sram_io_data[i]),
        .sram_io_we_n (sram_io_we_n[i]),
        .sram_io_oe_n (sram_io_oe_n[i]),
        .sram_io_ce_n (sram_io_ce_n[i])
    );

    //
    // arbitrate between null and the stripes to the sram
    //
    svc_axi_arbiter #(
        .NUM_M         (2),
        .AXI_ADDR_WIDTH(AW),
        .AXI_DATA_WIDTH(DW),
        .AXI_ID_WIDTH  (IW)
    ) svc_axi_arbiter_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_axi_awvalid({null_axi_awvalid[i], stripe_axi_awvalid[i]}),
        .s_axi_awaddr ({null_axi_awaddr[i], stripe_axi_awaddr[i]}),
        .s_axi_awid   ({null_axi_awid[i], stripe_axi_awid[i]}),
        .s_axi_awlen  ({null_axi_awlen[i], stripe_axi_awlen[i]}),
        .s_axi_awsize ({null_axi_awsize[i], stripe_axi_awsize[i]}),
        .s_axi_awburst({null_axi_awburst[i], stripe_axi_awburst[i]}),
        .s_axi_awready({null_axi_awready[i], stripe_axi_awready[i]}),
        .s_axi_wdata  ({null_axi_wdata[i], stripe_axi_wdata[i]}),
        .s_axi_wstrb  ({null_axi_wstrb[i], stripe_axi_wstrb[i]}),
        .s_axi_wlast  ({null_axi_wlast[i], stripe_axi_wlast[i]}),
        .s_axi_wvalid ({null_axi_wvalid[i], stripe_axi_wvalid[i]}),
        .s_axi_wready ({null_axi_wready[i], stripe_axi_wready[i]}),
        .s_axi_bresp  ({null_axi_bresp[i], stripe_axi_bresp[i]}),
        .s_axi_bid    ({null_axi_bid[i], stripe_axi_bid[i]}),
        .s_axi_bvalid ({null_axi_bvalid[i], stripe_axi_bvalid[i]}),
        .s_axi_bready ({null_axi_bready[i], stripe_axi_bready[i]}),
        .s_axi_arvalid({null_axi_arvalid[i], stripe_axi_arvalid[i]}),
        .s_axi_araddr ({null_axi_araddr[i], stripe_axi_araddr[i]}),
        .s_axi_arid   ({null_axi_arid[i], stripe_axi_arid[i]}),
        .s_axi_arready({null_axi_arready[i], stripe_axi_arready[i]}),
        .s_axi_arlen  ({null_axi_arlen[i], stripe_axi_arlen[i]}),
        .s_axi_arsize ({null_axi_arsize[i], stripe_axi_arsize[i]}),
        .s_axi_arburst({null_axi_arburst[i], stripe_axi_arburst[i]}),
        .s_axi_rvalid ({null_axi_rvalid[i], stripe_axi_rvalid[i]}),
        .s_axi_rid    ({null_axi_rid[i], stripe_axi_rid[i]}),
        .s_axi_rresp  ({null_axi_rresp[i], stripe_axi_rresp[i]}),
        .s_axi_rlast  ({null_axi_rlast[i], stripe_axi_rlast[i]}),
        .s_axi_rdata  ({null_axi_rdata[i], stripe_axi_rdata[i]}),
        .s_axi_rready ({null_axi_rready[i], stripe_axi_rready[i]}),

        .m_axi_awvalid(sram_axi_awvalid[i]),
        .m_axi_awaddr (sram_axi_awaddr[i]),
        .m_axi_awid   (sram_axi_awid[i]),
        .m_axi_awlen  (sram_axi_awlen[i]),
        .m_axi_awsize (sram_axi_awsize[i]),
        .m_axi_awburst(sram_axi_awburst[i]),
        .m_axi_awready(sram_axi_awready[i]),
        .m_axi_wdata  (sram_axi_wdata[i]),
        .m_axi_wstrb  (sram_axi_wstrb[i]),
        .m_axi_wlast  (sram_axi_wlast[i]),
        .m_axi_wvalid (sram_axi_wvalid[i]),
        .m_axi_wready (sram_axi_wready[i]),
        .m_axi_bresp  (sram_axi_bresp[i]),
        .m_axi_bid    (sram_axi_bid[i]),
        .m_axi_bvalid (sram_axi_bvalid[i]),
        .m_axi_bready (sram_axi_bready[i]),
        .m_axi_arvalid(sram_axi_arvalid[i]),
        .m_axi_araddr (sram_axi_araddr[i]),
        .m_axi_arid   (sram_axi_arid[i]),
        .m_axi_arready(sram_axi_arready[i]),
        .m_axi_arlen  (sram_axi_arlen[i]),
        .m_axi_arsize (sram_axi_arsize[i]),
        .m_axi_arburst(sram_axi_arburst[i]),
        .m_axi_rvalid (sram_axi_rvalid[i]),
        .m_axi_rid    (sram_axi_rid[i]),
        .m_axi_rresp  (sram_axi_rresp[i]),
        .m_axi_rlast  (sram_axi_rlast[i]),
        .m_axi_rdata  (sram_axi_rdata[i]),
        .m_axi_rready (sram_axi_rready[i])
    );

    //
    // The nulls
    //
    svc_axi_null #(
        .AXI_ADDR_WIDTH(AW),
        .AXI_DATA_WIDTH(DW),
        .AXI_ID_WIDTH  (IW)
    ) svc_axi_null_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .m_axi_awvalid(null_axi_awvalid[i]),
        .m_axi_awaddr (null_axi_awaddr[i]),
        .m_axi_awid   (null_axi_awid[i]),
        .m_axi_awlen  (null_axi_awlen[i]),
        .m_axi_awsize (null_axi_awsize[i]),
        .m_axi_awburst(null_axi_awburst[i]),
        .m_axi_awready(null_axi_awready[i]),
        .m_axi_wdata  (null_axi_wdata[i]),
        .m_axi_wstrb  (null_axi_wstrb[i]),
        .m_axi_wlast  (null_axi_wlast[i]),
        .m_axi_wvalid (null_axi_wvalid[i]),
        .m_axi_wready (null_axi_wready[i]),
        .m_axi_bresp  (null_axi_bresp[i]),
        .m_axi_bid    (null_axi_bid[i]),
        .m_axi_bvalid (null_axi_bvalid[i]),
        .m_axi_bready (null_axi_bready[i]),
        .m_axi_arvalid(null_axi_arvalid[i]),
        .m_axi_araddr (null_axi_araddr[i]),
        .m_axi_arid   (null_axi_arid[i]),
        .m_axi_arready(null_axi_arready[i]),
        .m_axi_arlen  (null_axi_arlen[i]),
        .m_axi_arsize (null_axi_arsize[i]),
        .m_axi_arburst(null_axi_arburst[i]),
        .m_axi_rvalid (null_axi_rvalid[i]),
        .m_axi_rid    (null_axi_rid[i]),
        .m_axi_rresp  (null_axi_rresp[i]),
        .m_axi_rlast  (null_axi_rlast[i]),
        .m_axi_rdata  (null_axi_rdata[i]),
        .m_axi_rready (null_axi_rready[i])
    );
  end

  //
  // the striper
  //
  svc_axi_stripe #(
      .NUM_S         (NUM_S),
      .AXI_ADDR_WIDTH(SAW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH  (IW)
  ) svc_axi_stripe_i (
      .clk  (clk),
      .rst_n(rst_n),

      .s_axi_awvalid(m_axi_awvalid),
      .s_axi_awid   (m_axi_awid),
      .s_axi_awaddr (m_axi_awaddr),
      .s_axi_awlen  (m_axi_awlen),
      .s_axi_awsize (m_axi_awsize),
      .s_axi_awburst(m_axi_awburst),
      .s_axi_awready(m_axi_awready),
      .s_axi_wvalid (m_axi_wvalid),
      .s_axi_wdata  (m_axi_wdata),
      .s_axi_wstrb  (m_axi_wstrb),
      .s_axi_wlast  (m_axi_wlast),
      .s_axi_wready (m_axi_wready),
      .s_axi_bvalid (m_axi_bvalid),
      .s_axi_bid    (m_axi_bid),
      .s_axi_bresp  (m_axi_bresp),
      .s_axi_bready (m_axi_bready),

      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_arid   (m_axi_arid),
      .s_axi_araddr (m_axi_araddr),
      .s_axi_arlen  (m_axi_arlen),
      .s_axi_arsize (m_axi_arsize),
      .s_axi_arburst(m_axi_arburst),
      .s_axi_arready(m_axi_arready),
      .s_axi_rvalid (m_axi_rvalid),
      .s_axi_rid    (m_axi_rid),
      .s_axi_rdata  (m_axi_rdata),
      .s_axi_rresp  (m_axi_rresp),
      .s_axi_rlast  (m_axi_rlast),
      .s_axi_rready (m_axi_rready),

      .m_axi_awvalid(stripe_axi_awvalid),
      .m_axi_awid   (stripe_axi_awid),
      .m_axi_awaddr (stripe_axi_awaddr),
      .m_axi_awlen  (stripe_axi_awlen),
      .m_axi_awsize (stripe_axi_awsize),
      .m_axi_awburst(stripe_axi_awburst),
      .m_axi_awready(stripe_axi_awready),
      .m_axi_wvalid (stripe_axi_wvalid),
      .m_axi_wdata  (stripe_axi_wdata),
      .m_axi_wstrb  (stripe_axi_wstrb),
      .m_axi_wlast  (stripe_axi_wlast),
      .m_axi_wready (stripe_axi_wready),
      .m_axi_bvalid (stripe_axi_bvalid),
      .m_axi_bid    (stripe_axi_bid),
      .m_axi_bresp  (stripe_axi_bresp),
      .m_axi_bready (stripe_axi_bready),

      .m_axi_arvalid(stripe_axi_arvalid),
      .m_axi_arid   (stripe_axi_arid),
      .m_axi_araddr (stripe_axi_araddr),
      .m_axi_arlen  (stripe_axi_arlen),
      .m_axi_arsize (stripe_axi_arsize),
      .m_axi_arburst(stripe_axi_arburst),
      .m_axi_arready(stripe_axi_arready),
      .m_axi_rvalid (stripe_axi_rvalid),
      .m_axi_rid    (stripe_axi_rid),
      .m_axi_rdata  (stripe_axi_rdata),
      .m_axi_rresp  (stripe_axi_rresp),
      .m_axi_rlast  (stripe_axi_rlast),
      .m_axi_rready (stripe_axi_rready)
  );

  mem_test_axi #(
      .AXI_ADDR_WIDTH(SAW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH  (IW),
      .NUM_BURSTS    (NUM_BURSTS),
      .NUM_BEATS     (NUM_BEATS),
      .RDATA_WIDTH   (SRAM_RDATA_WIDTH)
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
