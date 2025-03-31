`ifndef DEBUG_BRIDGE_DEMO_SV
`define DEBUG_BRIDGE_DEMO_SV

`include "svc.sv"
`include "svc_axil_bridge_uart.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"
`include "svc_unused.sv"

`include "blinky_reg.sv"

module debug_bridge_demo #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input logic clk,
    input logic rst_n,

    input  logic urx_pin,
    output logic utx_pin,

    output logic led
);
  logic        utx_en;
  logic [ 7:0] utx_data;
  logic        utx_busy;

  logic        urx_valid;
  logic [ 7:0] urx_data;

  logic [31:0] m_axil_awaddr;
  logic        m_axil_awvalid;
  logic        m_axil_awready;
  logic [31:0] m_axil_wdata;
  logic [ 3:0] m_axil_wstrb;
  logic        m_axil_wvalid;
  logic        m_axil_wready;
  logic [ 1:0] m_axil_bresp;
  logic        m_axil_bvalid;
  logic        m_axil_bready;

  logic [31:0] m_axil_araddr;
  logic        m_axil_arvalid;
  logic        m_axil_arready;
  logic [31:0] m_axil_rdata;
  logic [ 1:0] m_axil_rresp;
  logic        m_axil_rvalid;
  logic        m_axil_rready;

  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_rx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_valid(urx_valid),
      .urx_data (urx_data),

      .urx_pin(urx_pin)
  );

  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_tx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .utx_en  (utx_en),
      .utx_data(utx_data),
      .utx_busy(utx_busy),

      .utx_pin(utx_pin)
  );

  svc_axil_bridge_uart svc_axil_bridge_uart_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_valid(urx_valid),
      .urx_data (urx_data),

      .utx_en  (utx_en),
      .utx_data(utx_data),
      .utx_busy(utx_busy),

      .m_axil_awaddr (m_axil_awaddr),
      .m_axil_awvalid(m_axil_awvalid),
      .m_axil_awready(m_axil_awready),
      .m_axil_wdata  (m_axil_wdata),
      .m_axil_wstrb  (m_axil_wstrb),
      .m_axil_wvalid (m_axil_wvalid),
      .m_axil_wready (m_axil_wready),
      .m_axil_bresp  (m_axil_bresp),
      .m_axil_bvalid (m_axil_bvalid),
      .m_axil_bready (m_axil_bready),

      .m_axil_arvalid(m_axil_arvalid),
      .m_axil_araddr (m_axil_araddr),
      .m_axil_arready(m_axil_arready),
      .m_axil_rdata  (m_axil_rdata),
      .m_axil_rresp  (m_axil_rresp),
      .m_axil_rvalid (m_axil_rvalid),
      .m_axil_rready (m_axil_rready)
  );

  blinky_reg #(
      .CLK_FREQ(CLOCK_FREQ)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),
      .led  (led),

      .s_axil_awaddr (8'(m_axil_awaddr)),
      .s_axil_awvalid(m_axil_awvalid),
      .s_axil_awready(m_axil_awready),
      .s_axil_wdata  (m_axil_wdata),
      .s_axil_wstrb  (m_axil_wstrb),
      .s_axil_wvalid (m_axil_wvalid),
      .s_axil_wready (m_axil_wready),
      .s_axil_bresp  (m_axil_bresp),
      .s_axil_bvalid (m_axil_bvalid),
      .s_axil_bready (m_axil_bready),

      .s_axil_araddr (8'(m_axil_araddr)),
      .s_axil_arvalid(m_axil_arvalid),
      .s_axil_arready(m_axil_arready),
      .s_axil_rdata  (m_axil_rdata),
      .s_axil_rresp  (m_axil_rresp),
      .s_axil_rvalid (m_axil_rvalid),
      .s_axil_rready (m_axil_rready)
  );

  `SVC_UNUSED({m_axil_awaddr[31:8], m_axil_araddr[31:8]});

endmodule
`endif
