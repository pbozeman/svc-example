`include "svc.sv"
`include "svc_init.sv"

`include "svc_rv_soc_bram_cache_fwd_demo.sv"

module svc_rv_soc_bram_cache_fwd_demo_top (
    input  logic CLK,
    output logic LED1
);
  logic rst_n;
  logic ebreak;
  logic ebreak_reg;

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  svc_rv_soc_bram_cache_fwd_demo svc_rv_soc_bram_cache_fwd_demo_i (
      .clk   (CLK),
      .rst_n (rst_n),
      .ebreak(ebreak)
  );

  //
  // register ebreak to show program completed
  //
  always_ff @(posedge CLK) begin
    if (!rst_n) begin
      ebreak_reg <= 1'b0;
    end else if (ebreak) begin
      ebreak_reg <= 1'b1;
    end
  end

  //
  // LED turns on when program completes (EBREAK)
  //
  assign LED1 = ebreak_reg;

endmodule
