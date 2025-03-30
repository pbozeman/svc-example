`include "svc_unit.sv"
`include "svc_model_sram.sv"

`include "axi_perf_ice40_sram.sv"

// verilator lint_off: UNUSEDSIGNAL
module axi_perf_ice40_sram_tb;
  localparam SRAM_ADDR_WIDTH = 20;
  localparam SRAM_DATA_WIDTH = 16;

  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic                       utx_pin;

  logic [SRAM_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [SRAM_DATA_WIDTH-1:0] sram_io_data;
  logic                       sram_io_we_n;
  logic                       sram_io_oe_n;
  logic                       sram_io_ce_n;

  axi_perf_ice40_sram #(
      .CLOCK_FREQ     (100),
      .BAUD_RATE      (10),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
  ) uut (
      .clk    (clk),
      .rst_n  (rst_n),
      .utx_pin(utx_pin),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  svc_model_sram #(
      .ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .DATA_WIDTH(SRAM_DATA_WIDTH)
  ) svc_model_sram_i (
      .rst_n  (rst_n),
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  task automatic test_basic();
    // This is only a very basic smoke test to make sure it compiles
    // and we can look at wave forms
    #200000;
  endtask

  `TEST_SUITE_BEGIN(axi_perf_ice40_sram_tb, 200000);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
