`ifndef GFX_PATTERN_SV
`define GFX_PATTERN_SV

`include "svc.sv"
`include "svc_rgb.sv"

//
// Color Bar GFX
//
// https://en.wikipedia.org/wiki/SMPTE_color_bars

// verilator lint_off: UNUSEDSIGNAL

module gfx_pattern #(
    parameter H_WIDTH     = 12,
    parameter V_WIDTH     = 12,
    parameter PIXEL_WIDTH = 12
) (
    input logic clk,
    input logic rst_n,

    input  logic s_gfx_start,
    output logic s_gfx_done,

    output logic                   m_gfx_valid,
    output logic [    H_WIDTH-1:0] m_gfx_x,
    output logic [    V_WIDTH-1:0] m_gfx_y,
    output logic [PIXEL_WIDTH-1:0] m_gfx_pixel,
    input  logic                   m_gfx_ready,

    input logic [HW-1:0] h_visible,
    input logic [HW-1:0] v_visible
);
  localparam HW = H_WIDTH;
  localparam VW = V_WIDTH;
  localparam PW = PIXEL_WIDTH;
  localparam CW = PW / 3;

  // 75% off/on
  // Use colors as defined on the page above, converting from the 10-bit RGBs.
  localparam [CW-1:0] C_OFF = `SVC_RGB_M_TO_N(64, 10, CW);
  localparam [CW-1:0] C_ON = `SVC_RGB_M_TO_N(721, 10, CW);

  localparam [PW-1:0] WHITE = {C_ON, C_ON, C_ON};
  localparam [PW-1:0] YELLOW = {C_ON, C_ON, C_OFF};
  localparam [PW-1:0] RED = {C_ON, C_OFF, C_OFF};
  localparam [PW-1:0] GREEN = {C_OFF, C_ON, C_OFF};
  localparam [PW-1:0] BLUE = {C_OFF, C_OFF, C_ON};
  localparam [PW-1:0] CYAN = {C_OFF, C_ON, C_ON};
  localparam [PW-1:0] MAGENTA = {C_ON, C_OFF, C_ON};
  localparam [PW-1:0] BLACK = {C_OFF, C_OFF, C_OFF};

  logic                  running;
  logic                  running_next;

  logic                  done;
  logic                  done_next;

  logic                  m_gfx_valid_next;

  logic [HW-1:0]         x;
  logic [HW-1:0]         x_next;

  logic [VW-1:0]         y;
  logic [VW-1:0]         y_next;

  // the width of each column
  logic [HW-1:0]         col_width;

  // which column are we on
  logic [   3:0]         col;
  logic [   3:0]         col_next;

  // the edge of the next column
  logic [HW-1:0]         col_edge;
  logic [HW-1:0]         col_edge_next;

  logic [   7:0][PW-1:0] col_colors;

  assign col_colors = {BLACK, BLUE, RED, MAGENTA, GREEN, CYAN, YELLOW, WHITE};

  // we have 8 columns, so divide by 8 for width
  assign col_width  = h_visible >> 3;

  // The running/done flags might be better represented by a state machine.
  // Together they form an informal state machine. Note: it will still be
  // 2 bits, as together they represent IDLE, RUNNING, and DONE
  always_comb begin
    m_gfx_valid_next = m_gfx_valid && !m_gfx_ready;

    x_next           = x;
    y_next           = y;

    col_next         = col;
    col_edge_next    = col_edge;

    running_next     = running;
    done_next        = done;

    if (s_gfx_start) begin
      running_next = 1'b1;
      done_next    = 1'b0;
    end

    if (running) begin
      if (m_gfx_valid && m_gfx_ready) begin
        if (x < h_visible - 1) begin
          x_next = x + 1;

          if (x == col_edge - 1) begin
            col_next      = col + 1;
            col_edge_next = col_edge + col_width;
          end
        end else begin
          x_next        = 0;
          col_next      = 0;
          col_edge_next = col_width;

          if (y < v_visible - 1) begin
            y_next = y + 1;
          end else begin
            running_next = 1'b0;
            done_next    = 1'b1;
            y_next       = 0;
          end
        end
      end
    end

    if (!m_gfx_valid || m_gfx_ready) begin
      m_gfx_valid_next = running_next;
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_gfx_valid <= 1'b0;
      x           <= 0;
      y           <= 0;
      col         <= 0;
      col_edge    <= col_width;
      running     <= 1'b0;
      done        <= 1'b0;
    end else begin
      m_gfx_valid <= m_gfx_valid_next;
      x           <= x_next;
      y           <= y_next;
      col         <= col_next;
      col_edge    <= col_edge_next;
      running     <= running_next;
      done        <= done_next;
    end
  end

  assign m_gfx_x     = x;
  assign m_gfx_y     = y;
  assign m_gfx_pixel = col_colors[col];

  assign s_gfx_done  = done;

endmodule
`endif
