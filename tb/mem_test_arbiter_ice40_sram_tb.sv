`include "svc.sv"
`include "svc_model_sram.sv"
`include "svc_unit.sv"

`include "mem_test_arbiter_ice40_sram.sv"

module mem_test_arbiter_ice40_sram_tb;
  localparam AW = 8;
  localparam DW = 16;

  logic [AW-1:0] sram_io_addr;
  wire  [DW-1:0] sram_io_data;
  logic          sram_io_we_n;
  logic          sram_io_oe_n;
  logic          sram_io_ce_n;

  logic          done;
  logic          pass;

  logic [   7:0] done_cnt;

  `TEST_CLK_NS(clk, 20);
  `TEST_RST_N(clk, rst_n);

  mem_test_arbiter_ice40_sram #(
      .SRAM_ADDR_WIDTH(AW),
      .SRAM_DATA_WIDTH(DW)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),

      .test_done(done),
      .test_pass(pass),
      .debug0   (),
      .debug1   (),
      .debug2   (),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  svc_model_sram #(
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW)
  ) svc_model_sram_i (
      .rst_n  (rst_n),
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      done_cnt <= 0;
    end else begin
      if (done) begin
        done_cnt <= done_cnt + 1;
      end
    end
  end

  task automatic test_pass();
    `CHECK_FALSE(done);
    `CHECK_TRUE(pass);

    wait (done_cnt == 3 || !pass);
    `CHECK_TRUE(pass);
    `CHECK_EQ(done_cnt, 3);
  endtask

  `TEST_SUITE_BEGIN(mem_test_arbiter_ice40_sram_tb);
  `TEST_CASE(test_pass);
  `TEST_SUITE_END();
endmodule
