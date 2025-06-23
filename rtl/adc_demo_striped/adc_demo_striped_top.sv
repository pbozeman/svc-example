// TODO: move the mode config into the makefile
`define VGA_MODE_640_480_60

`include "svc.sv"
`include "svc_init.sv"
`include "svc_ice40_pll_25.sv"
`include "svc_ice40_vga_mode.sv"
`include "svc_ice40_vga_pll.sv"

`include "adc_demo_striped.sv"

module adc_demo_striped_top #(
    parameter  NUM_S           = 2,
    localparam COLOR_WIDTH     = 4,
    parameter  SRAM_ADDR_WIDTH = 19,
    parameter  SRAM_DATA_WIDTH = 16,
    parameter  ADC_DATA_WIDTH  = 10
) (
    input  logic CLK,
    output logic LED1,

    // sram L
    output logic                       SRAM_512_A_OE_N,
    output logic                       SRAM_512_A_WE_N,
    output logic                       SRAM_512_A_UB_N,
    output logic                       SRAM_512_A_LB_N,
    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_512_A_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_512_A_DATA_BUS,

    // sram R
    output logic                       SRAM_512_B_OE_N,
    output logic                       SRAM_512_B_WE_N,
    output logic                       SRAM_512_B_UB_N,
    output logic                       SRAM_512_B_LB_N,
    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_512_B_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_512_B_DATA_BUS,

    // ADC inputs
    input  logic [ADC_DATA_WIDTH-1:0] ADC_X,
    input  logic [ADC_DATA_WIDTH-1:0] ADC_Y,
    input  logic                      ADC_RED,
    input  logic                      ADC_GRN,
    input  logic                      ADC_BLU,
    output logic                      ADC_CLK_TO_ADC,

    // output vga to pmod
    output logic [7:0] PMOD_A,
    output logic [5:0] PMOD_B

    // output logic [7:0] R_H,
    // output logic [7:0] R_I
);
  logic                   rst_n;

  logic                   pixel_clk;
  logic                   pixel_rst_n;

  logic                   adc_clk;
  logic                   adc_rst_n;

  logic [COLOR_WIDTH-1:0] vga_red;
  logic [COLOR_WIDTH-1:0] vga_grn;
  logic [COLOR_WIDTH-1:0] vga_blu;
  logic                   vga_hsync;
  logic                   vga_vsync;
  logic                   vga_error;

  // FIXME: this is bad, replace with pll locked signals
  assign pixel_rst_n = rst_n;
  assign adc_rst_n   = rst_n;

  svc_ice40_vga_pll svc_ice40_vga_pll_i (
      .clk_i(CLK),
      .clk_o(pixel_clk)
  );

  svc_ice40_pll_25 svc_ice40_pll_25_i (
      .clk_i(CLK),
      .clk_o(adc_clk)
  );

  svc_init svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  assign ADC_CLK_TO_ADC = adc_clk;

  adc_demo_striped #(
      .NUM_S          (NUM_S),
      .COLOR_WIDTH    (COLOR_WIDTH),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
      .ADC_DATA_WIDTH (ADC_DATA_WIDTH)
  ) adc_demo_striped_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(pixel_rst_n),

      .adc_clk   (adc_clk),
      .adc_rst_n (adc_rst_n),
      .adc_x_io  (ADC_X),
      .adc_y_io  (ADC_Y),
      .adc_red_io(ADC_RED),
      .adc_grn_io(ADC_GRN),
      .adc_blu_io(ADC_BLU),

      .sram_io_addr({SRAM_512_A_ADDR_BUS, SRAM_512_B_ADDR_BUS}),
      .sram_io_data({SRAM_512_A_DATA_BUS, SRAM_512_B_DATA_BUS}),
      .sram_io_ce_n(),
      .sram_io_we_n({SRAM_512_A_WE_N, SRAM_512_B_WE_N}),
      .sram_io_oe_n({SRAM_512_A_OE_N, SRAM_512_B_OE_N}),

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
  // assign PMOD_B[6]      = 1'b0;
  // assign PMOD_B[7]      = 1'b0;

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

  assign LED1            = 1'b0;

  // assign R_I             = error_cnt[15:8];
  // assign R_H             = error_cnt[7:0];

  assign SRAM_512_A_UB_N = 1'b0;
  assign SRAM_512_A_LB_N = 1'b0;
  assign SRAM_512_B_UB_N = 1'b0;
  assign SRAM_512_B_LB_N = 1'b0;

endmodule
