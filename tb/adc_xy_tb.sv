`include "svc_unit.sv"
`include "adc_xy.sv"

module adc_xy_tb;
  localparam DATA_WIDTH = 10;
  localparam SCALE_NUM_X = 3;
  localparam SCALE_DEN_X = 4;
  localparam SCALE_NUM_Y = 3;
  localparam SCALE_DEN_Y = 4;

  // Clock and reset generation

  // 10ns clock period for main clock (100MHz)
  `TEST_CLK_NS(clk, 10);

  // 20ns clock period for ADC clock (50MHz), phase shifted
  `TEST_CLK_NS(adc_clk, 20, 1);

  // Reset signal generation for main clock
  `TEST_RST_N(clk, rst_n);
  logic                  adc_rst_n;

  // ADC IO signals
  logic                  adc_valid;
  logic                  adc_ready;
  logic [DATA_WIDTH-1:0] adc_x_io;
  logic [DATA_WIDTH-1:0] adc_y_io;
  logic                  adc_red_io;
  logic                  adc_grn_io;
  logic                  adc_blu_io;

  // ADC outputs
  logic [DATA_WIDTH-1:0] adc_x;
  logic [DATA_WIDTH-1:0] adc_y;
  logic                  adc_red;
  logic                  adc_grn;
  logic                  adc_blu;

  // set delay to 0 since we aren't mocking the adc
  adc_xy #(
      .DATA_WIDTH (DATA_WIDTH),
      .SCALE_NUM_X(SCALE_NUM_X),
      .SCALE_DEN_X(SCALE_DEN_X),
      .SCALE_NUM_Y(SCALE_NUM_Y),
      .SCALE_DEN_Y(SCALE_DEN_Y),
      .ADC_DELAY  (0)
  ) uut (
      .clk       (clk),
      .rst_n     (rst_n),
      .adc_clk   (adc_clk),
      .adc_rst_n (adc_rst_n),
      .adc_valid (adc_valid),
      .adc_ready (adc_ready),
      .adc_x_io  (adc_x_io),
      .adc_y_io  (adc_y_io),
      .adc_red_io(adc_red_io),
      .adc_grn_io(adc_grn_io),
      .adc_blu_io(adc_blu_io),
      .adc_x     (adc_x),
      .adc_y     (adc_y),
      .adc_red   (adc_red),
      .adc_grn   (adc_grn),
      .adc_blu   (adc_blu)
  );

  assign adc_rst_n = rst_n;

  // Signal initialization
  always_ff @(posedge clk) begin
    if (~rst_n) begin
      adc_ready <= 1'b0;
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
    `CHECK_FALSE(adc_valid);
  endtask

  task automatic test_basic();
    logic [DATA_WIDTH-1:0] expected_x;
    logic [DATA_WIDTH-1:0] expected_y;

    // Red dot at position (100, 200)
    adc_x_io   = 100;
    adc_y_io   = 200;
    adc_red_io = 1'b1;
    adc_grn_io = 1'b0;
    adc_blu_io = 1'b0;

    // scaled values
    expected_x = ((2 ** DATA_WIDTH - 1) - 100) * SCALE_NUM_X / SCALE_DEN_X;
    expected_y = 200 * SCALE_NUM_Y / SCALE_DEN_Y;

    adc_ready  = 1'b1;
    `CHECK_WAIT_FOR(clk, adc_valid, 30);

    `CHECK_EQ(adc_x, expected_x);
    `CHECK_EQ(adc_y, expected_y);
    `CHECK_EQ(adc_red, 1'b1);
    `CHECK_EQ(adc_grn, 1'b0);
    `CHECK_EQ(adc_blu, 1'b0);

    `TICK(clk);
    adc_ready = 1'b0;
    `CHECK_FALSE(adc_valid);

    // green dot at position (300, 400)
    adc_x_io   = 300;
    adc_y_io   = 400;
    adc_red_io = 1'b0;
    adc_grn_io = 1'b1;
    adc_blu_io = 1'b0;

    adc_ready  = 1'b1;
    `CHECK_WAIT_FOR(clk, adc_valid, 30);
    adc_ready  = 1'b0;

    // Calculate expected values
    expected_x = ((2 ** DATA_WIDTH - 1) - 300) * SCALE_NUM_X / SCALE_DEN_X;
    expected_y = 400 * SCALE_NUM_Y / SCALE_DEN_Y;

    `CHECK_EQ(adc_x, expected_x);
    `CHECK_EQ(adc_y, expected_y);
    `CHECK_EQ(adc_red, 1'b0);
    `CHECK_EQ(adc_grn, 1'b1);
    `CHECK_EQ(adc_blu, 1'b0);
  endtask

  // Test suite definition
  `TEST_SUITE_BEGIN(adc_xy_tb);
  `TEST_CASE(test_reset);
  `TEST_CASE(test_basic);
  `TEST_SUITE_END();
endmodule
