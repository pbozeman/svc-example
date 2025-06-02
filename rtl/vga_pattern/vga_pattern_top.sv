// TODO: move the mode config into the makefile
`define VGA_MODE_640_480_60

`include "svc.sv"
`include "svc_init.sv"
`include "svc_ice40_vga_mode.sv"
`include "svc_ice40_vga_pll.sv"

`include "vga_pattern.sv"

module vga_pattern_top #(
    localparam COLOR_WIDTH = 4
) (
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // output vga to pmod e/f
    output logic [7:0] PMOD_A,
    output logic [7:0] PMOD_B
);
  logic                   pixel_clk;
  logic                   rst_n;

  logic [COLOR_WIDTH-1:0] vga_red;
  logic [COLOR_WIDTH-1:0] vga_grn;
  logic [COLOR_WIDTH-1:0] vga_blu;
  logic                   vga_hsync;
  logic                   vga_vsync;

  svc_ice40_vga_pll svc_ice40_vga_pll_i (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  vga_pattern #(
      .COLOR_WIDTH(COLOR_WIDTH)
  ) vga_pattern_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync)
  );

  assign LED1        = 1'b0;
  assign LED2        = 1'b0;

  // digilent vga pmod pinout
  assign PMOD_A[3:0] = vga_red;
  assign PMOD_B[3:0] = vga_grn;
  assign PMOD_A[7:4] = vga_blu;
  assign PMOD_B[4]   = vga_hsync;
  assign PMOD_B[5]   = vga_vsync;
  assign PMOD_B[6]   = 1'b0;
  assign PMOD_B[7]   = 1'b0;

endmodule
