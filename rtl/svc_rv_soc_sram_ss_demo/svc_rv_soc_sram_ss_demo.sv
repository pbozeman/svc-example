`ifndef SVC_RV_SOC_SRAM_SS_DEMO_SV
`define SVC_RV_SOC_SRAM_SS_DEMO_SV

`include "svc.sv"
`include "svc_rv_soc_sram.sv"

module svc_rv_soc_sram_ss_demo (
    input  logic clk,
    input  logic rst_n,
    output logic ebreak
);

  //
  // Instantiate the RISC-V SoC with program pre-loaded in IMEM
  //
  // Program loaded from program.hex into IMEM
  // Fibonacci(100) - computes 100th Fibonacci number (truncated to 32-bit) in x11
  // Result is then shifted left by 1 in x30
  // This exercises ALU, branches, loops, and register forwarding
  //
  // Program includes performance counter reads (RDCYCLE, RDINSTRET)
  // before and after the main computation for CPI measurement
  //
  // This program only uses registers, so it doesn't need any DMEM,
  // and only uses 18 instructions (72 bytes), so IMEM_AW 5 (128 bytes)
  // is sufficient. These overrides can be removed when bram is used.
  //
  // Single-stage (non-pipelined) configuration for SRAM
  //
  svc_rv_soc_sram #(
      .XLEN       (32),
      .IMEM_DEPTH (32),
      .DMEM_DEPTH (2),
      .PIPELINED  (0),
      .FWD_REGFILE(0),
      .FWD        (0),
      .BPRED      (0),
      .IMEM_INIT  ("rtl/svc_rv_soc_sram_ss_demo/program.hex")
  ) soc (
      .clk     (clk),
      .rst_n   (rst_n),
      .ebreak  (ebreak),
      .trap    (),
      .io_raddr(),
      .io_rdata(),
      .io_wen  (),
      .io_waddr(),
      .io_wdata(),
      .io_wstrb()
  );

endmodule

`endif
