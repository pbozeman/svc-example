`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V hello world demo
//
// Architecture-generic: hex file path set by Makefile via RV_HELLO_HEX define
//
// Usage:
//   make sw
//   make rv_hello_i_sim        # RV32I variant
//   make rv_hello_im_sim       # RV32IM variant
//   make rv_hello_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
module rv_hello_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  localparam int WATCHDOG_CYCLES = 1_000_000;

  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      // Clock and timing
      .CLOCK_FREQ     (1_000_000),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      // Memory configuration
      .IMEM_DEPTH     (IMEM_DEPTH),
      .DMEM_DEPTH     (DMEM_DEPTH),
      .IMEM_INIT      (MEM_INIT),
      .DMEM_INIT      (MEM_INIT),
      .DMEM_INIT_128  (MEM_INIT),
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
      .PREFIX         ("hello"),
      .SW_PATH        ("sw/hello/main.c")
  ) sim ();

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_hello_sim.vcd");
  //   $dumpvars(0, rv_hello_sim);
  // end

endmodule
