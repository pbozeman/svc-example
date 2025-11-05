`include "svc.sv"

`include "svc_soc_sim.sv"
`include "rv_blinky.sv"

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
  // Clock and reset from simulation infrastructure
  //
  logic clk;
  logic rst_n;

  svc_soc_sim #(
      .CLOCK_FREQ_MHZ(25)
  ) sim_infra (
      .clk  (clk),
      .rst_n(rst_n)
  );

  //
  // Hardware outputs
  //
  logic       led;
  logic [7:0] gpio;
  logic       ebreak;

  //
  // Instantiate the DUT
  //
  rv_blinky dut (
      .clk   (clk),
      .rst_n (rst_n),
      .led   (led),
      .gpio  (gpio),
      .ebreak(ebreak)
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
  // Monitor MMIO writes
  //
  always @(posedge clk) begin
    if (rst_n && dut.io_wen) begin
      $display("[%0t] MMIO Write: addr=0x%08x data=0x%08x", $time,
               dut.io_waddr, dut.io_wdata);
    end
  end

  //
  // Debug: Count data memory writes
  //
  int dmem_write_count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dmem_write_count <= 0;
    end else if (dut.soc.dmem_wen) begin
      dmem_write_count <= dmem_write_count + 1;
    end
  end

  always @(posedge clk) begin
    if (rst_n && dut.soc.dmem_wen && dmem_write_count < 20) begin
      $display("[%0t] Data mem write #%0d: addr=0x%08x data=0x%08x", $time,
               dmem_write_count, dut.soc.dmem_waddr, dut.soc.dmem_wdata);
    end
  end

  //
  // Watchdog counter
  //
  int   watchdog_count;
  logic timeout;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      watchdog_count <= 0;
      timeout        <= 1'b0;
    end else begin
      watchdog_count <= watchdog_count + 1;
      if (watchdog_count >= WATCHDOG_CYCLES) begin
        timeout <= 1'b1;
      end
    end
  end

  //
  // Simulation control
  //
  initial begin
    wait (rst_n);
    #1000;

    $display("");
    $display("=== RISC-V Blinky Simulation ===");
    $display("Running software from sw/blinky/main.c");
    $display("Watching for LED toggles via MMIO writes to 0x80000000");
    $display("Will run for %0d cycles (infinite loop program)",
             WATCHDOG_CYCLES);
    $display("");

    //
    // Wait for timeout or ebreak
    //
    wait (timeout || ebreak);

    $display("");
    if (timeout) begin
      $display("=== Simulation Complete (timeout) ===");
    end else begin
      $display("=== Simulation Complete (ebreak) ===");
    end
    $display("Cycles: %0d", watchdog_count);
    $display("Final LED state: %b", led);
    $display("Final GPIO state: 0x%02x", gpio);
    $display("Data mem writes seen: %0d", dmem_write_count);
    $display("");

    $finish;
  end

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_blinky_sim.vcd");
  //   $dumpvars(0, rv_blinky_sim);
  // end

endmodule
