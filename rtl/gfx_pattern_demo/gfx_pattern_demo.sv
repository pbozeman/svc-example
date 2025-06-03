`ifndef GFX_PATTERN_DEMO_SV
`define GFX_PATTERN_DEMO_SV

`include "svc_ice40_axi_sram.sv"

`include "gfx_pattern_axi.sv"

// verilator lint_off: UNUSEDSIGNAL
module gfx_pattern_demo #(
    parameter COLOR_WIDTH     = 4,
    parameter H_WIDTH         = 12,
    parameter V_WIDTH         = 12,
    parameter SRAM_ADDR_WIDTH = 18,
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

    output logic [SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [SRAM_DATA_WIDTH-1:0] sram_io_data,
    output logic                       sram_io_we_n,
    output logic                       sram_io_oe_n,
    output logic                       sram_io_ce_n
);
  localparam NUM_M = 3;
  localparam AXI_ADDR_WIDTH = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam AXI_DATA_WIDTH = SRAM_DATA_WIDTH;
  localparam AXI_ID_WIDTH = 4 + $clog2(NUM_M);
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

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

  svc_ice40_axi_sram #(
      .AXI_ADDR_WIDTH      (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH      (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH        (AXI_ID_WIDTH),
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

  gfx_pattern_axi #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH),
      .COLOR_WIDTH   (COLOR_WIDTH),
      .H_WIDTH       (H_WIDTH),
      .V_WIDTH       (V_WIDTH)
  ) gfx_pattern_axi_i (
      .clk  (clk),
      .rst_n(rst_n),

      .pixel_clk  (pixel_clk),
      .pixel_rst_n(pixel_rst_n),

      .continious_write(continious_write),

      .m_axi_awvalid(sram_axi_awvalid),
      .m_axi_awaddr (sram_axi_awaddr),
      .m_axi_awburst(sram_axi_awburst),
      .m_axi_awid   (sram_axi_awid),
      .m_axi_awlen  (sram_axi_awlen),
      .m_axi_awsize (sram_axi_awsize),
      .m_axi_awready(sram_axi_awready),
      .m_axi_wdata  (sram_axi_wdata),
      .m_axi_wlast  (sram_axi_wlast),
      .m_axi_wready (sram_axi_wready),
      .m_axi_wstrb  (sram_axi_wstrb),
      .m_axi_wvalid (sram_axi_wvalid),
      .m_axi_bvalid (sram_axi_bvalid),
      .m_axi_bid    (sram_axi_bid),
      .m_axi_bresp  (sram_axi_bresp),
      .m_axi_bready (sram_axi_bready),

      .m_axi_arvalid(sram_axi_arvalid),
      .m_axi_araddr (sram_axi_araddr),
      .m_axi_arburst(sram_axi_arburst),
      .m_axi_arid   (sram_axi_arid),
      .m_axi_arlen  (sram_axi_arlen),
      .m_axi_arsize (sram_axi_arsize),
      .m_axi_arready(sram_axi_arready),
      .m_axi_rvalid (sram_axi_rvalid),
      .m_axi_rid    (sram_axi_rid),
      .m_axi_rdata  (sram_axi_rdata),
      .m_axi_rresp  (sram_axi_rresp),
      .m_axi_rlast  (sram_axi_rlast),
      .m_axi_rready (sram_axi_rready),

      .vga_red  (vga_red),
      .vga_grn  (vga_grn),
      .vga_blu  (vga_blu),
      .vga_hsync(vga_hsync),
      .vga_vsync(vga_vsync),
      .vga_error(vga_error)
  );

endmodule
`endif
