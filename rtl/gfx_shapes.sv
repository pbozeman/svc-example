`ifndef GFX_SHAPES_SV
`define GFX_SHAPES_SV

`include "svc.sv"
`include "svc_gfx_line.sv"

module gfx_shapes #(
    parameter H_WIDTH     = 12,
    parameter V_WIDTH     = 12,
    parameter PIXEL_WIDTH = 12
) (
    input logic clk,
    input logic rst_n,

    // Control interface
    input  logic s_gfx_start,
    output logic s_gfx_done,

    // Graphics output interface (master)
    output logic                   m_gfx_valid,
    output logic [    H_WIDTH-1:0] m_gfx_x,
    output logic [    V_WIDTH-1:0] m_gfx_y,
    output logic [PIXEL_WIDTH-1:0] m_gfx_pixel,
    input  logic                   m_gfx_ready,

    // Screen dimensions
    input logic [H_WIDTH-1:0] h_visible,
    input logic [V_WIDTH-1:0] v_visible
);
  // State machine states
  typedef enum logic [1:0] {
    IDLE,
    DRAWING_LINE,
    DONE
  } state_t;

  state_t                   state;
  state_t                   state_next;

  // Line drawing control signals
  logic                     line_start;
  logic                     line_done;
  logic   [    H_WIDTH-1:0] line_x0;
  logic   [    V_WIDTH-1:0] line_y0;
  logic   [    H_WIDTH-1:0] line_x1;
  logic   [    V_WIDTH-1:0] line_y1;
  logic   [PIXEL_WIDTH-1:0] line_color;

  // Use the svc_gfx_line module for drawing lines
  svc_gfx_line #(
      .H_WIDTH    (H_WIDTH),
      .V_WIDTH    (V_WIDTH),
      .PIXEL_WIDTH(PIXEL_WIDTH)
  ) svc_gfx_line_i (
      .clk        (clk),
      .rst_n      (rst_n),
      .start      (line_start),
      .done       (line_done),
      .x0         (line_x0),
      .y0         (line_y0),
      .x1         (line_x1),
      .y1         (line_y1),
      .color      (line_color),
      .m_gfx_valid(m_gfx_valid),
      .m_gfx_x    (m_gfx_x),
      .m_gfx_y    (m_gfx_y),
      .m_gfx_pixel(m_gfx_pixel),
      .m_gfx_ready(m_gfx_ready)
  );

  // State machine and drawing logic
  always_comb begin
    // Default values
    state_next = state;
    line_start = 1'b0;
    s_gfx_done = 1'b0;

    case (state)
      IDLE: begin
        if (s_gfx_start) begin
          state_next = DRAWING_LINE;
          line_start = 1'b1;
        end
        s_gfx_done = 1'b1;
      end

      DRAWING_LINE: begin
        if (line_done) begin
          state_next = DONE;
        end
      end

      DONE: begin
        state_next = IDLE;
        s_gfx_done = 1'b1;
      end

      default: state_next = IDLE;
    endcase
  end

  // State register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= IDLE;
    end else begin
      state <= state_next;
    end
  end

  // Line parameters - draw a line near the middle of the screen
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      line_x0    <= 0;
      line_y0    <= 0;
      line_x1    <= 0;
      line_y1    <= 0;
      line_color <= 0;
    end else begin
      // Set line coordinates to draw a large diagonal line
      line_x0    <= h_visible / 4;
      line_y0    <= v_visible / 4;
      line_x1    <= (h_visible * 3) / 4;
      line_y1    <= (v_visible * 3) / 4;
      // Set a bright color (assuming RGB format with PIXEL_WIDTH=12)
      line_color <= 12'hF00;  // Bright red
    end
  end

endmodule
`endif
