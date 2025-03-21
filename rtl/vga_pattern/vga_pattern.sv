`ifndef VGA_PATTERN_SV
`define VGA_PATTERN_SV

`include "svc_pix_cdc.sv"
`include "svc_pix_vga.sv"
`include "svc_rgb.sv"
`include "svc_vga_mode.sv"

//
// Color Bar Stream to VGA
//
// https://en.wikipedia.org/wiki/SMPTE_color_bars
//
// Use colors as defined on the page above, converting from the 10-bit RGBs.
`define C_75_OFF `SVC_RGB_M_TO_N(64, 10, COLOR_WIDTH)
`define C_75_ON `SVC_RGB_M_TO_N(721, 10, COLOR_WIDTH)

// TODO: make the vga mode configurable
// verilator lint_off: UNUSEDSIGNAL
module vga_pattern #(
    parameter COLOR_WIDTH = 4
) (
    input logic clk,
    input logic rst_n,

    input logic pixel_clk,
    input logic pixel_rst_n,

    output logic [COLOR_WIDTH-1:0] vga_red,
    output logic [COLOR_WIDTH-1:0] vga_grn,
    output logic [COLOR_WIDTH-1:0] vga_blu,
    output logic                   vga_hsync,
    output logic                   vga_vsync
);
  localparam AW = 16;
  localparam CW = COLOR_WIDTH;
  localparam HW = 12;
  localparam VW = 12;
  localparam PW = CW * 3;

  localparam [CW-1:0] C_OFF = `C_75_OFF;
  localparam [CW-1:0] C_ON = `C_75_ON;

  localparam [PW-1:0] WHITE = {C_ON, C_ON, C_ON};
  localparam [PW-1:0] YELLOW = {C_ON, C_ON, C_OFF};
  localparam [PW-1:0] RED = {C_ON, C_OFF, C_OFF};
  localparam [PW-1:0] GREEN = {C_OFF, C_ON, C_OFF};
  localparam [PW-1:0] BLUE = {C_OFF, C_OFF, C_ON};
  localparam [PW-1:0] CYAN = {C_OFF, C_ON, C_ON};
  localparam [PW-1:0] MAGENTA = {C_ON, C_OFF, C_ON};
  localparam [PW-1:0] BLACK = {C_OFF, C_OFF, C_OFF};

  logic [HW-1:0]         h_visible;
  logic [HW-1:0]         h_sync_start;
  logic [HW-1:0]         h_sync_end;
  logic [HW-1:0]         h_line_end;

  logic [HW-1:0]         v_visible;
  logic [HW-1:0]         v_sync_start;
  logic [HW-1:0]         v_sync_end;
  logic [HW-1:0]         v_frame_end;

  logic                  m_pix_valid;
  logic                  m_pix_valid_next;

  logic [CW-1:0]         m_pix_red;
  logic [CW-1:0]         m_pix_grn;
  logic [CW-1:0]         m_pix_blu;
  logic [HW-1:0]         m_pix_x;
  logic [VW-1:0]         m_pix_y;
  logic [AW-1:0]         m_pix_addr;
  logic                  m_pix_ready;

  // horizontal position
  logic [HW-1:0]         x;
  logic [HW-1:0]         x_next;

  // vert position
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

  // these signals are in the pixel clock domain
  logic                  vga_pix_valid;
  logic [CW-1:0]         vga_pix_red;
  logic [CW-1:0]         vga_pix_grn;
  logic [CW-1:0]         vga_pix_blu;
  logic [HW-1:0]         vga_pix_x;
  logic [VW-1:0]         vga_pix_y;
  logic [AW-1:0]         vga_pix_addr;
  logic                  vga_pix_ready;
  logic                  vga_error;

  assign h_visible    = `VGA_MODE_H_VISIBLE;
  assign h_sync_start = `VGA_MODE_H_SYNC_START;
  assign h_sync_end   = `VGA_MODE_H_SYNC_END;
  assign h_line_end   = `VGA_MODE_H_LINE_END;

  assign v_visible    = `VGA_MODE_V_VISIBLE;
  assign v_sync_start = `VGA_MODE_V_SYNC_START;
  assign v_sync_end   = `VGA_MODE_V_SYNC_END;
  assign v_frame_end  = `VGA_MODE_V_FRAME_END;

  assign col_colors   = {BLACK, BLUE, RED, MAGENTA, GREEN, CYAN, YELLOW, WHITE};

  // we have 8 columns, so divide by 8 for width
  assign col_width    = h_visible >> 3;

  always_comb begin
    m_pix_valid_next = m_pix_valid && !m_pix_ready;

    if (!m_pix_valid || m_pix_ready) begin
      m_pix_valid_next = 1'b1;
    end
  end

  always_comb begin
    x_next        = x;
    y_next        = y;

    col_next      = col;
    col_edge_next = col_edge;

    if (m_pix_valid && m_pix_ready) begin
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
          y_next = 0;
        end
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      m_pix_valid <= 1'b0;
      x           <= 0;
      y           <= 0;
      col         <= 0;
      col_edge    <= col_width;
    end else begin
      m_pix_valid <= m_pix_valid_next;
      x           <= x_next;
      y           <= y_next;
      col         <= col_next;
      col_edge    <= col_edge_next;
    end
  end

  assign {m_pix_red, m_pix_grn, m_pix_blu} = col_colors[col];
  assign m_pix_x                           = x;
  assign m_pix_y                           = y;

  // TODO: it's ok, it isn't used.. but it should probably be removed from the
  // pix interface
  assign m_pix_addr                        = 0;

  svc_pix_cdc #(
      .COLOR_WIDTH(COLOR_WIDTH)
  ) svc_pix_cdc_i (
      .s_clk  (clk),
      .s_rst_n(rst_n),

      .s_pix_valid(m_pix_valid),
      .s_pix_red  (m_pix_red),
      .s_pix_grn  (m_pix_grn),
      .s_pix_blu  (m_pix_blu),
      .s_pix_x    (m_pix_x),
      .s_pix_y    (m_pix_y),

      .s_pix_ready(m_pix_ready),

      .m_clk      (pixel_clk),
      .m_rst_n    (pixel_rst_n),
      .m_pix_valid(vga_pix_valid),
      .m_pix_red  (vga_pix_red),
      .m_pix_grn  (vga_pix_grn),
      .m_pix_blu  (vga_pix_blu),
      .m_pix_x    (vga_pix_x),
      .m_pix_y    (vga_pix_y),
      .m_pix_ready(vga_pix_ready)
  );

  svc_pix_vga #(
      .H_WIDTH    (HW),
      .V_WIDTH    (VW),
      .COLOR_WIDTH(COLOR_WIDTH)
  ) svc_pix_vga_i (
      .clk  (pixel_clk),
      .rst_n(pixel_rst_n),

      .s_pix_valid(vga_pix_valid),
      .s_pix_red  (vga_pix_red),
      .s_pix_grn  (vga_pix_grn),
      .s_pix_blu  (vga_pix_blu),
      .s_pix_x    (vga_pix_x),
      .s_pix_y    (vga_pix_y),
      .s_pix_ready(vga_pix_ready),

      .h_visible   (h_visible),
      .h_sync_start(h_sync_start),
      .h_sync_end  (h_sync_end),
      .h_line_end  (h_line_end),

      .v_visible   (v_visible),
      .v_sync_start(v_sync_start),
      .v_sync_end  (v_sync_end),
      .v_frame_end (v_frame_end),

      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_error(vga_error)
  );

endmodule
`endif
