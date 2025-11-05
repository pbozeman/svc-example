`include "svc.sv"

`include "svc_soc_sim.sv"
`include "svc_soc_sim_uart.sv"
`include "uart_demo.sv"

// Standalone interactive simulation for uart_demo
//
//
// Usage:
//   iverilog -g2012 -Isvc -Irtl -Itb -o uart_demo_sim.vvp rtl/uart_demo/uart_demo_sim.sv
//   vvp uart_demo_sim.vvp

module uart_demo_sim;
  // Clock and reset from simulation infrastructure
  logic clk;
  logic rst_n;

  svc_soc_sim #(
      .CLOCK_FREQ_MHZ(100)
  ) sim_infra (
      .clk  (clk),
      .rst_n(rst_n)
  );

  // UART pins
  logic urx_pin;
  logic utx_pin;

  // Instantiate the DUT with realistic clock/baud parameters
  uart_demo #(
      .CLOCK_FREQ(100_000_000),
      .BAUD_RATE (115_200)
  ) dut (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(urx_pin),
      .utx_pin(utx_pin)
  );

  // Instantiate UART terminal model
  // PRINT_RX=1 makes it print received characters to console in real-time
  svc_soc_sim_uart #(
      .CLOCK_FREQ(100_000_000),
      .BAUD_RATE (115_200),
      .PRINT_RX  (1),
      .DEBUG     (0)
  ) uart_terminal (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(urx_pin),
      .utx_pin(utx_pin)
  );

  // Simulation control and interactive commands
  initial begin
    // Wait for reset
    wait (rst_n);
    #10000;

    // Display banner
    $display("");
    $display("=== UART Demo Standalone Simulation ===");
    $display("Waiting for DUT to send hello message...");
    $display("");

    // Wait for hello message to be sent
    #5000000;

    // Send some test input
    $display("");
    $display("Sending test input: 'hello world'");
    uart_terminal.send_string("hello world");

    // Run for a while to see the echo response
    #10000000;

    // Send another test
    $display("");
    $display("Sending test input: 'abc123'");
    uart_terminal.send_string("abc123");

    // Run longer
    #10000000;

    // Statistics
    $display("");
    $display("=== Simulation Statistics ===");
    $display("UART RX chars received: %0d", uart_terminal.rx_char_count);
    $display("UART TX chars sent:     %0d", uart_terminal.tx_char_count);
    $display("");

    $finish;
  end

  // Optional: Uncomment to generate VCD for waveform viewing
  // initial begin
  //   $dumpfile("uart_demo_sim.vcd");
  //   $dumpvars(0, uart_demo_sim);
  // end

endmodule
