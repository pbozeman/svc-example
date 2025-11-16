`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V blinky demo
//
// Architecture-generic: hex file path set by Makefile via RV_BLINKY_HEX define
//
// Usage:
//   make sw
//   make rv_blinky_i_sim        # RV32I variant
//   make rv_blinky_im_sim       # RV32IM variant
//   make rv_blinky_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
module rv_blinky_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  localparam int WATCHDOG_CYCLES = 100_000;

  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      // Clock and timing
      .CLOCK_FREQ_MHZ (25),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      // Memory configuration
      .IMEM_DEPTH     (IMEM_DEPTH),
      .DMEM_DEPTH     (DMEM_DEPTH),
      .IMEM_INIT      (MEM_INIT),
      .DMEM_INIT      (MEM_INIT),
      // CPU architecture (from rv_sim_config.svh)
      .MEM_TYPE       (MEM_TYPE),
      .PIPELINED      (PIPELINED),
      .FWD_REGFILE    (FWD_REGFILE),
      .FWD            (FWD),
      .BPRED          (BPRED),
      .BTB_ENABLE     (BTB_ENABLE),
      .EXT_ZMMUL      (EXT_ZMMUL),
      .EXT_M          (EXT_M),
      // Peripherals
      .BAUD_RATE      (115_200),
      // Debug/reporting
      .PREFIX         ("blinky"),
      .SW_PATH        ("sw/blinky/main.c")
  ) sim ();

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_blinky_sim.vcd");
  //   $dumpvars(0, rv_blinky_sim);
  // end

endmodule
