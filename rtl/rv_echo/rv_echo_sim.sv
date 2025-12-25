`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V UART echo demo
//
// This simulation tests bidirectional UART by receiving characters
// and echoing them back. Use uart_terminal.send_string() to send
// data to the SoC.
//
// Usage:
//   make sw
//   make rv_echo_sim           # RV32I variant
//   make rv_echo_im_sim        # RV32IM variant
//
module rv_echo_sim;
  //
  // Shared configuration from Makefile defines
  //
  `include "rv_sim_config.svh"

  //
  // Program-specific configuration
  //
  // Use a very long watchdog since echo is interactive
  localparam int WATCHDOG_CYCLES = 1_000_000_000;

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
      .PREFIX         ("echo"),
      .SW_PATH        ("sw/echo/main.c")
  ) sim ();

endmodule
