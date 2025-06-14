`include "svc.sv"
`include "svc_init.sv"
`include "svc_ice40_pll_75.sv"

`include "axi_perf_ice40_sram.sv"

module axi_perf_ice40_sram_top #(
    parameter SRAM_ADDR_WIDTH = 18,
    parameter SRAM_DATA_WIDTH = 16
) (
    input logic CLK,

    output logic LED1,

    input  logic UART_RX,
    output logic UART_TX,

    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_256_A_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_256_A_DATA_BUS,
    output logic                       SRAM_256_A_OE_N,
    output logic                       SRAM_256_A_WE_N,
    output logic                       SRAM_256_A_UB_N,
    output logic                       SRAM_256_A_LB_N
);
  localparam CLOCK_FREQ = 75_000_000;
  localparam BAUD_RATE = 115_200;
  localparam STAT_WIDTH = 16;

  logic clk;
  logic rst_n;

  svc_ice40_pll_75 svc_ice40_pll_75_i (
      .clk_i(CLK),
      .clk_o(clk)
  );

  svc_init svc_init_i (
      .clk  (clk),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  axi_perf_ice40_sram #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .STAT_WIDTH(STAT_WIDTH)
  ) axi_perf_ice40_sram_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX),

      .sram_io_addr(SRAM_256_A_ADDR_BUS),
      .sram_io_data(SRAM_256_A_DATA_BUS),
      .sram_io_ce_n(),
      .sram_io_we_n(SRAM_256_A_WE_N),
      .sram_io_oe_n(SRAM_256_A_OE_N)
  );

  assign LED1            = 1'b0;
  assign SRAM_256_A_UB_N = 1'b0;
  assign SRAM_256_A_LB_N = 1'b0;

endmodule
