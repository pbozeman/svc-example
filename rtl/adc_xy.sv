`ifndef ADC_XY_SV
`define ADC_XY_SV

`include "svc.sv"
`include "svc_cdc_fifo.sv"
`include "svc_delay.sv"

// TODO: The scaling params are based on resolution. Make them dynamic.
//
// TODO: Make mirroring and rotation parameters dynamic since they
// change based on the source signal.

module adc_xy #(
    parameter DATA_WIDTH  = 10,
    parameter SCALE_NUM_X = 3,
    parameter SCALE_DEN_X = 4,
    parameter SCALE_NUM_Y = 3,
    parameter SCALE_DEN_Y = 4,
    parameter ADC_DELAY   = 7
) (
    input logic clk,
    input logic rst_n,

    input logic adc_clk,
    input logic adc_rst_n,

    output logic adc_valid,
    input  logic adc_ready,

    input logic [DATA_WIDTH-1:0] adc_x_io,
    input logic [DATA_WIDTH-1:0] adc_y_io,
    input logic                  adc_red_io,
    input logic                  adc_grn_io,
    input logic                  adc_blu_io,

    output logic [DATA_WIDTH-1:0] adc_x,
    output logic [DATA_WIDTH-1:0] adc_y,
    output logic                  adc_red,
    output logic                  adc_grn,
    output logic                  adc_blu
);
  // We have to delay by the ADC amount, plus 2 pipeline cycles for the
  // scaling math.
  //
  // Data sheet for the adc says 7 cycle delay for x/y, which is the default
  // above.
  //
  // TODO: there is a little blue line under the player name in game,
  // so despite the data sheet, this seems wrong, like the gun turned on/off
  // early or late. Measure and tune this.
  parameter COLOR_DELAY = (ADC_DELAY + 2);

  // X/Y + color
  localparam FIFO_WIDTH = DATA_WIDTH * 2 + 3;

  // mirror and rotate parms
  localparam MAX_ADC = {DATA_WIDTH{1'b1}};
  localparam SCALE_BITS = (DATA_WIDTH + $clog2(
      (SCALE_NUM_X > SCALE_NUM_Y) ? SCALE_NUM_X : SCALE_NUM_Y
  ));

  logic                  w_data_changed;

  logic                  fifo_w_inc;
  logic [FIFO_WIDTH-1:0] fifo_w_data;
  logic [FIFO_WIDTH-1:0] fifo_w_data_prev;

  logic                  fifo_r_empty;

  // pipeline scaling in the caller's coordinates
  logic [SCALE_BITS-1:0] adc_x_io_scaled_p1;
  logic [SCALE_BITS-1:0] adc_y_io_scaled_p1;

  // Not all bits are used in final assignment
  // verilator lint_off: UNUSEDSIGNAL
  // TODO: scope the unused bits in svc_unused
  logic [SCALE_BITS-1:0] adc_x_io_scaled_p2;
  logic [SCALE_BITS-1:0] adc_y_io_scaled_p2;
  // verilator lint_on: UNUSEDSIGNAL

  // delay the color to match the adc x/y
  //
  // Right now, color is available immediately, so the color needs to be
  // delayed for the full duration of the x/y adc. Adjust this if/when a color
  // adc is added.
  logic                  adc_red_io_d;
  logic                  adc_grn_io_d;
  logic                  adc_blu_io_d;

  logic                  w_pixel_lit;

  svc_delay #(
      .CYCLES(COLOR_DELAY),
      .WIDTH (3)
  ) adc_color_delay (
      .clk  (adc_clk),
      .rst_n(adc_rst_n),
      .in   ({adc_red_io, adc_grn_io, adc_blu_io}),
      .out  ({adc_red_io_d, adc_grn_io_d, adc_blu_io_d})
  );

  //
  // Scaling, pipelined
  //
  always_ff @(posedge adc_clk) begin
    adc_x_io_scaled_p1 <=
        ((SCALE_BITS'(MAX_ADC) - SCALE_BITS'(adc_x_io)) * SCALE_NUM_X);
    adc_y_io_scaled_p1 <= SCALE_BITS'(adc_y_io) * SCALE_NUM_Y;
  end

  always_ff @(posedge adc_clk) begin
    adc_x_io_scaled_p2 <= adc_x_io_scaled_p1 / SCALE_DEN_X;
    adc_y_io_scaled_p2 <= adc_y_io_scaled_p1 / SCALE_DEN_Y;
  end

  assign fifo_w_data = {
    adc_x_io_scaled_p2[DATA_WIDTH-1:0],
    adc_y_io_scaled_p2[DATA_WIDTH-1:0],
    adc_red_io_d,
    adc_grn_io_d,
    adc_blu_io_d
  };

  // only send pixels that re lit, and no duplicates
  assign w_pixel_lit = (adc_red_io_d || adc_grn_io_d || adc_blu_io_d);
  assign w_data_changed = fifo_w_data != fifo_w_data_prev;
  assign fifo_w_inc = w_pixel_lit && w_data_changed;

  always_ff @(posedge adc_clk) begin
    fifo_w_data_prev <= fifo_w_data;
  end

  svc_cdc_fifo #(
      .DATA_WIDTH(FIFO_WIDTH),
      .ADDR_WIDTH(4)
  ) fifo (
      .w_clk  (adc_clk),
      .w_rst_n(adc_rst_n),
      .w_inc  (fifo_w_inc),
      .w_data (fifo_w_data),
      .w_full (),

      .r_clk  (clk),
      .r_rst_n(rst_n),
      .r_inc  (adc_valid && adc_ready),
      .r_empty(fifo_r_empty),
      .r_data ({adc_x, adc_y, adc_red, adc_grn, adc_blu})
  );

  assign adc_valid = !fifo_r_empty;

endmodule

`endif
