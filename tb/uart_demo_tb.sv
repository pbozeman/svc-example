`define SVC_TB_PRINT

`include "svc_unit.sv"
`include "soc/svc_soc_model_uart.sv"
`include "uart_demo.sv"

// verilator lint_off: UNUSEDSIGNAL
module uart_demo_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic urx_pin;
  logic utx_pin;

  uart_demo #(
      .CLOCK_FREQ(10_000_000),
      .BAUD_RATE (1_000_000)
  ) uut (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(urx_pin),
      .utx_pin(utx_pin)
  );

  // Instantiate UART model to simulate terminal
  svc_soc_model_uart #(
      .CLOCK_FREQ(10_000_000),
      .BAUD_RATE (1_000_000),
      .PRINT_RX  (0),
      .DEBUG     (0)
  ) uart_model (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(urx_pin),
      .utx_pin(utx_pin)
  );

  task automatic test_basic();
    logic [7:0] ch;

    // Wait for UUT to send "Hello - to upper:\r\n"
    repeat (100000) `TICK(clk);

    // Verify we received some characters
    `CHECK_GT(uart_model.rx_char_count, 0);
  endtask

  task automatic test_echo();
    // Wait for UUT to send hello message first
    repeat (50000) `TICK(clk);

    // Send some lowercase characters to be echoed back as uppercase
    uart_model.send_string("enbiggen");

    // Wait for echo response
    repeat (50000) `TICK(clk);

    // Should have received both the hello message and the echoed characters
    `CHECK_GT(uart_model.rx_char_count, 5);
  endtask

  `TEST_SUITE_BEGIN(uart_demo_tb, 1000000);
  `TEST_CASE(test_basic);
  `TEST_CASE(test_echo);
  `TEST_SUITE_END();
endmodule
