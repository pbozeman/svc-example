`ifndef GFX_SHAPES_SV
`define GFX_SHAPES_SV

`include "svc.sv"
`include "svc_gfx_line.sv"
`include "svc_gfx_rect_fill.sv"

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
  typedef enum {
    STATE_IDLE,
    STATE_CLEARING,
    STATE_DRAWING,
    STATE_PAUSE,
    STATE_DONE
  } state_t;

  state_t                   state;
  state_t                   state_next;

  logic                     s_gfx_done_next;

  logic                     clr_start;
  logic                     clr_done;

  logic                     line_start;
  logic                     line_start_next;

  logic                     line_done;

  logic   [    H_WIDTH-1:0] line_x0;
  logic   [    V_WIDTH-1:0] line_y0;
  logic   [    H_WIDTH-1:0] line_x1;
  logic   [    V_WIDTH-1:0] line_y1;
  logic   [PIXEL_WIDTH-1:0] line_color;
  logic   [PIXEL_WIDTH-1:0] line_color_next;

  logic   [    H_WIDTH-1:0] line_x0_next;
  logic   [    V_WIDTH-1:0] line_y0_next;
  logic   [    H_WIDTH-1:0] line_x1_next;
  logic   [    V_WIDTH-1:0] line_y1_next;

  // Graphics mux signals
  logic                     rect_valid;
  logic   [    H_WIDTH-1:0] rect_x;
  logic   [    V_WIDTH-1:0] rect_y;
  logic   [PIXEL_WIDTH-1:0] rect_pixel;
  logic                     rect_ready;

  logic                     line_valid;
  logic   [    H_WIDTH-1:0] line_x;
  logic   [    V_WIDTH-1:0] line_y;
  logic   [PIXEL_WIDTH-1:0] line_pixel;
  logic                     line_ready;

  logic                     line_dir;
  logic                     line_dir_next;

  logic   [           19:0] cnt;
  logic   [           19:0] cnt_next;

  // Mux control - 0 for rect, 1 for line
  logic                     gfx_mux_sel;

  logic   [            1:0] color_cnt;
  logic   [            1:0] color_cnt_next;

  logic   [            7:0] sweep_cnt;
  logic   [            7:0] sweep_cnt_next;

  // Set mux select based on state
  assign gfx_mux_sel = (state == STATE_DRAWING);

  // Output signals next
  logic                   m_gfx_valid_next;
  logic [    H_WIDTH-1:0] m_gfx_x_next;
  logic [    V_WIDTH-1:0] m_gfx_y_next;
  logic [PIXEL_WIDTH-1:0] m_gfx_pixel_next;

  // Output mux combinational logic
  assign m_gfx_valid_next = gfx_mux_sel ? line_valid : rect_valid;
  assign m_gfx_x_next     = gfx_mux_sel ? line_x : rect_x;
  assign m_gfx_y_next     = gfx_mux_sel ? line_y : rect_y;
  assign m_gfx_pixel_next = gfx_mux_sel ? line_pixel : rect_pixel;

  // Input demux
  assign rect_ready       = gfx_mux_sel ? 1'b0 : m_gfx_ready;
  assign line_ready       = gfx_mux_sel ? m_gfx_ready : 1'b0;

  // clear screen
  svc_gfx_rect_fill #(
      .H_WIDTH    (H_WIDTH),
      .V_WIDTH    (V_WIDTH),
      .PIXEL_WIDTH(PIXEL_WIDTH)
  ) svc_gfx_rect_fill_i (
      .clk        (clk),
      .rst_n      (rst_n),
      .start      (clr_start),
      .done       (clr_done),
      .x0         ('0),
      .y0         ('0),
      .x1         (h_visible),
      .y1         (v_visible),
      .color      ('0),
      .m_gfx_valid(rect_valid),
      .m_gfx_x    (rect_x),
      .m_gfx_y    (rect_y),
      .m_gfx_pixel(rect_pixel),
      .m_gfx_ready(rect_ready)
  );

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
      .m_gfx_valid(line_valid),
      .m_gfx_x    (line_x),
      .m_gfx_y    (line_y),
      .m_gfx_pixel(line_pixel),
      .m_gfx_ready(line_ready)
  );

  // State machine and drawing logic
  always_comb begin
    state_next      = state;

    s_gfx_done_next = s_gfx_done;
    clr_start       = 1'b0;

    line_start_next = line_start;
    line_x0_next    = line_x0;
    line_y0_next    = line_y0;
    line_x1_next    = line_x1;
    line_y1_next    = line_y1;

    line_dir_next   = line_dir;

    cnt_next        = cnt;
    color_cnt_next  = color_cnt;
    line_color_next = line_color;

    sweep_cnt_next  = sweep_cnt;

    case (state)
      STATE_IDLE: begin
        if (s_gfx_start) begin
          state_next = STATE_CLEARING;
          clr_start  = 1'b1;
        end
      end

      STATE_CLEARING: begin
        if (clr_done) begin
          state_next      = STATE_DRAWING;
          line_start_next = 1'b1;
        end
      end

      STATE_DRAWING: begin
        line_start_next = 1'b0;

        if (line_done) begin
          s_gfx_done_next = 1'b1;
          state_next      = STATE_PAUSE;
        end
      end

      STATE_PAUSE: begin
        cnt_next = cnt + 1;

        if (cnt == '1) begin
          if (line_dir == 0) begin
            line_y0_next = line_y0 + 1;
          end else begin
            line_y0_next = line_y0 - 1;
          end

          if (line_y0 == 100) begin
            // if (line_y0 == h_visible / 4) begin
            line_dir_next  = 0;
            color_cnt_next = color_cnt + 1;

            case (color_cnt)
              2'b00: begin
                line_color_next = 12'h00F;
              end
              2'b01: begin
                line_color_next = 12'h0F0;
              end
              2'b10: begin
                line_color_next = 12'h0FF;
              end
              2'b11: begin
                line_color_next = 12'hFFF;
              end
            endcase
          end

          if (line_y0 == line_y1) begin
            line_dir_next  = 1;
            sweep_cnt_next = sweep_cnt + 1;

            case (color_cnt)
              2'b00: begin
                line_color_next = 12'h00F;
              end
              2'b01: begin
                line_color_next = 12'h0F0;
              end
              2'b10: begin
                line_color_next = 12'h0FF;
              end
              2'b11: begin
                line_color_next = 12'hFFF;
              end
            endcase
          end

          // if (sweep_cnt < 8) begin
          //   line_start_next = 1'b1;
          //   state_next      = STATE_DRAWING;
          // end else begin
          //   state_next = STATE_DONE;
          // end
          //
          line_start_next = 1'b1;
          state_next      = STATE_DRAWING;
        end

      end

      STATE_DONE: begin
      end

      default: state_next = STATE_IDLE;
    endcase
  end

  // State register
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state       <= STATE_IDLE;
      s_gfx_done  <= 1'b0;
      cnt         <= 0;

      line_start  <= 0;
      line_x0     <= 100;  //h_visible / 4;
      line_y0     <= 100;  //v_visible / 4;
      line_x1     <= 400;  //(h_visible * 3) / 4;
      line_y1     <= 400;  //(v_visible * 3) / 4;
      line_color  <= 0;
      line_dir    <= 0;

      color_cnt   <= 0;

      // Reset output registers
      m_gfx_valid <= 1'b0;
      m_gfx_x     <= '0;
      m_gfx_y     <= '0;
      m_gfx_pixel <= '0;
    end else begin
      state       <= state_next;
      s_gfx_done  <= s_gfx_done_next;
      cnt         <= cnt_next;

      line_start  <= line_start_next;
      line_x0     <= line_x0_next;
      line_y0     <= line_y0_next;
      line_x1     <= line_x1_next;
      line_y1     <= line_y1_next;
      line_dir    <= line_dir_next;

      line_color  <= line_color_next;
      color_cnt   <= color_cnt_next;

      sweep_cnt   <= sweep_cnt_next;

      // Register outputs
      m_gfx_valid <= m_gfx_valid_next;
      m_gfx_x     <= m_gfx_x_next;
      m_gfx_y     <= m_gfx_y_next;
      m_gfx_pixel <= m_gfx_pixel_next;

    end
  end

endmodule
`endif
