`define VGA_MODE_640_480_60

`include "svc_unit.sv"
`include "svc_ice40_vga_mode.sv"

`include "vga_pattern.sv"

// verilator lint_off: UNUSEDSIGNAL
module vga_pattern_tb;
  localparam COLOR_WIDTH = 4;

  `TEST_CLK_NS(clk, 10);
  `TEST_CLK_NS(pixel_clk, `VGA_MODE_TB_PIXEL_CLK);

  `TEST_RST_N(clk, rst_n);

  logic [COLOR_WIDTH-1:0] vga_red;
  logic [COLOR_WIDTH-1:0] vga_grn;
  logic [COLOR_WIDTH-1:0] vga_blu;
  logic                   vga_hsync;
  logic                   vga_vsync;

  vga_pattern #(
      .COLOR_WIDTH(COLOR_WIDTH)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync)
  );

  task automatic test_basic();
    // 2 frames
    repeat (2 * (`VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME)) begin
      `TICK(pixel_clk);
    end
  endtask

  `TEST_SUITE_BEGIN_SLOW(vga_pattern_tb);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
