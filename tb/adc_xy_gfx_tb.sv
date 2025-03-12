`include "svc_unit.sv"
`include "adc_xy_gfx.sv"

module adc_xy_gfx_tb;
  // Parameters
  localparam ADC_DATA_WIDTH = 10;
  localparam ADC_SCALE_NUM_X = 3;
  localparam ADC_SCALE_DEN_X = 4;
  localparam ADC_SCALE_NUM_Y = 3;
  localparam ADC_SCALE_DEN_Y = 4;
  localparam H_WIDTH = 12;
  localparam V_WIDTH = 12;
  localparam PIXEL_WIDTH = 12;
  localparam COLOR_WIDTH = PIXEL_WIDTH / 3;

  // Clock and reset generation
  // 10ns clock period for main clock (100MHz)
  `TEST_CLK_NS(clk, 10);

  // 20ns clock period for ADC clock (50MHz), phase shifted
  `TEST_CLK_NS(adc_clk, 20, 1);

  // Reset signal generation for main clock
  `TEST_RST_N(clk, rst_n);

  logic                      adc_rst_n;

  // ADC IO signals
  logic [ADC_DATA_WIDTH-1:0] adc_x_io;
  logic [ADC_DATA_WIDTH-1:0] adc_y_io;
  logic                      adc_red_io;
  logic                      adc_grn_io;
  logic                      adc_blu_io;

  // Graphics output signals
  logic                      m_gfx_valid;
  logic [       H_WIDTH-1:0] m_gfx_x;
  logic [       V_WIDTH-1:0] m_gfx_y;
  logic [   PIXEL_WIDTH-1:0] m_gfx_pixel;
  logic                      m_gfx_ready;

  adc_xy_gfx #(
      .ADC_DATA_WIDTH (ADC_DATA_WIDTH),
      .ADC_SCALE_NUM_X(ADC_SCALE_NUM_X),
      .ADC_SCALE_DEN_X(ADC_SCALE_DEN_X),
      .ADC_SCALE_NUM_Y(ADC_SCALE_NUM_Y),
      .ADC_SCALE_DEN_Y(ADC_SCALE_DEN_Y),
      .H_WIDTH        (H_WIDTH),
      .V_WIDTH        (V_WIDTH),
      .PIXEL_WIDTH    (PIXEL_WIDTH),
      .ADC_DELAY      (0)
  ) uut (
      .clk        (clk),
      .rst_n      (rst_n),
      .adc_clk    (adc_clk),
      .adc_rst_n  (adc_rst_n),
      .adc_x_io   (adc_x_io),
      .adc_y_io   (adc_y_io),
      .adc_red_io (adc_red_io),
      .adc_grn_io (adc_grn_io),
      .adc_blu_io (adc_blu_io),
      .m_gfx_valid(m_gfx_valid),
      .m_gfx_x    (m_gfx_x),
      .m_gfx_y    (m_gfx_y),
      .m_gfx_pixel(m_gfx_pixel),
      .m_gfx_ready(m_gfx_ready)
  );

  assign adc_rst_n = rst_n;

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      m_gfx_ready <= 1'b0;
    end
  end

  always_ff @(posedge adc_clk) begin
    if (~adc_rst_n) begin
      adc_x_io   <= '0;
      adc_y_io   <= '0;
      adc_red_io <= 1'b0;
      adc_grn_io <= 1'b0;
      adc_blu_io <= 1'b0;
    end
  end

  task automatic test_reset();
    `CHECK_FALSE(m_gfx_valid);
  endtask

  task automatic test_basic();
    logic [    H_WIDTH-1:0] expected_x;
    logic [    V_WIDTH-1:0] expected_y;
    logic [PIXEL_WIDTH-1:0] expected_pixel;

    m_gfx_ready = 1'b1;

    // Test with red dot at position (100, 200)
    adc_x_io = 100;
    adc_y_io = 200;
    adc_red_io = 1'b1;
    adc_grn_io = 1'b0;
    adc_blu_io = 1'b0;

    expected_x = (((2 ** ADC_DATA_WIDTH - 1) - 100) * ADC_SCALE_NUM_X /
                  ADC_SCALE_DEN_X);
    expected_y = 200 * ADC_SCALE_NUM_Y / ADC_SCALE_DEN_Y;

    expected_pixel = {
      {COLOR_WIDTH{1'b1}}, {COLOR_WIDTH{1'b0}}, {COLOR_WIDTH{1'b0}}
    };

    `CHECK_WAIT_FOR(clk, m_gfx_valid, 30);
    `CHECK_EQ(m_gfx_x, H_WIDTH'(expected_x));
    `CHECK_EQ(m_gfx_y, V_WIDTH'(expected_y));
    `CHECK_EQ(m_gfx_pixel, expected_pixel);

    `TICK(clk);
    m_gfx_ready = 1'b0;
    `TICK(clk);

    // green dot at position (300, 400)
    adc_x_io = 300;
    adc_y_io = 400;
    adc_red_io = 1'b0;
    adc_grn_io = 1'b1;
    adc_blu_io = 1'b0;

    m_gfx_ready = 1'b1;

    expected_x = (((2 ** ADC_DATA_WIDTH - 1) - 300) * ADC_SCALE_NUM_X /
                  ADC_SCALE_DEN_X);
    expected_y = 400 * ADC_SCALE_NUM_Y / ADC_SCALE_DEN_Y;
    expected_pixel = {
      {COLOR_WIDTH{1'b0}}, {COLOR_WIDTH{1'b1}}, {COLOR_WIDTH{1'b0}}
    };

    `CHECK_WAIT_FOR(clk, m_gfx_valid, 30);
    `CHECK_EQ(m_gfx_x, H_WIDTH'(expected_x));
    `CHECK_EQ(m_gfx_y, V_WIDTH'(expected_y));
    `CHECK_EQ(m_gfx_pixel, expected_pixel);
  endtask

  task automatic test_backpressure();
    logic [    H_WIDTH-1:0] initial_x;
    logic [    V_WIDTH-1:0] initial_y;
    logic [PIXEL_WIDTH-1:0] initial_pixel;

    logic [    H_WIDTH-1:0] expected_x;
    logic [    V_WIDTH-1:0] expected_y;
    logic [PIXEL_WIDTH-1:0] expected_pixel;

    adc_x_io    = 500;
    adc_y_io    = 600;
    adc_red_io  = 1'b0;
    adc_grn_io  = 1'b0;
    adc_blu_io  = 1'b1;

    m_gfx_ready = 1'b1;
    `CHECK_WAIT_FOR(clk, m_gfx_valid, 30);

    // Store initial values
    initial_x     = m_gfx_x;
    initial_y     = m_gfx_y;
    initial_pixel = m_gfx_pixel;

    // Apply backpressure (not ready)
    m_gfx_ready   = 1'b0;
    `TICK(clk);

    // Change ADC inputs while backpressure is applied
    adc_x_io   = 700;
    adc_y_io   = 800;
    adc_red_io = 1'b1;
    adc_grn_io = 1'b1;
    adc_blu_io = 1'b1;

    // Verify values don't change with backpressure
    repeat (5) `TICK(clk);
    `CHECK_TRUE(m_gfx_valid);
    `CHECK_EQ(m_gfx_x, initial_x);
    `CHECK_EQ(m_gfx_y, initial_y);
    `CHECK_EQ(m_gfx_pixel, initial_pixel);

    // Release backpressure
    m_gfx_ready = 1'b1;
    `TICK(clk);

    // Now we should get new values
    `CHECK_WAIT_FOR(clk, m_gfx_valid, 30);

    // Calculate expected values for new inputs
    expected_x = (((2 ** ADC_DATA_WIDTH - 1) - 700) * ADC_SCALE_NUM_X /
                  ADC_SCALE_DEN_X);
    expected_y = 800 * ADC_SCALE_NUM_Y / ADC_SCALE_DEN_Y;
    expected_pixel = '1;

    // Verify we get new values after backpressure is released
    `CHECK_EQ(m_gfx_x, H_WIDTH'(expected_x));
    `CHECK_EQ(m_gfx_y, V_WIDTH'(expected_y));
    `CHECK_EQ(m_gfx_pixel, expected_pixel);
  endtask

  // Test suite definition
  `TEST_SUITE_BEGIN(adc_xy_gfx_tb);
  `TEST_CASE(test_reset);
  `TEST_CASE(test_basic);
  `TEST_CASE(test_backpressure);
  `TEST_SUITE_END();
endmodule
