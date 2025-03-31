`include "svc.sv"

`include "debug_bridge_demo/debug_bridge_demo.sv"

module top (
    input  wire       CLK100MHZ,
    input  wire       reset,
    output wire [3:0] led,
    input  wire       UART_RX,
    output wire       UART_TX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  wire clk;
  wire rst_n;

  assign led[3] = reset;
  assign led[2] = 1'b0;
  assign led[1] = 1'b0;

  assign clk    = CLK100MHZ;
  assign rst_n  = reset;

  debug_bridge_demo debug_bridge_demo_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX),

      .led(led[0])
  );

endmodule
