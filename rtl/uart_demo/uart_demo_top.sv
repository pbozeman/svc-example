`include "svc.sv"
`include "svc_init.sv"

`include "uart_demo.sv"

module uart_demo_top (
    input  logic CLK,
    output logic LED1,
    output logic LED2,
    input  logic UART_RX,
    output logic UART_TX
);
  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  uart_demo uart_demo_i (
      .clk    (CLK),
      .rst_n  (rst_n),
      .urx_pin(UART_RX),
      .utx_pin(UART_TX)
  );

  assign LED1 = 1'b0;
  assign LED2 = 1'b0;

endmodule
