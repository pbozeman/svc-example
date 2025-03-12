`define VGA_MODE_640_480_60

`include "svc_ice40_vga_mode.sv"
`include "svc_model_sram.sv"
`include "svc_unit.sv"

`include "adc_demo_striped.sv"

// verilator lint_off: UNUSEDSIGNAL
module adc_demo_striped_tb;
  localparam NUM_S = 2;
  localparam COLOR_WIDTH = 4;
  localparam SRAM_ADDR_WIDTH = 20;
  localparam SRAM_DATA_WIDTH = 16;
  localparam ADC_DATA_WIDTH = 10;
  localparam PIXEL_WIDTH = COLOR_WIDTH * 3;

  `TEST_CLK_NS(clk, 10);
  `TEST_CLK_NS(pixel_clk, `VGA_MODE_TB_PIXEL_CLK);
  `TEST_CLK_NS(adc_clk, 40);

  `TEST_RST_N(clk, rst_n);

  logic [   COLOR_WIDTH-1:0]                      vga_red;
  logic [   COLOR_WIDTH-1:0]                      vga_grn;
  logic [   COLOR_WIDTH-1:0]                      vga_blu;
  logic                                           vga_hsync;
  logic                                           vga_vsync;
  logic                                           vga_error;

  logic [         NUM_S-1:0][SRAM_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [         NUM_S-1:0][SRAM_DATA_WIDTH-1:0] sram_io_data;
  logic [         NUM_S-1:0]                      sram_io_we_n;
  logic [         NUM_S-1:0]                      sram_io_oe_n;
  logic [         NUM_S-1:0]                      sram_io_ce_n;

  logic [ADC_DATA_WIDTH-1:0]                      adc_x_io;
  logic [ADC_DATA_WIDTH-1:0]                      adc_y_io;
  logic                                           adc_red_io;
  logic                                           adc_grn_io;
  logic                                           adc_blu_io;

  logic [   PIXEL_WIDTH-1:0]                      pixel;
  assign pixel = {vga_red, vga_grn, vga_blu};

  // ADC input pattern generator
  logic [7:0] adc_pattern_counter;
  always @(posedge adc_clk) begin
    if (!rst_n) begin
      adc_pattern_counter <= 0;
      adc_x_io            <= 0;
      adc_y_io            <= 0;
      adc_red_io          <= 0;
      adc_grn_io          <= 0;
      adc_blu_io          <= 0;
    end else begin
      adc_pattern_counter <= adc_pattern_counter + 1;

      // Simple 0-128 pattern on X and Y
      adc_x_io            <= ADC_DATA_WIDTH'(adc_pattern_counter[6:0]);
      adc_y_io            <= ADC_DATA_WIDTH'(adc_pattern_counter[6:0]);

      // Reset counter after 128
      if (adc_pattern_counter >= 128) begin
        adc_pattern_counter <= 0;
      end

      // Change colors periodically
      adc_red_io <= (adc_pattern_counter < 43);
      adc_grn_io <= (adc_pattern_counter >= 43) && (adc_pattern_counter < 86);
      adc_blu_io <= (adc_pattern_counter >= 86);
    end
  end

  adc_demo_striped #(
      .NUM_S          (NUM_S),
      .COLOR_WIDTH    (COLOR_WIDTH),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
      .ADC_DATA_WIDTH (ADC_DATA_WIDTH)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(rst_n),

      .adc_clk   (adc_clk),
      .adc_rst_n (rst_n),
      .adc_x_io  (adc_x_io),
      .adc_y_io  (adc_y_io),
      .adc_red_io(adc_red_io),
      .adc_grn_io(adc_grn_io),
      .adc_blu_io(adc_blu_io),

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

  for (genvar i = 0; i < NUM_S; i++) begin : gen_sram
    svc_model_sram #(
        .ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .DATA_WIDTH(SRAM_DATA_WIDTH)
    ) svc_model_sram_i (
        .rst_n  (rst_n),
        .we_n   (sram_io_we_n[i]),
        .oe_n   (sram_io_oe_n[i]),
        .ce_n   (sram_io_ce_n[i]),
        .addr   (sram_io_addr[i]),
        .data_io(sram_io_data[i])
    );
  end

  always @(posedge pixel_clk) begin
    if (rst_n) begin
      `CHECK_FALSE(vga_error);
    end
  end

  logic [3:0] gfx_wait_cnt;
  always @(posedge clk) begin
    if (!rst_n) begin
      gfx_wait_cnt <= 0;
    end else begin
      if (uut.adc_xy_gfx_axi_i.svc_gfx_vga_fade_i.s_gfx_valid) begin
        if (uut.adc_xy_gfx_axi_i.svc_gfx_vga_fade_i.s_gfx_ready) begin
          gfx_wait_cnt <= 0;
        end else begin
          gfx_wait_cnt <= gfx_wait_cnt + 1;
        end
      end

      `CHECK_LT(int'(gfx_wait_cnt), 10);
    end
  end

  task automatic test_basic();
    // 2 frames
    repeat (2 * (`VGA_MODE_H_WHOLE_LINE * `VGA_MODE_V_WHOLE_FRAME)) begin
      @(posedge pixel_clk);
    end
  endtask

  `TEST_SUITE_BEGIN_SLOW(adc_demo_striped_tb);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
