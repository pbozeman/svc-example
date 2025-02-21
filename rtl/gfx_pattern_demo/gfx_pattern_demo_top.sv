// TODO: move the mode config into the makefile
`define VGA_MODE_640_480_60

`include "svc.sv"
`include "svc_init.sv"
`include "svc_ice40_vga_mode.sv"
`include "svc_ice40_vga_pll.sv"

`include "gfx_pattern_demo.sv"

module gfx_pattern_demo_top #(
    localparam COLOR_WIDTH      = 4,
    parameter  SRAM_ADDR_WIDTH  = 20,
    parameter  SRAM_DATA_WIDTH  = 16,
    parameter  SRAM_RDATA_WIDTH = 12
) (
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // sram
    output logic [ SRAM_ADDR_WIDTH-1:0] L_SRAM_ADDR_BUS,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] L_SRAM_DATA_BUS,
    output logic                        L_SRAM_CS_N,
    output logic                        L_SRAM_OE_N,
    output logic                        L_SRAM_WE_N,

    // output vga to pmod e/f
    output logic [7:0] R_E,
    output logic [7:0] R_F,

    output logic [7:0] R_H,
    output logic [7:0] R_I
);
  logic                   pixel_clk;
  logic                   rst_n;

  logic [COLOR_WIDTH-1:0] vga_red;
  logic [COLOR_WIDTH-1:0] vga_grn;
  logic [COLOR_WIDTH-1:0] vga_blu;
  logic                   vga_hsync;
  logic                   vga_vsync;
  logic                   vga_error;

  svc_ice40_vga_pll svc_ice40_vga_pll_i (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  gfx_pattern_demo #(
      .COLOR_WIDTH     (COLOR_WIDTH),
      .SRAM_ADDR_WIDTH (SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH (SRAM_DATA_WIDTH),
      .SRAM_RDATA_WIDTH(SRAM_RDATA_WIDTH)
  ) gfx_pattern_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .continious_write(1'b1),

      .sram_io_addr(L_SRAM_ADDR_BUS),
      .sram_io_data(L_SRAM_DATA_BUS),
      .sram_io_ce_n(L_SRAM_CS_N),
      .sram_io_we_n(L_SRAM_WE_N),
      .sram_io_oe_n(L_SRAM_OE_N),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_error(vga_error)
  );

  // digilent vga pmod pinout
  assign R_E[3:0] = vga_red;
  assign R_F[3:0] = vga_grn;
  assign R_E[7:4] = vga_blu;
  assign R_F[4]   = vga_hsync;
  assign R_F[5]   = vga_vsync;
  assign R_F[6]   = 1'b0;
  assign R_F[7]   = 1'b0;

  logic [15:0] error_cnt;
  always_ff @(posedge pixel_clk) begin
    if (!rst_n) begin
      error_cnt <= 0;
    end else begin
      if (vga_error) begin
        error_cnt <= error_cnt + 1;
      end
    end
  end

  assign LED1 = 1'b0;
  assign LED2 = 1'b0;

  assign R_I  = error_cnt[15:8];
  assign R_H  = error_cnt[7:0];

endmodule
