`include "svc_unit.sv"

`include "uart_demo.sv"

// verilator lint_off: UNUSEDSIGNAL
module uart_demo_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic utx_pin;

  uart_demo #(
      .CLOCK_FREQ(100),
      .BAUD_RATE (10)
  ) uut (
      .clk    (clk),
      .rst_n  (rst_n),
      .utx_pin(utx_pin)
  );

  task automatic test_basic();
    // This is only a very basic smoke test and isn't testing the actual uart
    #100000;
  endtask

  `TEST_SUITE_BEGIN(uart_demo_tb, 1000000);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
