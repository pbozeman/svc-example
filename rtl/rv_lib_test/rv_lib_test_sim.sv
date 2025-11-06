`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V libsvc test suite
//
// Usage:
//   make sw
//   make rv_lib_test_sim
//
module rv_lib_test_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 2_000_000;  // Increased for malloc tests


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ(25),
      .IMEM_DEPTH(4096),
      .DMEM_DEPTH(2048),  // 8KB for heap support
      .IMEM_INIT(".build/sw/lib_test/lib_test.hex"),
      .DMEM_INIT(".build/sw/lib_test/lib_test.hex"),
      .BAUD_RATE(115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX("lib_test"),
      .SW_PATH("sw/lib_test/main.c")
  ) sim (
      .clk    (),
      .rst_n  (),
      .uart_tx(),
      .led    (),
      .gpio   (),
      .done   ()
  );

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_lib_test_sim.vcd");
  //   $dumpvars(0, rv_lib_test_sim);
  // end

endmodule
