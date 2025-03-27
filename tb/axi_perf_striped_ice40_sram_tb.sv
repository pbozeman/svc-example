`include "svc_unit.sv"
`include "svc_model_sram.sv"

`include "axi_perf_striped_ice40_sram.sv"

// verilator lint_off: UNUSEDSIGNAL
module axi_perf_striped_ice40_sram_tb;
  localparam NUM_S = 2;
  localparam SRAM_ADDR_WIDTH = 20;
  localparam SRAM_DATA_WIDTH = 16;

  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic                                  utx_pin;

  logic [NUM_S-1:0][SRAM_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [NUM_S-1:0][SRAM_DATA_WIDTH-1:0] sram_io_data;
  logic [NUM_S-1:0]                      sram_io_we_n;
  logic [NUM_S-1:0]                      sram_io_oe_n;
  logic [NUM_S-1:0]                      sram_io_ce_n;

  axi_perf_striped_ice40_sram #(
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

  for (genvar i = 0; i < NUM_S; i++) begin : gen_sram
    svc_model_sram #(
        .ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .DATA_WIDTH(SRAM_DATA_WIDTH)
    ) svc_model_sram_i (
        .rst_n  (rst_n),
        .we_n   (sram_io_we_n[i]),
        .oe_n   (sram_io_oe_n[i]),
        .ce_n   (sram_io_ce_n[i]),
        .addr   (sram_io_addr[i]),
        .data_io(sram_io_data[i])
    );
  end

  task automatic test_basic();
    // This is only a very basic smoke test to make sure it compiles
    // and we can look at wave forms
    #100000;
  endtask

  `TEST_SUITE_BEGIN(axi_perf_striped_ice40_sram_tb, 100000);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
