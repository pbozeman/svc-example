`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V blinky demo
//
// Usage:
//   make sw
//   make rv_blinky_sim
//
module rv_blinky_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 100000;

  //
  // Signals
  //
  logic       clk;
  logic       rst_n;
  logic       uart_tx_unused;
  logic       led;
  logic [7:0] gpio;
  logic       done;

  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_AW        (10),
      .DMEM_AW        (10),
      .IMEM_INIT      (".build/sw/blinky/blinky.hex"),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .TITLE          ("Blinky"),
      .SW_PATH        ("sw/blinky/main.c")
  ) sim (
      .clk    (clk),
      .rst_n  (rst_n),
      .uart_tx(uart_tx_unused),
      .led    (led),
      .gpio   (gpio),
      .done   (done)
  );

  //
  // Monitor LED changes
  //
  logic led_prev;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      led_prev <= 1'b0;
    end else begin
      led_prev <= led;
    end
  end

  always @(posedge clk) begin
    if (rst_n && led != led_prev) begin
      $display("[%0t] LED changed: %b -> %b", $time, led_prev, led);
    end
  end

  //
  // Debug: Count data memory writes
  //
  int dmem_write_count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dmem_write_count <= 0;
    end else if (sim.bram_cpu.dmem_wen) begin
      dmem_write_count <= dmem_write_count + 1;
    end
  end

  //
  // Additional statistics reporting on completion
  //
  initial begin
    wait (done);
    $display("Final LED state: %b", led);
    $display("Final GPIO state: 0x%02x", gpio);
    $display("Data mem writes seen: %0d", dmem_write_count);
  end

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_blinky_sim.vcd");
  //   $dumpvars(0, rv_blinky_sim);
  // end

endmodule
