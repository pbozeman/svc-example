`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Debug loader simulation
//
// Instantiates the SoC with DEBUG_ENABLED=1. The CPU starts stalled
// and in reset, waiting for commands via the debug UART.
//
// Architecture-generic: supports all variants like other rv_* sims
//
// Usage:
//   make rv_loader_sim           # RV32I variant (default)
//   make rv_loader_i_sim         # RV32I variant (explicit)
//   make rv_loader_im_sim        # RV32IM variant
//   make rv_loader_i_zmmul_sim   # RV32I_Zmmul variant
//
// Then in another terminal:
//   python3 ./scripts/rv_loader.py -p /dev/pts/N --run program.elf
//
module rv_loader_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  localparam int WATCHDOG_CYCLES = 500_000_000;

  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      // Clock and timing
      .CLOCK_FREQ     (25_000_000),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      // Memory configuration (no init - loaded via debug bridge)
      .IMEM_DEPTH     (IMEM_DEPTH),
      .DMEM_DEPTH     (DMEM_DEPTH),
      .IMEM_INIT      (""),
      .DMEM_INIT      (""),
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
      .PREFIX         ("loader"),
      .SW_PATH        (""),
      // Enable debug bridge (CPU starts stalled)
      .DEBUG_ENABLED  (1)
  ) sim ();

endmodule
