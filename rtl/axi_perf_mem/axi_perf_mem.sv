`ifndef AXI_PERF_MEM_SV
`define AXI_PERF_MEM_SV

`include "svc.sv"
`include "svc_axi_mem.sv"

`include "axi_perf.sv"

module axi_perf_mem #(
    parameter NAME           = "axi_perf_mem",
    parameter CLOCK_FREQ     = 100_000_000,
    parameter BAUD_RATE      = 115_200,
    parameter AXI_ADDR_WIDTH = 8,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8
) (
    input logic clk,
    input logic rst_n,

    input  logic urx_pin,
    output logic utx_pin
);
  logic                      mem_axi_awvalid;
  logic [AXI_ADDR_WIDTH-1:0] mem_axi_awaddr;
  logic [  AXI_ID_WIDTH-1:0] mem_axi_awid;
  logic [               7:0] mem_axi_awlen;
  logic [               2:0] mem_axi_awsize;
  logic [               1:0] mem_axi_awburst;
  logic                      mem_axi_awready;
  logic                      mem_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] mem_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] mem_axi_wstrb;
  logic                      mem_axi_wlast;
  logic                      mem_axi_wready;
  logic                      mem_axi_bvalid;
  logic [  AXI_ID_WIDTH-1:0] mem_axi_bid;
  logic [               1:0] mem_axi_bresp;
  logic                      mem_axi_bready;

  // verilator lint_off: UNUSEDSIGNAL
  logic                      mem_axi_arvalid;
  logic [  AXI_ID_WIDTH-1:0] mem_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0] mem_axi_araddr;
  logic [               7:0] mem_axi_arlen;
  logic [               2:0] mem_axi_arsize;
  logic [               1:0] mem_axi_arburst;
  logic                      mem_axi_arready;
  logic                      mem_axi_rvalid;
  logic [  AXI_ID_WIDTH-1:0] mem_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] mem_axi_rdata;
  logic [               1:0] mem_axi_rresp;
  logic                      mem_axi_rlast;
  logic                      mem_axi_rready;
  // verilator lint_on: UNUSEDSIGNAL

  assign mem_axi_arvalid = 1'b0;
  assign mem_axi_arid    = 0;
  assign mem_axi_araddr  = 0;
  assign mem_axi_arlen   = 0;
  assign mem_axi_arsize  = 0;
  assign mem_axi_arburst = 0;
  assign mem_axi_rready  = 1'b0;

  svc_axi_mem #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_axi_mem_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(mem_axi_awvalid),
      .s_axi_awaddr (mem_axi_awaddr),
      .s_axi_awid   (mem_axi_awid),
      .s_axi_awlen  (mem_axi_awlen),
      .s_axi_awsize (mem_axi_awsize),
      .s_axi_awburst(mem_axi_awburst),
      .s_axi_awready(mem_axi_awready),
      .s_axi_wdata  (mem_axi_wdata),
      .s_axi_wstrb  (mem_axi_wstrb),
      .s_axi_wlast  (mem_axi_wlast),
      .s_axi_wvalid (mem_axi_wvalid),
      .s_axi_wready (mem_axi_wready),
      .s_axi_bresp  (mem_axi_bresp),
      .s_axi_bid    (mem_axi_bid),
      .s_axi_bvalid (mem_axi_bvalid),
      .s_axi_bready (mem_axi_bready),
      .s_axi_arvalid(mem_axi_arvalid),
      .s_axi_araddr (mem_axi_araddr),
      .s_axi_arid   (mem_axi_arid),
      .s_axi_arready(mem_axi_arready),
      .s_axi_arlen  (mem_axi_arlen),
      .s_axi_arsize (mem_axi_arsize),
      .s_axi_arburst(mem_axi_arburst),
      .s_axi_rvalid (mem_axi_rvalid),
      .s_axi_rid    (mem_axi_rid),
      .s_axi_rresp  (mem_axi_rresp),
      .s_axi_rlast  (mem_axi_rlast),
      .s_axi_rdata  (mem_axi_rdata),
      .s_axi_rready (mem_axi_rready)
  );

  axi_perf #(
      .NAME          (NAME),
      .CLOCK_FREQ    (CLOCK_FREQ),
      .BAUD_RATE     (BAUD_RATE),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) axi_perf_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_pin(urx_pin),
      .utx_pin(utx_pin),

      .m_axi_awvalid(mem_axi_awvalid),
      .m_axi_awaddr (mem_axi_awaddr),
      .m_axi_awid   (mem_axi_awid),
      .m_axi_awlen  (mem_axi_awlen),
      .m_axi_awsize (mem_axi_awsize),
      .m_axi_awburst(mem_axi_awburst),
      .m_axi_awready(mem_axi_awready),
      .m_axi_wvalid (mem_axi_wvalid),
      .m_axi_wdata  (mem_axi_wdata),
      .m_axi_wstrb  (mem_axi_wstrb),
      .m_axi_wlast  (mem_axi_wlast),
      .m_axi_wready (mem_axi_wready),
      .m_axi_bvalid (mem_axi_bvalid),
      .m_axi_bid    (mem_axi_bid),
      .m_axi_bresp  (mem_axi_bresp),
      .m_axi_bready (mem_axi_bready)
  );

endmodule
`endif
