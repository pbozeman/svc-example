`include "svc.sv"
`include "svc_init.sv"

`include "axi_perf_mem.sv"

module axi_perf_mem_top (
    input  logic CLK,
    output logic LED1,
    output logic LED2,
    output logic UART_TX
);
  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  axi_perf_mem axi_perf_mem_i (
      .clk    (CLK),
      .rst_n  (rst_n),
      .utx_pin(UART_TX)
  );

  assign LED1 = 1'b0;
  assign LED2 = 1'b0;

endmodule
