`ifndef ADC_XY_GFX_AXI_SV
`define ADC_XY_GFX_AXI_SV

`include "svc.sv"
`include "svc_gfx_vga_fade.sv"
`include "svc_gfx_rect_fill.sv"
`include "svc_skidbuf.sv"

`include "adc_xy_gfx.sv"

module adc_xy_gfx_axi #(
    parameter AXI_ADDR_WIDTH  = 27,
    parameter AXI_DATA_WIDTH  = 32,
    parameter AXI_ID_WIDTH    = 4,
    parameter AXI_STRB_WIDTH  = AXI_DATA_WIDTH / 8,
    parameter COLOR_WIDTH     = 4,
    parameter H_WIDTH         = 12,
    parameter V_WIDTH         = 12,
    parameter ADC_DATA_WIDTH  = 10,
    parameter ADC_SCALE_NUM_X = 3,
    parameter ADC_SCALE_DEN_X = 4,
    parameter ADC_SCALE_NUM_Y = 3,
    parameter ADC_SCALE_DEN_Y = 4,
    parameter ADC_DELAY       = 7
) (
    input logic clk,
    input logic rst_n,

    input logic pixel_clk,
    input logic pixel_rst_n,

    input logic adc_clk,
    input logic adc_rst_n,


    input logic [ADC_DATA_WIDTH-1:0] adc_x_io,
    input logic [ADC_DATA_WIDTH-1:0] adc_y_io,
    input logic                      adc_red_io,
    input logic                      adc_grn_io,
    input logic                      adc_blu_io,

    output logic                      m_axi_awvalid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [               1:0] m_axi_awburst,
    output logic [  AXI_ID_WIDTH-1:0] m_axi_awid,
    output logic [               7:0] m_axi_awlen,
    output logic [               2:0] m_axi_awsize,
    input  logic                      m_axi_awready,
    output logic [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output logic                      m_axi_wlast,
    input  logic                      m_axi_wready,
    output logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                      m_axi_wvalid,
    input  logic                      m_axi_bvalid,
    input  logic [  AXI_ID_WIDTH-1:0] m_axi_bid,
    input  logic [               1:0] m_axi_bresp,
    output logic                      m_axi_bready,

    output logic                      m_axi_arvalid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [               1:0] m_axi_arburst,
    output logic [  AXI_ID_WIDTH-1:0] m_axi_arid,
    output logic [               7:0] m_axi_arlen,
    output logic [               2:0] m_axi_arsize,
    input  logic                      m_axi_arready,
    input  logic                      m_axi_rvalid,
    input  logic [  AXI_ID_WIDTH-1:0] m_axi_rid,
    input  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [               1:0] m_axi_rresp,
    input  logic                      m_axi_rlast,
    output logic                      m_axi_rready,

    output logic [COLOR_WIDTH-1:0] vga_red,
    output logic [COLOR_WIDTH-1:0] vga_grn,
    output logic [COLOR_WIDTH-1:0] vga_blu,
    output logic                   vga_hsync,
    output logic                   vga_vsync,
    output logic                   vga_error
);
  localparam PIXEL_WIDTH = COLOR_WIDTH * 3;

  // Black color for clear screen
  localparam [PIXEL_WIDTH-1:0] BLACK = {(PIXEL_WIDTH) {1'b0}};

  // adc_gfx writes to the gfx/framebuffer
  logic                   adc_gfx_valid;
  logic [    H_WIDTH-1:0] adc_gfx_x;
  logic [    V_WIDTH-1:0] adc_gfx_y;
  logic [PIXEL_WIDTH-1:0] adc_gfx_pixel;
  logic                   adc_gfx_ready;

  // clear screen control signals
  logic                   clear_start;
  logic                   clear_done;
  logic                   clear_gfx_valid;
  logic [    H_WIDTH-1:0] clear_gfx_x;
  logic [    V_WIDTH-1:0] clear_gfx_y;
  logic [PIXEL_WIDTH-1:0] clear_gfx_pixel;
  logic                   clear_gfx_ready;

  // sb for gfx
  logic                   sb_gfx_valid;
  logic [    H_WIDTH-1:0] sb_gfx_x;
  logic [    V_WIDTH-1:0] sb_gfx_y;
  logic [PIXEL_WIDTH-1:0] sb_gfx_pixel;
  logic                   sb_gfx_ready;

  // output signals from skidbuf - these go to gfx_vga_fade
  logic                   gfx_valid;
  logic [    H_WIDTH-1:0] gfx_x;
  logic [    V_WIDTH-1:0] gfx_y;
  logic [PIXEL_WIDTH-1:0] gfx_pixel;
  logic                   gfx_ready;

  logic [    H_WIDTH-1:0] h_visible;
  logic [    H_WIDTH-1:0] h_sync_start;
  logic [    H_WIDTH-1:0] h_sync_end;
  logic [    H_WIDTH-1:0] h_line_end;

  logic [    V_WIDTH-1:0] v_visible;
  logic [    V_WIDTH-1:0] v_sync_start;
  logic [    V_WIDTH-1:0] v_sync_end;
  logic [    V_WIDTH-1:0] v_frame_end;

  typedef enum {
    STATE_IDLE,
    STATE_CLEAR,
    STATE_ADC
  } state_t;

  state_t state;
  state_t state_next;

  logic   clear_start_next;

  // Using constants from VGA mode macro (same as in gfx_pattern_axi.sv)
  localparam MODE_H_VISIBLE = `VGA_MODE_H_VISIBLE;
  localparam MODE_H_SYNC_START = `VGA_MODE_H_SYNC_START;
  localparam MODE_H_SYNC_END = `VGA_MODE_H_SYNC_END;
  localparam MODE_H_LINE_END = `VGA_MODE_H_LINE_END;

  localparam MODE_V_VISIBLE = `VGA_MODE_V_VISIBLE;
  localparam MODE_V_SYNC_START = `VGA_MODE_V_SYNC_START;
  localparam MODE_V_SYNC_END = `VGA_MODE_V_SYNC_END;
  localparam MODE_V_FRAME_END = `VGA_MODE_V_FRAME_END;

  assign h_visible    = MODE_H_VISIBLE;
  assign h_sync_start = MODE_H_SYNC_START;
  assign h_sync_end   = MODE_H_SYNC_END;
  assign h_line_end   = MODE_H_LINE_END;

  assign v_visible    = MODE_V_VISIBLE;
  assign v_sync_start = MODE_V_SYNC_START;
  assign v_sync_end   = MODE_V_SYNC_END;
  assign v_frame_end  = MODE_V_FRAME_END;

  svc_gfx_vga_fade #(
      .H_WIDTH       (H_WIDTH),
      .V_WIDTH       (V_WIDTH),
      .PIXEL_WIDTH   (PIXEL_WIDTH),
      .COLOR_WIDTH   (COLOR_WIDTH),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_gfx_vga_fade_i (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(pixel_rst_n),

      .fb_start(clear_done),

      .s_gfx_valid(gfx_valid),
      .s_gfx_x    (gfx_x),
      .s_gfx_y    (gfx_y),
      .s_gfx_pixel(gfx_pixel),
      .s_gfx_ready(gfx_ready),

      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wlast  (m_axi_wlast),
      .m_axi_wready (m_axi_wready),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bid    (m_axi_bid),
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bready (m_axi_bready),

      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arid   (m_axi_arid),
      .m_axi_araddr (m_axi_araddr),
      .m_axi_arlen  (m_axi_arlen),
      .m_axi_arsize (m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arready(m_axi_arready),
      .m_axi_rvalid (m_axi_rvalid),
      .m_axi_rid    (m_axi_rid),
      .m_axi_rdata  (m_axi_rdata),
      .m_axi_rresp  (m_axi_rresp),
      .m_axi_rlast  (m_axi_rlast),
      .m_axi_rready (m_axi_rready),

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

  // Clear screen module
  svc_gfx_rect_fill #(
      .H_WIDTH    (H_WIDTH),
      .V_WIDTH    (V_WIDTH),
      .PIXEL_WIDTH(PIXEL_WIDTH)
  ) svc_gfx_rect_fill_i (
      .clk  (clk),
      .rst_n(rst_n),

      .start(clear_start),
      .done (clear_done),

      .x0   (H_WIDTH'(0)),
      .y0   (V_WIDTH'(0)),
      .x1   (h_visible - 1'b1),
      .y1   (v_visible - 1'b1),
      .color(BLACK),

      .m_gfx_valid(clear_gfx_valid),
      .m_gfx_x    (clear_gfx_x),
      .m_gfx_y    (clear_gfx_y),
      .m_gfx_pixel(clear_gfx_pixel),
      .m_gfx_ready(clear_gfx_ready)
  );

  adc_xy_gfx #(
      .ADC_DATA_WIDTH (ADC_DATA_WIDTH),
      .ADC_SCALE_NUM_X(ADC_SCALE_NUM_X),
      .ADC_SCALE_DEN_X(ADC_SCALE_DEN_X),
      .ADC_SCALE_NUM_Y(ADC_SCALE_NUM_Y),
      .ADC_SCALE_DEN_Y(ADC_SCALE_DEN_Y),
      .ADC_DELAY      (ADC_DELAY),
      .H_WIDTH        (H_WIDTH),
      .V_WIDTH        (V_WIDTH),
      .PIXEL_WIDTH    (PIXEL_WIDTH)
  ) adc_xy_gfx_i (
      .clk        (clk),
      .rst_n      (rst_n),
      .adc_clk    (adc_clk),
      .adc_rst_n  (adc_rst_n),
      .adc_x_io   (adc_x_io),
      .adc_y_io   (adc_y_io),
      .adc_red_io (adc_red_io),
      .adc_grn_io (adc_grn_io),
      .adc_blu_io (adc_blu_io),
      .m_gfx_valid(adc_gfx_valid),
      .m_gfx_x    (adc_gfx_x),
      .m_gfx_y    (adc_gfx_y),
      .m_gfx_pixel(adc_gfx_pixel),
      .m_gfx_ready(adc_gfx_ready)
  );

  svc_skidbuf #(
      .DATA_WIDTH(H_WIDTH + V_WIDTH + PIXEL_WIDTH),
      .OPT_OUTREG(1)
  ) gfx_skidbuf (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(sb_gfx_valid),
      .i_data ({sb_gfx_x, sb_gfx_y, sb_gfx_pixel}),
      .o_ready(sb_gfx_ready),

      .o_valid(gfx_valid),
      .o_data ({gfx_x, gfx_y, gfx_pixel}),
      .i_ready(gfx_ready)
  );

  always_comb begin
    state_next       = state;
    clear_start_next = 1'b0;

    sb_gfx_valid     = 1'b0;
    sb_gfx_x         = 0;
    sb_gfx_y         = 0;
    sb_gfx_pixel     = 0;
    clear_gfx_ready  = 1'b0;
    adc_gfx_ready    = 1'b0;

    case (state)
      STATE_IDLE: begin
        clear_start_next = 1'b1;
        state_next       = STATE_CLEAR;
      end

      STATE_CLEAR: begin
        if (clear_done) begin
          state_next = STATE_ADC;
        end else begin
          sb_gfx_valid    = clear_gfx_valid;
          sb_gfx_x        = clear_gfx_x;
          sb_gfx_y        = clear_gfx_y;
          sb_gfx_pixel    = clear_gfx_pixel;
          clear_gfx_ready = sb_gfx_ready;
        end
      end

      STATE_ADC: begin
        sb_gfx_valid  = adc_gfx_valid;
        sb_gfx_x      = adc_gfx_x;
        sb_gfx_y      = adc_gfx_y;
        sb_gfx_pixel  = adc_gfx_pixel;
        adc_gfx_ready = sb_gfx_ready;
      end

      default: begin
        state_next = STATE_IDLE;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state       <= STATE_IDLE;
      clear_start <= 1'b0;
    end else begin
      state       <= state_next;
      clear_start <= clear_start_next;
    end
  end

endmodule
`endif
