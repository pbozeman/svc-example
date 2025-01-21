`include "svc_unit.sv"

`include "blinky.sv"

module blinky_tb;
  logic led;

  `TEST_CLK_NS(clk, 20);
  `TEST_RST_N(clk, rst_n);

  blinky #(
      .CLK_FREQ(100)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),
      .led  (led)
  );

  task automatic test_init();
    `CHECK_FALSE(led);
  endtask

  task automatic test_blink();
    for (int i = 0; i < 50; i++) begin
      `CHECK_FALSE(led);
      `TICK(clk);
    end

    for (int i = 0; i < 50; i++) begin
      `CHECK_TRUE(led);
      `TICK(clk);
    end

    for (int i = 0; i < 50; i++) begin
      `CHECK_FALSE(led);
      `TICK(clk);
    end

    for (int i = 0; i < 50; i++) begin
      `CHECK_TRUE(led);
      `TICK(clk);
    end
  endtask

  `TEST_SUITE_BEGIN(blinky_tb);

  `TEST_CASE(test_init);
  `TEST_CASE(test_blink);

  `TEST_SUITE_END();
endmodule
