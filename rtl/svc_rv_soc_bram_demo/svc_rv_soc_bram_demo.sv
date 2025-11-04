`ifndef SVC_RV_SOC_BRAM_DEMO_SV
`define SVC_RV_SOC_BRAM_DEMO_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"

module svc_rv_soc_bram_demo (
    input  logic clk,
    input  logic rst_n,
    output logic ebreak
);

  //
  // Instantiate the RISC-V SoC with program pre-loaded in IMEM
  //
  // Program loaded from program.hex into IMEM
  // Fibonacci(12) - computes 12th Fibonacci number (144) in x11
  // Result is then shifted left by 1 (x30 = 288)
  // This exercises ALU, branches, loops, and register forwarding
  //
  // Program includes performance counter reads (RDCYCLE, RDINSTRET)
  // before and after the main computation for CPI measurement
  //
  // BRAM provides 1-cycle read latency with full pipeline enabled
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_AW    (5),
      .DMEM_AW    (1),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (0),
      .IMEM_INIT  ("rtl/svc_rv_soc_bram_demo/program.hex")
  ) soc (
      .clk   (clk),
      .rst_n (rst_n),
      .ebreak(ebreak)
  );

endmodule

`endif
