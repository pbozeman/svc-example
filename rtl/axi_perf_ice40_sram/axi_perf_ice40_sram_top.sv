`include "svc.sv"
`include "svc_init.sv"

`include "axi_perf_ice40_sram.sv"

module axi_perf_ice40_sram_top #(
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 16
) (
    input logic CLK,

    output logic LED1,
    output logic LED2,

    input  logic UART_RX,
    output logic UART_TX,

    output logic [SRAM_ADDR_WIDTH-1:0] L_SRAM_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] L_SRAM_DATA_BUS,
    output logic                       L_SRAM_CS_N,
    output logic                       L_SRAM_OE_N,
    output logic                       L_SRAM_WE_N
);
  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  axi_perf_ice40_sram axi_perf_ice40_sram_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX),

      .sram_io_addr(L_SRAM_ADDR_BUS),
      .sram_io_data(L_SRAM_DATA_BUS),
      .sram_io_ce_n(L_SRAM_CS_N),
      .sram_io_we_n(L_SRAM_WE_N),
      .sram_io_oe_n(L_SRAM_OE_N)
  );

  assign LED1 = 1'b0;
  assign LED2 = 1'b0;

endmodule
