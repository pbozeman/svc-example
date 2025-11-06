`include "svc.sv"
`include "svc_init.sv"

`include "rv_bubble_sort.sv"

module rv_bubble_sort_top (
    input logic CLK,

    output logic UART_TX,

    output logic LED1,
    output logic LED2
);
  //
  // Clock frequency matches board clock
  //
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  logic rst_n;
  logic ebreak;

  //
  // Reset generation
  //
  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  //
  // RISC-V bubble sort instance
  //
  rv_bubble_sort #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) rv_bubble_sort_i (
      .clk    (CLK),
      .rst_n  (rst_n),
      .uart_tx(UART_TX),
      .ebreak (ebreak)
  );

  //
  // Status LEDs
  //
  // LED1: Active when not in reset
  // LED2: Indicates ebreak hit
  //
  assign LED1 = rst_n;
  assign LED2 = ebreak;

endmodule
