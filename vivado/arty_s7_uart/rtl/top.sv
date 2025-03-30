`include "svc.sv"

`include "uart_demo/uart_demo.sv"

module top (
    input  wire       CLK100MHZ,
    input  wire       reset,
    output wire [3:0] led,
    input  wire       UART_RX,
    output wire       UART_TX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  wire clk = CLK100MHZ;
  wire rst_n = reset;

  assign led[3] = reset;
  assign led[2] = 1'b0;
  assign led[1] = 1'b0;
  assign led[0] = 1'b0;

  assign clk    = CLK100MHZ;
  assign rst_n  = reset;

  uart_demo uart_demo_i (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(UART_RX),
      .utx_pin(UART_TX)
  );

endmodule
