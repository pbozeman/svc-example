`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V Dhrystone benchmark
//
// Architecture-generic: hex file path set by Makefile via RV_DHRYSTONE_HEX define
//
// Usage:
//   make sw
//   make rv_dhrystone_i_sim        # RV32I variant
//   make rv_dhrystone_im_sim       # RV32IM variant
//   make rv_dhrystone_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
module rv_dhrystone_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  localparam
      int WATCHDOG_CYCLES = 100_000_000;  // 100M cycles for full benchmark

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
      .RAS_ENABLE     (RAS_ENABLE),
      .RAS_DEPTH      (RAS_DEPTH),
      .EXT_ZMMUL      (EXT_ZMMUL),
      .EXT_M          (EXT_M),
      // Peripherals
      .BAUD_RATE      (115_200),
      // Debug/reporting
      .PREFIX         ("dhrystone"),
      .SW_PATH        ("sw/dhrystone/dhry_1.c")
  ) sim ();

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_dhrystone_sim.vcd");
  //   $dumpvars(0, rv_dhrystone_sim);
  // end

endmodule
