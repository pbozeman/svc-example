`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V Dhrystone benchmark
//
// Usage:
//   make sw
//   make rv_dhrystone_sim
//
module rv_dhrystone_sim;
  //
  // Simulation parameters
  //
  localparam
      int WATCHDOG_CYCLES = 100_000_000;  // 100M cycles for full benchmark


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ(25),
      .IMEM_DEPTH(8192),  // 32KB for larger Dhrystone code
      .DMEM_DEPTH(4096),  // 16KB for Dhrystone globals + heap
      .IMEM_INIT(".build/sw/dhrystone/dhrystone.hex"),
      .DMEM_INIT(".build/sw/dhrystone/dhrystone.hex"),
      .BAUD_RATE(115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX("dhrystone"),
      .SW_PATH("sw/dhrystone/dhry_1.c")
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
  //   $dumpfile("rv_dhrystone_sim.vcd");
  //   $dumpvars(0, rv_dhrystone_sim);
  // end

endmodule
