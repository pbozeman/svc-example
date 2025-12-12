`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V CoreMark benchmark
//
// Architecture-generic: hex file path set by Makefile via RV_COREMARK_HEX define
//
// Note: CoreMark requires hardware multiply (M extension or Zmmul)
//
// Usage:
//   make sw
//   make rv_coremark_im_sim       # RV32IM variant (recommended)
//   make rv_coremark_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
module rv_coremark_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  // CoreMark runs longer than Dhrystone - increase watchdog
  //
  localparam int WATCHDOG_CYCLES = 500_000_000;  // 500M cycles for benchmark

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
      .PC_REG         (PC_REG),
      .EXT_ZMMUL      (EXT_ZMMUL),
      .EXT_M          (EXT_M),
      // Peripherals
      .BAUD_RATE      (115_200),
      // Debug/reporting
      .PREFIX         ("coremark"),
      .SW_PATH        ("sw/coremark/core_portme.c")
  ) sim ();

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_coremark_sim.vcd");
  //   $dumpvars(0, rv_coremark_sim);
  // end

endmodule
