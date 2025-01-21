`include "svc.sv"
`include "svc_init.sv"

`include "blinky.sv"

module blinky_top (
    input  logic CLK,
    output logic LED1,
    output logic LED2
);
  logic rst_n;

  svc_init svc_init_i (
      .clk  (CLK),
      .rst_n(rst_n)
  );

  blinky blinky_i (
      .clk  (CLK),
      .rst_n(rst_n),
      .led  (LED1)
  );

  assign LED2 = 1'b0;

endmodule
