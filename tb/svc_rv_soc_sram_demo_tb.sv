`include "svc_unit.sv"

`include "svc_rv_soc_sram_demo.sv"

module svc_rv_soc_sram_demo_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic ebreak;

  svc_rv_soc_sram_demo uut (
      .clk   (clk),
      .rst_n (rst_n),
      .ebreak(ebreak)
  );

  // Program is automatically loaded via IMEM_INIT parameter

  logic [31:0] cpi_cycles;
  logic [31:0] cpi_instrs;
  logic [31:0] cpi_value;
  bit          cpi_report_en;

  final begin
    if (cpi_report_en) begin
      $display("CPI Report:");
      $display("  Cycles:       %0d", cpi_cycles);
      $display("  Instructions: %0d", cpi_instrs);
      $display("  CPI:          %0d", cpi_value);
    end
  end

  task automatic test_hardcoded_program;
    logic [31:0] cycles;
    logic [31:0] instrs;
    logic [31:0] cpi;
    bit          svc_tb_rpt;

    `CHECK_WAIT_FOR(clk, ebreak, 1024);

    // Correctness check
    `CHECK_EQ(uut.soc.cpu.stage_id.regfile.regs[11], 32'hC594BFC3);
    `CHECK_EQ(uut.soc.cpu.stage_id.regfile.regs[30], 32'h8B297F86);
    `CHECK_EQ(uut.soc.cpu.stage_id.regfile.regs[0], 32'd0);

    // CPI check
    cycles = uut.soc.cpu.stage_id.regfile.regs[24];
    instrs = uut.soc.cpu.stage_id.regfile.regs[25];
    cpi    = cycles / instrs;


    // crude since this is int based, replace with real based calcs
    // TODO: re-enable
    // `CHECK_EQ(cpi, 2);

    if ($value$plusargs("SVC_TB_RPT=%b", svc_tb_rpt) && svc_tb_rpt) begin
      cpi_cycles    = cycles;
      cpi_instrs    = instrs;
      cpi_value     = cpi;
      cpi_report_en = 1;
    end
  endtask

  `TEST_SUITE_BEGIN(svc_rv_soc_sram_demo_tb);
  `TEST_CASE(test_hardcoded_program);
  `TEST_SUITE_END();

endmodule
