`include "svc.sv"
`include "svc_init.sv"

`include "axi_perf_mem.sv"

module axi_perf_mem_top (
    input  logic CLK,
    output logic LED1,
    output logic UART_TX,
    input  logic UART_RX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;
  localparam STAT_WIDTH = 16;

  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  axi_perf_mem #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .STAT_WIDTH(STAT_WIDTH)
  ) axi_perf_mem_i (
      .clk    (CLK),
      .rst_n  (rst_n),
      .urx_pin(UART_RX),
      .utx_pin(UART_TX)
  );

  assign LED1 = 1'b0;

endmodule
