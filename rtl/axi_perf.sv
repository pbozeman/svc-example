`ifndef AXI_PERF_SV
`define AXI_PERF_SV

`include "svc.sv"
`include "svc_axi_arbiter.sv"
`include "svc_axi_null_rd.sv"
`include "svc_axi_null_rd.sv"
`include "svc_axi_stats_wr.sv"
`include "svc_axil_bridge_uart.sv"
`include "svc_axil_router.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"
`include "svc_unused.sv"

`include "axi_perf_wr.sv"

// This is still a bit hacky and still in POC phase for both stats and how
// reporting is going to work

module axi_perf #(
    parameter CLOCK_FREQ     = 100_000_000,
    parameter BAUD_RATE      = 115_200,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8,
    parameter STAT_WIDTH     = 32
) (
    input logic clk,
    input logic rst_n,

    input  logic urx_pin,
    output logic utx_pin,

    output logic                      m_axi_awvalid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [  AXI_ID_WIDTH-1:0] m_axi_awid,
    output logic [               7:0] m_axi_awlen,
    output logic [               2:0] m_axi_awsize,
    output logic [               1:0] m_axi_awburst,
    input  logic                      m_axi_awready,
    output logic                      m_axi_wvalid,
    output logic [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                      m_axi_wlast,
    input  logic                      m_axi_wready,
    input  logic                      m_axi_bvalid,
    input  logic [  AXI_ID_WIDTH-1:0] m_axi_bid,
    input  logic [               1:0] m_axi_bresp,
    output logic                      m_axi_bready
);
  localparam NUM_M = 2;
  localparam AW = AXI_ADDR_WIDTH;
  localparam DW = AXI_DATA_WIDTH;
  localparam IW = AXI_ID_WIDTH;
  localparam STRBW = AXI_STRB_WIDTH;

  localparam AIW = AXI_ID_WIDTH - $clog2(NUM_M);

  // TODO: these widths are going to be used in a lot of places. Standardize
  // their naming and put them in a common spot in svc.

  // AXI Bridge widths
  localparam AB_AW = 32;
  localparam AB_DW = 32;
  localparam AB_SW = AB_DW / 8;

  // Stat widths
  localparam S_AW = 8;
  localparam S_DW = 32;
  localparam S_SW = S_DW / 8;

  logic [NUM_M-1:0]            perf_axi_awvalid;
  logic [NUM_M-1:0][   AW-1:0] perf_axi_awaddr;
  logic [NUM_M-1:0][  AIW-1:0] perf_axi_awid;
  logic [NUM_M-1:0][      7:0] perf_axi_awlen;
  logic [NUM_M-1:0][      2:0] perf_axi_awsize;
  logic [NUM_M-1:0][      1:0] perf_axi_awburst;
  logic [NUM_M-1:0]            perf_axi_awready;
  logic [NUM_M-1:0]            perf_axi_wvalid;
  logic [NUM_M-1:0][   DW-1:0] perf_axi_wdata;
  logic [NUM_M-1:0][STRBW-1:0] perf_axi_wstrb;
  logic [NUM_M-1:0]            perf_axi_wlast;
  logic [NUM_M-1:0]            perf_axi_wready;
  logic [NUM_M-1:0]            perf_axi_bvalid;
  logic [NUM_M-1:0][  AIW-1:0] perf_axi_bid;
  logic [NUM_M-1:0][      1:0] perf_axi_bresp;
  logic [NUM_M-1:0]            perf_axi_bready;

  logic [NUM_M-1:0]            perf_axi_arvalid;
  logic [NUM_M-1:0][  AIW-1:0] perf_axi_arid;
  logic [NUM_M-1:0][   AW-1:0] perf_axi_araddr;
  logic [NUM_M-1:0][      7:0] perf_axi_arlen;
  logic [NUM_M-1:0][      2:0] perf_axi_arsize;
  logic [NUM_M-1:0][      1:0] perf_axi_arburst;
  logic [NUM_M-1:0]            perf_axi_arready;
  logic [NUM_M-1:0]            perf_axi_rvalid;
  logic [NUM_M-1:0][  AIW-1:0] perf_axi_rid;
  logic [NUM_M-1:0][   DW-1:0] perf_axi_rdata;
  logic [NUM_M-1:0][      1:0] perf_axi_rresp;
  logic [NUM_M-1:0]            perf_axi_rlast;
  logic [NUM_M-1:0]            perf_axi_rready;

  // TODO: pass these signals in, since ultimately we'll be doing both
  // for now, we need to null the arbiter inputs
  logic                        m_axi_arvalid;
  logic [   IW-1:0]            m_axi_arid;
  logic [   AW-1:0]            m_axi_araddr;
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

  //
  // external control interface
  //
  logic                        ctrl_awvalid;
  logic [AB_AW-1:0]            ctrl_awaddr;
  logic                        ctrl_awready;
  logic [AB_DW-1:0]            ctrl_wdata;
  logic [AB_SW-1:0]            ctrl_wstrb;
  logic                        ctrl_wvalid;
  logic                        ctrl_wready;
  logic                        ctrl_bvalid;
  logic [      1:0]            ctrl_bresp;
  logic                        ctrl_bready;

  logic                        ctrl_arvalid;
  logic [AB_AW-1:0]            ctrl_araddr;
  logic                        ctrl_arready;
  logic                        ctrl_rvalid;
  logic [AB_DW-1:0]            ctrl_rdata;
  logic [      1:0]            ctrl_rresp;
  logic                        ctrl_rready;

  logic                        utx_valid;
  logic [      7:0]            utx_data;
  logic                        utx_ready;

  logic                        urx_valid;
  logic [      7:0]            urx_data;
  logic                        urx_ready;

  //
  // axi stats control interface
  //
  logic                        stats_top_awvalid;
  logic [ S_AW-1:0]            stats_top_awaddr;
  logic                        stats_top_awready;
  logic [ S_DW-1:0]            stats_top_wdata;
  logic [ S_SW-1:0]            stats_top_wstrb;
  logic                        stats_top_wvalid;
  logic                        stats_top_wready;
  logic                        stats_top_bvalid;
  logic [      1:0]            stats_top_bresp;
  logic                        stats_top_bready;

  logic                        stats_top_arvalid;
  logic [ S_AW-1:0]            stats_top_araddr;
  logic                        stats_top_arready;
  logic                        stats_top_rvalid;
  logic [ S_DW-1:0]            stats_top_rdata;
  logic [      1:0]            stats_top_rresp;
  logic                        stats_top_rready;

  logic [NUM_M-1:0]            stats_perf_awvalid;
  logic [NUM_M-1:0][ S_AW-1:0] stats_perf_awaddr;
  logic [NUM_M-1:0]            stats_perf_awready;
  logic [NUM_M-1:0][ S_DW-1:0] stats_perf_wdata;
  logic [NUM_M-1:0][ S_SW-1:0] stats_perf_wstrb;
  logic [NUM_M-1:0]            stats_perf_wvalid;
  logic [NUM_M-1:0]            stats_perf_wready;
  logic [NUM_M-1:0]            stats_perf_bvalid;
  logic [NUM_M-1:0][      1:0] stats_perf_bresp;
  logic [NUM_M-1:0]            stats_perf_bready;

  logic [NUM_M-1:0]            stats_perf_arvalid;
  logic [NUM_M-1:0][ S_AW-1:0] stats_perf_araddr;
  logic [NUM_M-1:0]            stats_perf_arready;
  logic [NUM_M-1:0]            stats_perf_rvalid;
  logic [NUM_M-1:0][ S_DW-1:0] stats_perf_rdata;
  logic [NUM_M-1:0][      1:0] stats_perf_rresp;
  logic [NUM_M-1:0]            stats_perf_rready;

  // arb from the perf signals to the m_ output signals going to the memory
  // device
  svc_axi_arbiter #(
      .NUM_M         (NUM_M),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AIW)
  ) svc_axi_arbiter_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(perf_axi_awvalid),
      .s_axi_awaddr (perf_axi_awaddr),
      .s_axi_awid   (perf_axi_awid),
      .s_axi_awlen  (perf_axi_awlen),
      .s_axi_awsize (perf_axi_awsize),
      .s_axi_awburst(perf_axi_awburst),
      .s_axi_awready(perf_axi_awready),
      .s_axi_wdata  (perf_axi_wdata),
      .s_axi_wstrb  (perf_axi_wstrb),
      .s_axi_wlast  (perf_axi_wlast),
      .s_axi_wvalid (perf_axi_wvalid),
      .s_axi_wready (perf_axi_wready),
      .s_axi_bresp  (perf_axi_bresp),
      .s_axi_bid    (perf_axi_bid),
      .s_axi_bvalid (perf_axi_bvalid),
      .s_axi_bready (perf_axi_bready),
      .s_axi_arvalid(perf_axi_arvalid),
      .s_axi_araddr (perf_axi_araddr),
      .s_axi_arid   (perf_axi_arid),
      .s_axi_arready(perf_axi_arready),
      .s_axi_arlen  (perf_axi_arlen),
      .s_axi_arsize (perf_axi_arsize),
      .s_axi_arburst(perf_axi_arburst),
      .s_axi_rvalid (perf_axi_rvalid),
      .s_axi_rid    (perf_axi_rid),
      .s_axi_rresp  (perf_axi_rresp),
      .s_axi_rlast  (perf_axi_rlast),
      .s_axi_rdata  (perf_axi_rdata),
      .s_axi_rready (perf_axi_rready),

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
      .m_axi_rresp  (m_axi_rresp),
      .m_axi_rlast  (m_axi_rlast),
      .m_axi_rdata  (m_axi_rdata),
      .m_axi_rready (m_axi_rready)
  );

  // null out all the reads
  for (genvar i = 0; i < NUM_M; i++) begin : gen_null_rd
    svc_axi_null_rd #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH  (AIW)
    ) svc_axi_null_rd_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .m_axi_arvalid(perf_axi_arvalid[i]),
        .m_axi_arid   (perf_axi_arid[i]),
        .m_axi_araddr (perf_axi_araddr[i]),
        .m_axi_arlen  (perf_axi_arlen[i]),
        .m_axi_arsize (perf_axi_arsize[i]),
        .m_axi_arburst(perf_axi_arburst[i]),
        .m_axi_arready(perf_axi_arready[i]),
        .m_axi_rvalid (perf_axi_rvalid[i]),
        .m_axi_rid    (perf_axi_rid[i]),
        .m_axi_rdata  (perf_axi_rdata[i]),
        .m_axi_rresp  (perf_axi_rresp[i]),
        .m_axi_rlast  (perf_axi_rlast[i]),
        .m_axi_rready (perf_axi_rready[i])
    );
  end

  //-------------------------------------------------------------------------
  //
  // control interface
  //
  //-------------------------------------------------------------------------
  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_rx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_valid(urx_valid),
      .urx_data (urx_data),
      .urx_ready(urx_ready),

      .urx_pin(urx_pin)
  );

  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_tx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .utx_valid(utx_valid),
      .utx_data (utx_data),
      .utx_ready(utx_ready),

      .utx_pin(utx_pin)
  );

  svc_axil_bridge_uart #(
      .AXIL_ADDR_WIDTH(AB_AW),
      .AXIL_DATA_WIDTH(AB_DW)
  ) svc_axil_bridge_uart_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_valid(urx_valid),
      .urx_data (urx_data),
      .urx_ready(urx_ready),

      .utx_valid(utx_valid),
      .utx_data (utx_data),
      .utx_ready(utx_ready),

      .m_axil_awaddr (ctrl_awaddr),
      .m_axil_awvalid(ctrl_awvalid),
      .m_axil_awready(ctrl_awready),
      .m_axil_wdata  (ctrl_wdata),
      .m_axil_wstrb  (ctrl_wstrb),
      .m_axil_wvalid (ctrl_wvalid),
      .m_axil_wready (ctrl_wready),
      .m_axil_bresp  (ctrl_bresp),
      .m_axil_bvalid (ctrl_bvalid),
      .m_axil_bready (ctrl_bready),

      .m_axil_arvalid(ctrl_arvalid),
      .m_axil_araddr (ctrl_araddr),
      .m_axil_arready(ctrl_arready),
      .m_axil_rdata  (ctrl_rdata),
      .m_axil_rresp  (ctrl_rresp),
      .m_axil_rvalid (ctrl_rvalid),
      .m_axil_rready (ctrl_rready)
  );

  svc_axil_router #(
      .S_AXIL_ADDR_WIDTH(AB_AW),
      .S_AXIL_DATA_WIDTH(AB_DW),
      .M_AXIL_ADDR_WIDTH(S_AW),
      .M_AXIL_DATA_WIDTH(S_DW),
      .NUM_S            (NUM_M + 1)
  ) svc_axil_router_i (
      .clk  (clk),
      .rst_n(rst_n),

      .s_axil_awaddr (ctrl_awaddr),
      .s_axil_awvalid(ctrl_awvalid),
      .s_axil_awready(ctrl_awready),
      .s_axil_wdata  (ctrl_wdata),
      .s_axil_wstrb  (ctrl_wstrb),
      .s_axil_wvalid (ctrl_wvalid),
      .s_axil_wready (ctrl_wready),
      .s_axil_bresp  (ctrl_bresp),
      .s_axil_bvalid (ctrl_bvalid),
      .s_axil_bready (ctrl_bready),

      .s_axil_arvalid(ctrl_arvalid),
      .s_axil_araddr (ctrl_araddr),
      .s_axil_arready(ctrl_arready),
      .s_axil_rdata  (ctrl_rdata),
      .s_axil_rresp  (ctrl_rresp),
      .s_axil_rvalid (ctrl_rvalid),
      .s_axil_rready (ctrl_rready),

      .m_axil_awvalid({stats_perf_awvalid, stats_top_awvalid}),
      .m_axil_awaddr ({stats_perf_awaddr, stats_top_awaddr}),
      .m_axil_awready({stats_perf_awready, stats_top_awready}),
      .m_axil_wvalid ({stats_perf_wvalid, stats_top_wvalid}),
      .m_axil_wdata  ({stats_perf_wdata, stats_top_wdata}),
      .m_axil_wstrb  ({stats_perf_wstrb, stats_top_wstrb}),
      .m_axil_wready ({stats_perf_wready, stats_top_wready}),
      .m_axil_bvalid ({stats_perf_bvalid, stats_top_bvalid}),
      .m_axil_bresp  ({stats_perf_bresp, stats_top_bresp}),
      .m_axil_bready ({stats_perf_bready, stats_top_bready}),


      .m_axil_arvalid({stats_perf_arvalid, stats_top_arvalid}),
      .m_axil_araddr ({stats_perf_araddr, stats_top_araddr}),
      .m_axil_arready({stats_perf_arready, stats_top_arready}),
      .m_axil_rdata  ({stats_perf_rdata, stats_top_rdata}),
      .m_axil_rresp  ({stats_perf_rresp, stats_top_rresp}),
      .m_axil_rvalid ({stats_perf_rvalid, stats_top_rvalid}),
      .m_axil_rready ({stats_perf_rready, stats_top_rready})
  );

  typedef enum {
    STATE_IDLE,
    STATE_HEADER,
    STATE_HEADER_WAIT,
    STATE_RUN,
    STATE_RUN_WAIT,
    STATE_REPORT,
    STATE_REPORT_ITER,
    STATE_REPORT_ITER_SEND,
    STATE_REPORT_ITER_SEND_WAIT,
    STATE_REPORT_ITER_SEND_DONE,
    STATE_DONE
  } state_t;

  state_t                     state;
  state_t                     state_next;

  logic   [NUM_M-1:0]         wr_start;
  logic   [NUM_M-1:0]         wr_busy;

  logic   [NUM_M-1:0][AW-1:0] wr_base_addr;
  logic   [NUM_M-1:0][   7:0] wr_burst_beats;
  logic   [NUM_M-1:0][AW-1:0] wr_burst_stride;
  logic   [NUM_M-1:0][  15:0] wr_burst_num;
  logic   [NUM_M-1:0][   2:0] wr_burst_awsize;

  // TODO: make these configurable
  assign wr_base_addr[0]    = 0;
  assign wr_burst_beats[0]  = 64;
  assign wr_burst_stride[0] = 128 * (AXI_DATA_WIDTH / 8);
  assign wr_burst_num[0]    = 16;
  assign wr_burst_awsize[0] = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);

  assign wr_base_addr[1]    = 0;
  assign wr_burst_beats[1]  = 64;
  assign wr_burst_stride[1] = 128 * (AXI_DATA_WIDTH / 8);
  assign wr_burst_num[1]    = 16;
  assign wr_burst_awsize[1] = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);

  for (genvar i = 0; i < NUM_M; i++) begin : gen_perf_wr
    axi_perf_wr #(
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH  (AIW)
    ) axi_perf_wr_i (
        .clk  (clk),
        .rst_n(rst_n),

        .start(wr_start[i]),
        .busy (wr_busy[i]),

        .base_addr   (wr_base_addr[i]),
        .burst_beats (wr_burst_beats[i]),
        .burst_stride(wr_burst_stride[i]),
        .burst_num   (wr_burst_num[i]),
        .burst_awsize(wr_burst_awsize[i]),

        .m_axi_awvalid(perf_axi_awvalid[i]),
        .m_axi_awaddr (perf_axi_awaddr[i]),
        .m_axi_awid   (perf_axi_awid[i]),
        .m_axi_awlen  (perf_axi_awlen[i]),
        .m_axi_awsize (perf_axi_awsize[i]),
        .m_axi_awburst(perf_axi_awburst[i]),
        .m_axi_awready(perf_axi_awready[i]),
        .m_axi_wvalid (perf_axi_wvalid[i]),
        .m_axi_wdata  (perf_axi_wdata[i]),
        .m_axi_wstrb  (perf_axi_wstrb[i]),
        .m_axi_wlast  (perf_axi_wlast[i]),
        .m_axi_wready (perf_axi_wready[i]),
        .m_axi_bvalid (perf_axi_bvalid[i]),
        .m_axi_bid    (perf_axi_bid[i]),
        .m_axi_bresp  (perf_axi_bresp[i]),
        .m_axi_bready (perf_axi_bready[i])
    );

    svc_axi_stats_wr #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH   (AIW),
        .STAT_WIDTH     (STAT_WIDTH),
        .AXIL_ADDR_WIDTH(S_AW),
        .AXIL_DATA_WIDTH(S_DW)
    ) svc_axi_stats_wr_perf (
        .clk  (clk),
        .rst_n(rst_n),

        .stat_clear(1'b0),
        .stat_err  (),

        // control interface
        .s_axil_awaddr (stats_perf_awaddr[i]),
        .s_axil_awvalid(stats_perf_awvalid[i]),
        .s_axil_awready(stats_perf_awready[i]),
        .s_axil_wdata  (stats_perf_wdata[i]),
        .s_axil_wstrb  (stats_perf_wstrb[i]),
        .s_axil_wvalid (stats_perf_wvalid[i]),
        .s_axil_wready (stats_perf_wready[i]),
        .s_axil_bvalid (stats_perf_bvalid[i]),
        .s_axil_bresp  (stats_perf_bresp[i]),
        .s_axil_bready (stats_perf_bready[i]),

        .s_axil_arvalid(stats_perf_arvalid[i]),
        .s_axil_araddr (stats_perf_araddr[i]),
        .s_axil_arready(stats_perf_arready[i]),
        .s_axil_rvalid (stats_perf_rvalid[i]),
        .s_axil_rdata  (stats_perf_rdata[i]),
        .s_axil_rresp  (stats_perf_rresp[i]),
        .s_axil_rready (stats_perf_rready[i]),

        // interface for stats
        .m_axi_awvalid(perf_axi_awvalid[i]),
        .m_axi_awaddr (perf_axi_awaddr[i]),
        .m_axi_awid   (perf_axi_awid[i]),
        .m_axi_awlen  (perf_axi_awlen[i]),
        .m_axi_awsize (perf_axi_awsize[i]),
        .m_axi_awburst(perf_axi_awburst[i]),
        .m_axi_awready(perf_axi_awready[i]),
        .m_axi_wvalid (perf_axi_wvalid[i]),
        .m_axi_wdata  (perf_axi_wdata[i]),
        .m_axi_wstrb  (perf_axi_wstrb[i]),
        .m_axi_wlast  (perf_axi_wlast[i]),
        .m_axi_wready (perf_axi_wready[i]),
        .m_axi_bvalid (perf_axi_bvalid[i]),
        .m_axi_bid    (perf_axi_bid[i]),
        .m_axi_bresp  (perf_axi_bresp[i]),
        .m_axi_bready (perf_axi_bready[i])
    );
  end

  // TODO: keep the top level, but also have per manager stats
  svc_axi_stats_wr #(
      .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH   (IW),
      .STAT_WIDTH     (STAT_WIDTH),
      .AXIL_ADDR_WIDTH(S_AW),
      .AXIL_DATA_WIDTH(S_DW)
  ) svc_axi_stats_wr_top (
      .clk  (clk),
      .rst_n(rst_n),

      .stat_clear(1'b0),
      .stat_err  (),

      // control interface
      .s_axil_awaddr (stats_top_awaddr),
      .s_axil_awvalid(stats_top_awvalid),
      .s_axil_awready(stats_top_awready),
      .s_axil_wdata  (stats_top_wdata),
      .s_axil_wstrb  (stats_top_wstrb),
      .s_axil_wvalid (stats_top_wvalid),
      .s_axil_wready (stats_top_wready),
      .s_axil_bvalid (stats_top_bvalid),
      .s_axil_bresp  (stats_top_bresp),
      .s_axil_bready (stats_top_bready),

      .s_axil_arvalid(stats_top_arvalid),
      .s_axil_araddr (stats_top_araddr),
      .s_axil_arready(stats_top_arready),
      .s_axil_rvalid (stats_top_rvalid),
      .s_axil_rdata  (stats_top_rdata),
      .s_axil_rresp  (stats_top_rresp),
      .s_axil_rready (stats_top_rready),

      // interface for stats
      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wlast  (m_axi_wlast),
      .m_axi_wready (m_axi_wready),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bid    (m_axi_bid),
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bready (m_axi_bready)
  );

  always @(*) begin
    state_next  = state;

    // TODO: state management for all managers, for now, hack it in
    wr_start[0] = 1'b0;
    wr_start[1] = 1'b0;

    case (state)
      STATE_IDLE: begin
        state_next = STATE_RUN;
      end

      STATE_RUN: begin
        // TODO: make these configurable
        wr_start[0] = 1'b1;
        wr_start[1] = 1'b1;
        state_next  = STATE_RUN_WAIT;
      end

      STATE_RUN_WAIT: begin
        if (!wr_busy[0] && !wr_busy[1]) begin
          state_next = STATE_DONE;
        end
      end

      STATE_DONE: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
    end else begin
      state <= state_next;
    end
  end

  // TODO: remove all of these when these get passed in
  assign m_axi_arready = 1'b0;
  assign m_axi_rvalid  = 1'b0;
  assign m_axi_rid     = 0;
  assign m_axi_rlast   = 1'b0;
  assign m_axi_rdata   = 0;
  assign m_axi_rresp   = 2'b11;

  `SVC_UNUSED({m_axi_arvalid, m_axi_araddr, m_axi_arid, m_axi_arlen,
               m_axi_arsize, m_axi_arburst, m_axi_rready});


endmodule
`endif
