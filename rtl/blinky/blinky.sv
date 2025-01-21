`ifndef BLINKY_SV
`define BLINKY_SV

module blinky #(
    parameter CLK_FREQ = 100_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic led
);
  // blink every half second
  localparam CNT_MAX = CLK_FREQ / 2;
  logic [31:0] cnt;

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      cnt <= 0;
      led <= 1'b0;
    end else begin
      if (cnt < CNT_MAX - 1) begin
        cnt <= cnt + 1;
      end else begin
        cnt <= 0;
        led <= ~led;
      end
    end
  end

endmodule
`endif
