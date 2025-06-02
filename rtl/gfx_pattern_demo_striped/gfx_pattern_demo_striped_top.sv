// TODO: move the mode config into the makefile
`define VGA_MODE_640_480_60

`include "svc.sv"
`include "svc_init.sv"
`include "svc_ice40_vga_mode.sv"
`include "svc_ice40_vga_pll.sv"

`include "gfx_pattern_demo_striped.sv"

module gfx_pattern_demo_striped_top #(
    parameter  NUM_S           = 2,
    localparam COLOR_WIDTH     = 4,
    parameter  SRAM_ADDR_WIDTH = 18,
    parameter  SRAM_DATA_WIDTH = 16
) (
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    output logic                       SRAM_256_A_OE_N,
    output logic                       SRAM_256_A_WE_N,
    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_256_A_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_256_A_DATA_BUS,

    output logic                       SRAM_256_B_OE_N,
    output logic                       SRAM_256_B_WE_N,
    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_256_B_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_256_B_DATA_BUS,

    // output vga to pmod
    output logic [7:0] PMOD_A,
    output logic [7:0] PMOD_B

    // TODO: re-enable the vga error count. These pmods are used by the
    // R sram, so they can't be used for reporting. Either move these,
    // or do the 2 sram optimization.
    //
    // output logic [7:0] R_H,
    // output logic [7:0] R_I
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

  gfx_pattern_demo_striped #(
      .NUM_S          (NUM_S),
      .COLOR_WIDTH    (COLOR_WIDTH),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH)
  ) gfx_pattern_demo_striped_top_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .continious_write(1'b1),

      .sram_io_addr({SRAM_256_B_ADDR_BUS, SRAM_256_A_ADDR_BUS}),
      .sram_io_data({SRAM_256_B_DATA_BUS, SRAM_256_A_DATA_BUS}),
      .sram_io_ce_n(),
      .sram_io_we_n({SRAM_256_B_WE_N, SRAM_256_A_WE_N}),
      .sram_io_oe_n({SRAM_256_B_OE_N, SRAM_256_A_OE_N}),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_error(vga_error)
  );

  // digilent vga pmod pinout
  assign PMOD_A[3:0] = vga_red;
  assign PMOD_B[3:0] = vga_grn;
  assign PMOD_A[7:4] = vga_blu;
  assign PMOD_B[4]   = vga_hsync;
  assign PMOD_B[5]   = vga_vsync;
  assign PMOD_B[6]   = 1'b0;
  assign PMOD_B[7]   = 1'b0;

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

  // assign R_I  = error_cnt[15:8];
  // assign R_H  = error_cnt[7:0];

endmodule
