`include "svc.sv"
`include "svc_init.sv"

`include "debug_bridge_demo.sv"

module debug_bridge_demo_top (
    input logic CLK,

    input  logic UART_RX,
    output logic UART_TX,

    output logic LED1
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  debug_bridge_demo #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) debug_bridge_demo_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX),

      .led(LED1)
  );

endmodule
