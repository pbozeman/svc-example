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
    for (int i = 0; i < 2; i++) begin
      `CHECK_WAIT_FOR(clk, uut.str_valid && uut.str_ready, 1000);
    end
  endtask

  `TEST_SUITE_BEGIN(uart_demo_tb);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
