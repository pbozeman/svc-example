`include "svc.sv"
`include "svc_init.sv"

`include "axi_perf_mem/axi_perf_mem.sv"

module top (
    input  wire       CLK100MHZ,
    input  wire       reset,
    output wire [3:0] led,
    input  wire       UART_RX,
    output wire       UART_TX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  localparam AXI_ADDR_WIDTH = 8;
  localparam AXI_DATA_WIDTH = 128;
  localparam AXI_ID_WIDTH = 4;

  wire clk = CLK100MHZ;
  wire rst_n;

  assign led[3] = rst_n;
  assign led[2] = 1'b0;
  assign led[1] = 1'b0;
  assign led[0] = 1'b0;

  assign clk    = CLK100MHZ;

  svc_init svc_init_i (
      .clk  (clk),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  axi_perf_mem #(
      .CLOCK_FREQ    (CLOCK_FREQ),
      .BAUD_RATE     (BAUD_RATE),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) axi_perf_mem (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_pin(UART_RX),
      .utx_pin(UART_TX)
  );

endmodule
