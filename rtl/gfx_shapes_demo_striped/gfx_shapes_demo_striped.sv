`ifndef GFX_SHAPES_DEMO_STRIPED_SV
`define GFX_SHAPES_DEMO_STRIPED_SV

`include "svc.sv"
`include "svc_ice40_axi_sram.sv"
`include "svc_axi_stripe.sv"

`include "gfx_shapes_axi.sv"

// verilator lint_off: UNUSEDSIGNAL
module gfx_shapes_demo_striped #(
    parameter NUM_S           = 2,
    parameter COLOR_WIDTH     = 4,
    parameter H_WIDTH         = 12,
    parameter V_WIDTH         = 12,
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 16
) (
    input logic clk,
    input logic rst_n,

    input logic pixel_clk,
    input logic pixel_rst_n,

    input logic continious_write,

    output logic [COLOR_WIDTH-1:0] vga_red,
    output logic [COLOR_WIDTH-1:0] vga_grn,
    output logic [COLOR_WIDTH-1:0] vga_blu,
    output logic                   vga_hsync,
    output logic                   vga_vsync,
    output logic                   vga_error,

    output logic [NUM_S-1:0][SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [NUM_S-1:0][SRAM_DATA_WIDTH-1:0] sram_io_data,
    output logic [NUM_S-1:0]                      sram_io_we_n,
    output logic [NUM_S-1:0]                      sram_io_oe_n,
    output logic [NUM_S-1:0]                      sram_io_ce_n
);
  localparam NUM_M = 3;

  localparam AXI_ADDR_WIDTH = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam AXI_DATA_WIDTH = SRAM_DATA_WIDTH;
  localparam AXI_ID_WIDTH = 4 + $clog2(NUM_M);
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

  localparam STRIPE_AXI_ADDR_WIDTH = AXI_ADDR_WIDTH + $clog2(NUM_S);

  logic [                NUM_S-1:0]                     sram_axi_awvalid;
  logic [                NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_axi_awaddr;
  logic [                NUM_S-1:0][  AXI_ID_WIDTH-1:0] sram_axi_awid;
  logic [                NUM_S-1:0][               7:0] sram_axi_awlen;
  logic [                NUM_S-1:0][               2:0] sram_axi_awsize;
  logic [                NUM_S-1:0][               1:0] sram_axi_awburst;
  logic [                NUM_S-1:0]                     sram_axi_awready;
  logic [                NUM_S-1:0]                     sram_axi_wvalid;
  logic [                NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_axi_wdata;
  logic [                NUM_S-1:0][AXI_STRB_WIDTH-1:0] sram_axi_wstrb;
  logic [                NUM_S-1:0]                     sram_axi_wlast;
  logic [                NUM_S-1:0]                     sram_axi_wready;
  logic [                NUM_S-1:0]                     sram_axi_bvalid;
  logic [                NUM_S-1:0][  AXI_ID_WIDTH-1:0] sram_axi_bid;
  logic [                NUM_S-1:0][               1:0] sram_axi_bresp;
  logic [                NUM_S-1:0]                     sram_axi_bready;

  logic [                NUM_S-1:0]                     sram_axi_arvalid;
  logic [                NUM_S-1:0][  AXI_ID_WIDTH-1:0] sram_axi_arid;
  logic [                NUM_S-1:0][AXI_ADDR_WIDTH-1:0] sram_axi_araddr;
  logic [                NUM_S-1:0][               7:0] sram_axi_arlen;
  logic [                NUM_S-1:0][               2:0] sram_axi_arsize;
  logic [                NUM_S-1:0][               1:0] sram_axi_arburst;
  logic [                NUM_S-1:0]                     sram_axi_arready;
  logic [                NUM_S-1:0]                     sram_axi_rvalid;
  logic [                NUM_S-1:0][  AXI_ID_WIDTH-1:0] sram_axi_rid;
  logic [                NUM_S-1:0][AXI_DATA_WIDTH-1:0] sram_axi_rdata;
  logic [                NUM_S-1:0][               1:0] sram_axi_rresp;
  logic [                NUM_S-1:0]                     sram_axi_rlast;
  logic [                NUM_S-1:0]                     sram_axi_rready;

  logic                                                 fb_axi_awvalid;
  logic [STRIPE_AXI_ADDR_WIDTH-1:0]                     fb_axi_awaddr;
  logic [         AXI_ID_WIDTH-1:0]                     fb_axi_awid;
  logic [                      7:0]                     fb_axi_awlen;
  logic [                      2:0]                     fb_axi_awsize;
  logic [                      1:0]                     fb_axi_awburst;
  logic                                                 fb_axi_awready;
  logic                                                 fb_axi_wvalid;
  logic [       AXI_DATA_WIDTH-1:0]                     fb_axi_wdata;
  logic [       AXI_STRB_WIDTH-1:0]                     fb_axi_wstrb;
  logic                                                 fb_axi_wlast;
  logic                                                 fb_axi_wready;
  logic                                                 fb_axi_bvalid;
  logic [         AXI_ID_WIDTH-1:0]                     fb_axi_bid;
  logic [                      1:0]                     fb_axi_bresp;
  logic                                                 fb_axi_bready;

  logic                                                 fb_axi_arvalid;
  logic [         AXI_ID_WIDTH-1:0]                     fb_axi_arid;
  logic [STRIPE_AXI_ADDR_WIDTH-1:0]                     fb_axi_araddr;
  logic [                      7:0]                     fb_axi_arlen;
  logic [                      2:0]                     fb_axi_arsize;
  logic [                      1:0]                     fb_axi_arburst;
  logic                                                 fb_axi_arready;
  logic                                                 fb_axi_rvalid;
  logic [         AXI_ID_WIDTH-1:0]                     fb_axi_rid;
  logic [       AXI_DATA_WIDTH-1:0]                     fb_axi_rdata;
  logic [                      1:0]                     fb_axi_rresp;
  logic                                                 fb_axi_rlast;
  logic                                                 fb_axi_rready;

  for (genvar i = 0; i < NUM_S; i++) begin : gen_sram
    svc_ice40_axi_sram #(
        .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH      (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH        (AXI_ID_WIDTH),
        .OUTSTANDING_IO_WIDTH(3)
    ) svc_ice40_axi_sram_i (
        .clk          (clk),
        .rst_n        (rst_n),
        .s_axi_awvalid(sram_axi_awvalid[i]),
        .s_axi_awaddr (sram_axi_awaddr[i]),
        .s_axi_awid   (sram_axi_awid[i]),
        .s_axi_awlen  (sram_axi_awlen[i]),
        .s_axi_awsize (sram_axi_awsize[i]),
        .s_axi_awburst(sram_axi_awburst[i]),
        .s_axi_awready(sram_axi_awready[i]),
        .s_axi_wdata  (sram_axi_wdata[i]),
        .s_axi_wstrb  (sram_axi_wstrb[i]),
        .s_axi_wlast  (sram_axi_wlast[i]),
        .s_axi_wvalid (sram_axi_wvalid[i]),
        .s_axi_wready (sram_axi_wready[i]),
        .s_axi_bresp  (sram_axi_bresp[i]),
        .s_axi_bid    (sram_axi_bid[i]),
        .s_axi_bvalid (sram_axi_bvalid[i]),
        .s_axi_bready (sram_axi_bready[i]),
        .s_axi_arvalid(sram_axi_arvalid[i]),
        .s_axi_araddr (sram_axi_araddr[i]),
        .s_axi_arid   (sram_axi_arid[i]),
        .s_axi_arready(sram_axi_arready[i]),
        .s_axi_arlen  (sram_axi_arlen[i]),
        .s_axi_arsize (sram_axi_arsize[i]),
        .s_axi_arburst(sram_axi_arburst[i]),
        .s_axi_rvalid (sram_axi_rvalid[i]),
        .s_axi_rid    (sram_axi_rid[i]),
        .s_axi_rresp  (sram_axi_rresp[i]),
        .s_axi_rlast  (sram_axi_rlast[i]),
        .s_axi_rdata  (sram_axi_rdata[i]),
        .s_axi_rready (sram_axi_rready[i]),
        .sram_io_addr (sram_io_addr[i]),
        .sram_io_data (sram_io_data[i]),
        .sram_io_we_n (sram_io_we_n[i]),
        .sram_io_oe_n (sram_io_oe_n[i]),
        .sram_io_ce_n (sram_io_ce_n[i])
    );
  end

  svc_axi_stripe #(
      .NUM_S         (NUM_S),
      .AXI_ADDR_WIDTH(STRIPE_AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) svc_axi_stripe_i (
      .clk  (clk),
      .rst_n(rst_n),

      .s_axi_awvalid(fb_axi_awvalid),
      .s_axi_awid   (fb_axi_awid),
      .s_axi_awaddr (fb_axi_awaddr),
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
      .m_axi_awid   (sram_axi_awid),
      .m_axi_awaddr (sram_axi_awaddr),
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

  gfx_shapes_axi #(
      .AXI_ADDR_WIDTH(STRIPE_AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH),
      .COLOR_WIDTH   (COLOR_WIDTH),
      .H_WIDTH       (H_WIDTH),
      .V_WIDTH       (V_WIDTH)
  ) gfx_shapes_axi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(pixel_rst_n),

      .continious_write(continious_write),

      .m_axi_awvalid(fb_axi_awvalid),
      .m_axi_awaddr (fb_axi_awaddr),
      .m_axi_awburst(fb_axi_awburst),
      .m_axi_awid   (fb_axi_awid),
      .m_axi_awlen  (fb_axi_awlen),
      .m_axi_awsize (fb_axi_awsize),
      .m_axi_awready(fb_axi_awready),
      .m_axi_wdata  (fb_axi_wdata),
      .m_axi_wlast  (fb_axi_wlast),
      .m_axi_wready (fb_axi_wready),
      .m_axi_wstrb  (fb_axi_wstrb),
      .m_axi_wvalid (fb_axi_wvalid),
      .m_axi_bvalid (fb_axi_bvalid),
      .m_axi_bid    (fb_axi_bid),
      .m_axi_bresp  (fb_axi_bresp),
      .m_axi_bready (fb_axi_bready),

      .m_axi_arvalid(fb_axi_arvalid),
      .m_axi_araddr (fb_axi_araddr),
      .m_axi_arburst(fb_axi_arburst),
      .m_axi_arid   (fb_axi_arid),
      .m_axi_arlen  (fb_axi_arlen),
      .m_axi_arsize (fb_axi_arsize),
      .m_axi_arready(fb_axi_arready),
      .m_axi_rvalid (fb_axi_rvalid),
      .m_axi_rid    (fb_axi_rid),
      .m_axi_rdata  (fb_axi_rdata),
      .m_axi_rresp  (fb_axi_rresp),
      .m_axi_rlast  (fb_axi_rlast),
      .m_axi_rready (fb_axi_rready),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_error(vga_error)
  );

endmodule
`endif
