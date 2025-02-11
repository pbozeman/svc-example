`ifndef GFX_PATTERN_DEMO_SV
`define GFX_PATTERN_DEMO_SV

`include "svc_axi_burst_adapter.sv"
`include "svc_fb_pix.sv"
`include "svc_gfx_fb.sv"
`include "svc_ice40_axi_sram.sv"
`include "svc_ice40_vga_mode.sv"
`include "svc_pix_cdc.sv"
`include "svc_pix_vga.sv"

`include "gfx_pattern.sv"

// verilator lint_off: UNUSEDSIGNAL
// verilator lint_off: UNDRIVEN
module gfx_pattern_demo #(
    parameter COLOR_WIDTH      = 4,
    parameter H_WIDTH          = 12,
    parameter V_WIDTH          = 12,
    parameter SRAM_ADDR_WIDTH  = 20,
    parameter SRAM_DATA_WIDTH  = 16,
    parameter SRAM_RDATA_WIDTH = SRAM_DATA_WIDTH
) (
    input logic clk,
    input logic rst_n,

    input logic pixel_clk,
    input logic pixel_rst_n,

    output logic [COLOR_WIDTH-1:0] vga_red,
    output logic [COLOR_WIDTH-1:0] vga_grn,
    output logic [COLOR_WIDTH-1:0] vga_blu,
    output logic                   vga_hsync,
    output logic                   vga_vsync,
    output logic                   vga_error,

    output logic [ SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] sram_io_data,
    output logic                        sram_io_we_n,
    output logic                        sram_io_oe_n,
    output logic                        sram_io_ce_n
);
  localparam AXI_ADDR_WIDTH = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam AXI_DATA_WIDTH = SRAM_DATA_WIDTH;
  localparam AXI_ID_WIDTH = 4;
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

  localparam PIXEL_WIDTH = COLOR_WIDTH * 3;

  logic                      sram_axi_awvalid;
  logic [AXI_ADDR_WIDTH-1:0] sram_axi_awaddr;
  logic [  AXI_ID_WIDTH-1:0] sram_axi_awid;
  logic [               7:0] sram_axi_awlen;
  logic [               2:0] sram_axi_awsize;
  logic [               1:0] sram_axi_awburst;
  logic                      sram_axi_awready;
  logic                      sram_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] sram_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] sram_axi_wstrb;
  logic                      sram_axi_wlast;
  logic                      sram_axi_wready;
  logic                      sram_axi_bvalid;
  logic [  AXI_ID_WIDTH-1:0] sram_axi_bid;
  logic [               1:0] sram_axi_bresp;
  logic                      sram_axi_bready;

  logic                      sram_axi_arvalid;
  logic [  AXI_ID_WIDTH-1:0] sram_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0] sram_axi_araddr;
  logic [               7:0] sram_axi_arlen;
  logic [               2:0] sram_axi_arsize;
  logic [               1:0] sram_axi_arburst;
  logic                      sram_axi_arready;
  logic                      sram_axi_rvalid;
  logic [  AXI_ID_WIDTH-1:0] sram_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] sram_axi_rdata;
  logic [               1:0] sram_axi_rresp;
  logic                      sram_axi_rlast;
  logic                      sram_axi_rready;

  logic                      fb_axi_awvalid;
  logic [AXI_ADDR_WIDTH-1:0] fb_axi_awaddr;
  logic [  AXI_ID_WIDTH-1:0] fb_axi_awid;
  logic [               7:0] fb_axi_awlen;
  logic [               2:0] fb_axi_awsize;
  logic [               1:0] fb_axi_awburst;
  logic                      fb_axi_awready;
  logic                      fb_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] fb_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] fb_axi_wstrb;
  logic                      fb_axi_wlast;
  logic                      fb_axi_wready;
  logic                      fb_axi_bvalid;
  logic [  AXI_ID_WIDTH-1:0] fb_axi_bid;
  logic [               1:0] fb_axi_bresp;
  logic                      fb_axi_bready;

  logic                      fb_axi_arvalid;
  logic [  AXI_ID_WIDTH-1:0] fb_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0] fb_axi_araddr;
  logic [               7:0] fb_axi_arlen;
  logic [               2:0] fb_axi_arsize;
  logic [               1:0] fb_axi_arburst;
  logic                      fb_axi_arready;
  logic                      fb_axi_rvalid;
  logic [  AXI_ID_WIDTH-1:0] fb_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] fb_axi_rdata;
  logic [               1:0] fb_axi_rresp;
  logic                      fb_axi_rlast;
  logic                      fb_axi_rready;

  // pat_gfx writes to the gfx/framebuffer
  logic                      pat_gfx_start;
  logic                      pat_gfx_done;

  logic                      pat_gfx_valid;
  logic [       H_WIDTH-1:0] pat_gfx_x;
  logic [       V_WIDTH-1:0] pat_gfx_y;
  logic [   PIXEL_WIDTH-1:0] pat_gfx_pixel;
  logic                      pat_gfx_ready;

  logic [       H_WIDTH-1:0] h_visible;
  logic [       H_WIDTH-1:0] h_sync_start;
  logic [       H_WIDTH-1:0] h_sync_end;
  logic [       H_WIDTH-1:0] h_line_end;

  logic [       H_WIDTH-1:0] v_visible;
  logic [       H_WIDTH-1:0] v_sync_start;
  logic [       H_WIDTH-1:0] v_sync_end;
  logic [       H_WIDTH-1:0] v_frame_end;

  logic                      fb_pix_valid;
  logic [   COLOR_WIDTH-1:0] fb_pix_red;
  logic [   COLOR_WIDTH-1:0] fb_pix_grn;
  logic [   COLOR_WIDTH-1:0] fb_pix_blu;
  logic                      fb_pix_ready;

  logic                      vga_pix_valid;
  logic [   COLOR_WIDTH-1:0] vga_pix_red;
  logic [   COLOR_WIDTH-1:0] vga_pix_grn;
  logic [   COLOR_WIDTH-1:0] vga_pix_blu;
  logic                      vga_pix_ready;

  // TODO: these need to be expanded in the macro defs or a pipelined module
  // that does the math needs to be created, because these seemed to result in actual
  // math circuity being synthesized. (Double check that) Aside from being wasteful,
  // it was actually causing timing issues. For now, run them through local params
  // to turn them into constants. (Again, double check)
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

  svc_ice40_axi_sram #(
      .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH      (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH        (AXI_ID_WIDTH),
      .SRAM_RDATA_WIDTH    (SRAM_RDATA_WIDTH),
      .OUTSTANDING_IO_WIDTH(3)
  ) svc_ice40_axi_sram_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(sram_axi_awvalid),
      .s_axi_awaddr (sram_axi_awaddr),
      .s_axi_awid   (sram_axi_awid),
      .s_axi_awlen  (sram_axi_awlen),
      .s_axi_awsize (sram_axi_awsize),
      .s_axi_awburst(sram_axi_awburst),
      .s_axi_awready(sram_axi_awready),
      .s_axi_wdata  (sram_axi_wdata),
      .s_axi_wstrb  (sram_axi_wstrb),
      .s_axi_wlast  (sram_axi_wlast),
      .s_axi_wvalid (sram_axi_wvalid),
      .s_axi_wready (sram_axi_wready),
      .s_axi_bresp  (sram_axi_bresp),
      .s_axi_bid    (sram_axi_bid),
      .s_axi_bvalid (sram_axi_bvalid),
      .s_axi_bready (sram_axi_bready),
      .s_axi_arvalid(sram_axi_arvalid),
      .s_axi_araddr (sram_axi_araddr),
      .s_axi_arid   (sram_axi_arid),
      .s_axi_arready(sram_axi_arready),
      .s_axi_arlen  (sram_axi_arlen),
      .s_axi_arsize (sram_axi_arsize),
      .s_axi_arburst(sram_axi_arburst),
      .s_axi_rvalid (sram_axi_rvalid),
      .s_axi_rid    (sram_axi_rid),
      .s_axi_rresp  (sram_axi_rresp),
      .s_axi_rlast  (sram_axi_rlast),
      .s_axi_rdata  (sram_axi_rdata),
      .s_axi_rready (sram_axi_rready),
      .sram_io_addr (sram_io_addr),
      .sram_io_data (sram_io_data),
      .sram_io_we_n (sram_io_we_n),
      .sram_io_oe_n (sram_io_oe_n),
      .sram_io_ce_n (sram_io_ce_n)
  );

  svc_axi_burst_adapter #(
      .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH      (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH        (AXI_ID_WIDTH),
      .OUTSTANDING_IO_WIDTH(4)
  ) svc_axi_burst_adapter_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(fb_axi_awvalid),
      .s_axi_awaddr (fb_axi_awaddr),
      .s_axi_awid   (fb_axi_awid),
      .s_axi_awlen  (fb_axi_awlen),
      .s_axi_awsize (fb_axi_awsize),
      .s_axi_awburst(fb_axi_awburst),
      .s_axi_awready(fb_axi_awready),
      .s_axi_wvalid (fb_axi_wvalid),
      .s_axi_wdata  (fb_axi_wdata),
      .s_axi_wstrb  (fb_axi_wstrb),
      .s_axi_wlast  (fb_axi_wlast),
      .s_axi_wready (fb_axi_wready),
      .s_axi_bvalid (fb_axi_bvalid),
      .s_axi_bid    (fb_axi_bid),
      .s_axi_bresp  (fb_axi_bresp),
      .s_axi_bready (fb_axi_bready),
      .s_axi_arvalid(fb_axi_arvalid),
      .s_axi_arid   (fb_axi_arid),
      .s_axi_araddr (fb_axi_araddr),
      .s_axi_arlen  (fb_axi_arlen),
      .s_axi_arsize (fb_axi_arsize),
      .s_axi_arburst(fb_axi_arburst),
      .s_axi_arready(fb_axi_arready),
      .s_axi_rvalid (fb_axi_rvalid),
      .s_axi_rid    (fb_axi_rid),
      .s_axi_rdata  (fb_axi_rdata),
      .s_axi_rresp  (fb_axi_rresp),
      .s_axi_rlast  (fb_axi_rlast),
      .s_axi_rready (fb_axi_rready),
      .m_axi_awvalid(sram_axi_awvalid),
      .m_axi_awaddr (sram_axi_awaddr),
      .m_axi_awid   (sram_axi_awid),
      .m_axi_awlen  (sram_axi_awlen),
      .m_axi_awsize (sram_axi_awsize),
      .m_axi_awburst(sram_axi_awburst),
      .m_axi_awready(sram_axi_awready),
      .m_axi_wvalid (sram_axi_wvalid),
      .m_axi_wdata  (sram_axi_wdata),
      .m_axi_wstrb  (sram_axi_wstrb),
      .m_axi_wlast  (sram_axi_wlast),
      .m_axi_wready (sram_axi_wready),
      .m_axi_bvalid (sram_axi_bvalid),
      .m_axi_bid    (sram_axi_bid),
      .m_axi_bresp  (sram_axi_bresp),
      .m_axi_bready (sram_axi_bready),
      .m_axi_arvalid(sram_axi_arvalid),
      .m_axi_arid   (sram_axi_arid),
      .m_axi_araddr (sram_axi_araddr),
      .m_axi_arlen  (sram_axi_arlen),
      .m_axi_arsize (sram_axi_arsize),
      .m_axi_arburst(sram_axi_arburst),
      .m_axi_arready(sram_axi_arready),
      .m_axi_rvalid (sram_axi_rvalid),
      .m_axi_rid    (sram_axi_rid),
      .m_axi_rdata  (sram_axi_rdata),
      .m_axi_rresp  (sram_axi_rresp),
      .m_axi_rlast  (sram_axi_rlast),
      .m_axi_rready (sram_axi_rready)
  );

  svc_gfx_fb #(
      .H_WIDTH       (H_WIDTH),
      .V_WIDTH       (V_WIDTH),
      .PIXEL_WIDTH   (PIXEL_WIDTH),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_gfx_fb_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_gfx_valid  (pat_gfx_valid),
      .s_gfx_x      (pat_gfx_x),
      .s_gfx_y      (pat_gfx_y),
      .s_gfx_pixel  (pat_gfx_pixel),
      .s_gfx_ready  (pat_gfx_ready),
      .h_visible    (h_visible),
      .v_visible    (v_visible),
      .m_axi_awvalid(fb_axi_awvalid),
      .m_axi_awaddr (fb_axi_awaddr),
      .m_axi_awid   (fb_axi_awid),
      .m_axi_awlen  (fb_axi_awlen),
      .m_axi_awsize (fb_axi_awsize),
      .m_axi_awburst(fb_axi_awburst),
      .m_axi_awready(fb_axi_awready),
      .m_axi_wvalid (fb_axi_wvalid),
      .m_axi_wdata  (fb_axi_wdata),
      .m_axi_wstrb  (fb_axi_wstrb),
      .m_axi_wlast  (fb_axi_wlast),
      .m_axi_wready (fb_axi_wready),
      .m_axi_bvalid (fb_axi_bvalid),
      .m_axi_bid    (fb_axi_bid),
      .m_axi_bresp  (fb_axi_bresp),
      .m_axi_bready (fb_axi_bready)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      pat_gfx_start <= 1'b1;
    end else begin
      pat_gfx_start <= pat_gfx_done;
    end
  end

  gfx_pattern #(
      .H_WIDTH    (H_WIDTH),
      .V_WIDTH    (V_WIDTH),
      .PIXEL_WIDTH(PIXEL_WIDTH)
  ) gfx_pattern_i (
      .clk  (clk),
      .rst_n(rst_n),

      .s_gfx_start(pat_gfx_start),
      .s_gfx_done (pat_gfx_done),

      .m_gfx_valid(pat_gfx_valid),
      .m_gfx_x    (pat_gfx_x),
      .m_gfx_y    (pat_gfx_y),
      .m_gfx_pixel(pat_gfx_pixel),
      .m_gfx_ready(pat_gfx_ready),

      .h_visible(h_visible),
      .v_visible(v_visible)
  );

  logic fb_pix_rst;
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      fb_pix_rst <= 1'b0;
    end else begin
      fb_pix_rst <= fb_pix_rst || pat_gfx_done;
    end
  end

  svc_fb_pix #(
      .H_WIDTH       (H_WIDTH),
      .V_WIDTH       (V_WIDTH),
      .COLOR_WIDTH   (COLOR_WIDTH),
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_fb_pix_i (
      .clk          (clk),
      .rst_n        (rst_n && pat_gfx_done),
      .m_pix_valid  (fb_pix_valid),
      .m_pix_red    (fb_pix_red),
      .m_pix_grn    (fb_pix_grn),
      .m_pix_blu    (fb_pix_blu),
      .m_pix_ready  (fb_pix_ready),
      .h_visible    (h_visible),
      .v_visible    (v_visible),
      .m_axi_arvalid(fb_axi_arvalid),
      .m_axi_arid   (fb_axi_arid),
      .m_axi_araddr (fb_axi_araddr),
      .m_axi_arlen  (fb_axi_arlen),
      .m_axi_arsize (fb_axi_arsize),
      .m_axi_arburst(fb_axi_arburst),
      .m_axi_arready(fb_axi_arready),
      .m_axi_rvalid (fb_axi_rvalid),
      .m_axi_rid    (fb_axi_rid),
      .m_axi_rdata  (fb_axi_rdata),
      .m_axi_rresp  (fb_axi_rresp),
      .m_axi_rlast  (fb_axi_rlast),
      .m_axi_rready (fb_axi_rready)
  );

  svc_pix_cdc #(
      .COLOR_WIDTH(COLOR_WIDTH)
  ) svc_pix_cdc_i (
      .s_clk  (clk),
      .s_rst_n(rst_n),

      .s_pix_valid(fb_pix_valid),
      .s_pix_red  (fb_pix_red),
      .s_pix_grn  (fb_pix_grn),
      .s_pix_blu  (fb_pix_blu),
      .s_pix_ready(fb_pix_ready),

      .m_clk      (pixel_clk),
      .m_rst_n    (pixel_rst_n),
      .m_pix_valid(vga_pix_valid),
      .m_pix_red  (vga_pix_red),
      .m_pix_grn  (vga_pix_grn),
      .m_pix_blu  (vga_pix_blu),
      .m_pix_ready(vga_pix_ready)
  );

  svc_pix_vga #(
      .H_WIDTH    (H_WIDTH),
      .V_WIDTH    (V_WIDTH),
      .COLOR_WIDTH(COLOR_WIDTH)
  ) svc_pix_vga_i (
      .clk  (pixel_clk),
      .rst_n(pixel_rst_n),

      .s_pix_valid(vga_pix_valid),
      .s_pix_red  (vga_pix_red),
      .s_pix_grn  (vga_pix_grn),
      .s_pix_blu  (vga_pix_blu),
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
