`ifndef ADC_XY_GFX_SV
`define ADC_XY_GFX_SV

`include "svc.sv"
`include "adc_xy.sv"

module adc_xy_gfx #(
    parameter ADC_DATA_WIDTH  = 10,
    parameter ADC_SCALE_NUM_X = 3,
    parameter ADC_SCALE_DEN_X = 4,
    parameter ADC_SCALE_NUM_Y = 3,
    parameter ADC_SCALE_DEN_Y = 4,
    parameter ADC_DELAY       = 7,
    parameter H_WIDTH         = 12,
    parameter V_WIDTH         = 12,
    parameter PIXEL_WIDTH     = 12
) (
    input logic clk,
    input logic rst_n,

    input logic adc_clk,
    input logic adc_rst_n,

    input logic [ADC_DATA_WIDTH-1:0] adc_x_io,
    input logic [ADC_DATA_WIDTH-1:0] adc_y_io,
    input logic                      adc_red_io,
    input logic                      adc_grn_io,
    input logic                      adc_blu_io,

    output logic                   m_gfx_valid,
    output logic [    H_WIDTH-1:0] m_gfx_x,
    output logic [    V_WIDTH-1:0] m_gfx_y,
    output logic [PIXEL_WIDTH-1:0] m_gfx_pixel,
    input  logic                   m_gfx_ready
);
  localparam DW = ADC_DATA_WIDTH;
  localparam HW = H_WIDTH;
  localparam VW = V_WIDTH;
  localparam PW = PIXEL_WIDTH;
  localparam CW = PW / 3;

  logic                   adc_valid;
  logic                   adc_ready;
  logic [         DW-1:0] adc_x;
  logic [         DW-1:0] adc_y;
  logic                   adc_red;
  logic                   adc_grn;
  logic                   adc_blu;

  // Next state signals
  logic                   m_gfx_valid_next;
  logic [    H_WIDTH-1:0] m_gfx_x_next;
  logic [    V_WIDTH-1:0] m_gfx_y_next;
  logic [PIXEL_WIDTH-1:0] m_gfx_pixel_next;

  // Just hold adc ready, because the actual inputs aren't going to
  // wait for us, and if we were to drop inputs, we want the freshest
  // ones, not the old ones.
  assign adc_ready = 1'b1;

  adc_xy #(
      .DATA_WIDTH (ADC_DATA_WIDTH),
      .ADC_DELAY  (ADC_DELAY),
      .SCALE_NUM_X(ADC_SCALE_NUM_X),
      .SCALE_DEN_X(ADC_SCALE_DEN_X),
      .SCALE_NUM_Y(ADC_SCALE_NUM_Y),
      .SCALE_DEN_Y(ADC_SCALE_DEN_Y)
  ) adc_xy_i (
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

  always_comb begin
    m_gfx_valid_next = m_gfx_valid && !m_gfx_ready;
    m_gfx_x_next     = m_gfx_x;
    m_gfx_y_next     = m_gfx_y;
    m_gfx_pixel_next = m_gfx_pixel;

    if (!m_gfx_valid || m_gfx_ready) begin
      m_gfx_valid_next = adc_valid;
      m_gfx_x_next = HW'(adc_x);
      m_gfx_y_next = VW'(adc_y);
      m_gfx_pixel_next = {
        adc_red ? {CW{1'b1}} : {CW{1'b0}},
        adc_grn ? {CW{1'b1}} : {CW{1'b0}},
        adc_blu ? {CW{1'b1}} : {CW{1'b0}}
      };
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_gfx_valid <= 1'b0;
    end else begin
      m_gfx_valid <= m_gfx_valid_next;
    end
  end

  always_ff @(posedge clk) begin
    m_gfx_x     <= m_gfx_x_next;
    m_gfx_y     <= m_gfx_y_next;
    m_gfx_pixel <= m_gfx_pixel_next;
  end

endmodule
`endif
