`define SVC_TB_PRINT

`include "svc_unit.sv"

`include "uart_demo.sv"

// verilator lint_off: UNUSEDSIGNAL
module uart_demo_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic urx_pin;
  logic utx_pin;

  assign urx_pin = 1'b1;

  uart_demo #(
      .CLOCK_FREQ(100),
      .BAUD_RATE (100)
  ) uut (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(utx_pin),
      .utx_pin(utx_pin)
  );

  task automatic test_basic();
    // This is only a very basic smoke test and isn't testing the actual uart
    #1000000;
  endtask

  `TEST_SUITE_BEGIN(uart_demo_tb, 1000000);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
