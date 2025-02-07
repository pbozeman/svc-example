`define VGA_MODE_640_480_60

`include "svc_ice40_vga_mode.sv"
`include "svc_model_sram.sv"
`include "svc_unit.sv"

`include "gfx_pattern_demo.sv"

// verilator lint_off: UNUSEDSIGNAL
module gfx_pattern_demo_tb;
  localparam COLOR_WIDTH = 4;
  localparam SRAM_ADDR_WIDTH = 20;
  localparam SRAM_DATA_WIDTH = 16;

  localparam PIXEL_WIDTH = COLOR_WIDTH * 3;

  `TEST_CLK_NS(clk, 10);
  `TEST_CLK_NS(pixel_clk, `VGA_MODE_TB_PIXEL_CLK);

  `TEST_RST_N(clk, rst_n);

  logic [    COLOR_WIDTH-1:0] vga_red;
  logic [    COLOR_WIDTH-1:0] vga_grn;
  logic [    COLOR_WIDTH-1:0] vga_blu;
  logic                       vga_hsync;
  logic                       vga_vsync;
  logic                       vga_error;

  logic [SRAM_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [SRAM_DATA_WIDTH-1:0] sram_io_data;
  logic                       sram_io_we_n;
  logic                       sram_io_oe_n;
  logic                       sram_io_ce_n;

  logic [    PIXEL_WIDTH-1:0] pixel;
  assign pixel = {vga_red, vga_grn, vga_blu};

  gfx_pattern_demo #(
      .COLOR_WIDTH    (COLOR_WIDTH),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_error(vga_error),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  svc_model_sram #(
      .ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .DATA_WIDTH(SRAM_DATA_WIDTH)
  ) svc_model_sram_i (
      .rst_n  (rst_n),
      .we_n   (sram_io_we_n),
      .oe_n   (sram_io_oe_n),
      .ce_n   (sram_io_ce_n),
      .addr   (sram_io_addr),
      .data_io(sram_io_data)
  );

  task automatic test_basic();
    // 2 frames
    repeat (2 * (`VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME)) begin
      @(posedge pixel_clk);
    end
  endtask

  `TEST_SUITE_BEGIN(gfx_pattern_demo_tb, 20000000, 6);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
