`include "svc_unit.sv"

`include "axi_perf_mem.sv"


// verilator lint_off: UNUSEDSIGNAL
module axi_perf_mem_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic utx_pin;
  logic urx_pin;

  assign urx_pin = 1'b1;

  axi_perf_mem #(
      .CLOCK_FREQ(100),
      .BAUD_RATE (100)
  ) uut (
      .clk    (clk),
      .rst_n  (rst_n),
      .utx_pin(utx_pin),
      .urx_pin(urx_pin)
  );

  task automatic test_basic();
    // This is only a very basic smoke test to make sure it compiles
    // and we can look at wave forms
    #200000;
  endtask

  `TEST_SUITE_BEGIN(axi_perf_mem_tb, 200000);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
