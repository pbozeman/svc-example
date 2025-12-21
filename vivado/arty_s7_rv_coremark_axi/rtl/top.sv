`include "svc.sv"

`include "svc_axi_mem.sv"
`include "svc_rv_soc_bram_cache.sv"
`include "svc_soc_io_reg.sv"

module top (
    input  wire        CLK100MHZ,
    input  wire        reset,
    output wire [ 3:0] led,
    output wire        UART_TX,
    output wire [13:0] ddr3_addr,
    output wire [ 2:0] ddr3_ba,
    output wire        ddr3_cas_n,
    output wire [ 0:0] ddr3_ck_n,
    output wire [ 0:0] ddr3_ck_p,
    output wire [ 0:0] ddr3_cke,
    output wire [ 0:0] ddr3_cs_n,
    output wire [ 1:0] ddr3_dm,
    inout  wire [15:0] ddr3_dq,
    inout  wire [ 1:0] ddr3_dqs_n,
    inout  wire [ 1:0] ddr3_dqs_p,
    output wire [ 0:0] ddr3_odt,
    output wire        ddr3_ras_n,
    output wire        ddr3_reset_n,
    output wire        ddr3_we_n
);
  // MIG UI clock is approximately 85.25 MHz (325 MHz / 4)
  localparam CLOCK_FREQ = 85_250_000;
  localparam BAUD_RATE = 115_200;

  // AXI parameters for MIG interface
  localparam AXI_ADDR_WIDTH = 28;
  localparam AXI_DATA_WIDTH = 128;
  localparam AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8;
  localparam AXI_ID_WIDTH = 4;

  wire clk;
  wire ui_clk_rst;
  wire rst_n;

  wire mmcm_locked;
  wire init_calib_complete;
  wire ebreak;
  wire sw_led;

  assign rst_n  = !ui_clk_rst;

  assign led[3] = mmcm_locked;
  assign led[2] = init_calib_complete;
  assign led[1] = ebreak;
  assign led[0] = sw_led;

  // AXI signals to MIG (all tied to idle/zero state)
  wire [AXI_ADDR_WIDTH-1:0] ddr_axi_araddr;
  wire [               1:0] ddr_axi_arburst;
  wire [               3:0] ddr_axi_arcache;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_arid;
  wire [               7:0] ddr_axi_arlen;
  wire                      ddr_axi_arlock;
  wire [               2:0] ddr_axi_arprot;
  wire [               3:0] ddr_axi_arqos;
  wire                      ddr_axi_arready;
  wire [               2:0] ddr_axi_arsize;
  wire                      ddr_axi_arvalid;
  wire [AXI_ADDR_WIDTH-1:0] ddr_axi_awaddr;
  wire [               1:0] ddr_axi_awburst;
  wire [               3:0] ddr_axi_awcache;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_awid;
  wire [               7:0] ddr_axi_awlen;
  wire                      ddr_axi_awlock;
  wire [               2:0] ddr_axi_awprot;
  wire [               3:0] ddr_axi_awqos;
  wire                      ddr_axi_awready;
  wire [               2:0] ddr_axi_awsize;
  wire                      ddr_axi_awvalid;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_bid;
  wire                      ddr_axi_bready;
  wire [               1:0] ddr_axi_bresp;
  wire                      ddr_axi_bvalid;
  wire [AXI_DATA_WIDTH-1:0] ddr_axi_rdata;
  wire [  AXI_ID_WIDTH-1:0] ddr_axi_rid;
  wire                      ddr_axi_rlast;
  wire                      ddr_axi_rready;
  wire [               1:0] ddr_axi_rresp;
  wire                      ddr_axi_rvalid;
  wire [AXI_DATA_WIDTH-1:0] ddr_axi_wdata;
  wire                      ddr_axi_wlast;
  wire                      ddr_axi_wready;
  wire [AXI_STRB_WIDTH-1:0] ddr_axi_wstrb;
  wire                      ddr_axi_wvalid;

  // Tie off AXI master signals to MIG (no transactions - using svc_axi_mem instead)
  assign ddr_axi_arvalid = 1'b0;
  assign ddr_axi_araddr  = {AXI_ADDR_WIDTH{1'b0}};
  assign ddr_axi_arburst = 2'b01;
  assign ddr_axi_arcache = 4'b0000;
  assign ddr_axi_arid    = {AXI_ID_WIDTH{1'b0}};
  assign ddr_axi_arlen   = 8'd0;
  assign ddr_axi_arlock  = 1'b0;
  assign ddr_axi_arprot  = 3'd0;
  assign ddr_axi_arqos   = 4'd0;
  assign ddr_axi_arsize  = 3'd4;

  assign ddr_axi_awvalid = 1'b0;
  assign ddr_axi_awaddr  = {AXI_ADDR_WIDTH{1'b0}};
  assign ddr_axi_awburst = 2'b01;
  assign ddr_axi_awcache = 4'b0000;
  assign ddr_axi_awid    = {AXI_ID_WIDTH{1'b0}};
  assign ddr_axi_awlen   = 8'd0;
  assign ddr_axi_awlock  = 1'b0;
  assign ddr_axi_awprot  = 3'd0;
  assign ddr_axi_awqos   = 4'd0;
  assign ddr_axi_awsize  = 3'd4;

  assign ddr_axi_wvalid  = 1'b0;
  assign ddr_axi_wdata   = {AXI_DATA_WIDTH{1'b0}};
  assign ddr_axi_wstrb   = {AXI_STRB_WIDTH{1'b0}};
  assign ddr_axi_wlast   = 1'b0;

  assign ddr_axi_rready  = 1'b0;
  assign ddr_axi_bready  = 1'b0;

  //
  // SoC I/O signals
  //
  logic                      io_ren;
  logic [              31:0] io_raddr;
  logic [              31:0] io_rdata;
  logic                      io_wen;
  logic [              31:0] io_waddr;
  logic [              31:0] io_wdata;
  logic [               3:0] io_wstrb;

  //
  // AXI signals from SoC cache to backing memory
  //
  logic                      m_axi_arvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_arid;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic [               7:0] m_axi_arlen;
  logic [               2:0] m_axi_arsize;
  logic [               1:0] m_axi_arburst;
  logic                      m_axi_arready;

  logic                      m_axi_rvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_rid;
  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic [               1:0] m_axi_rresp;
  logic                      m_axi_rlast;
  logic                      m_axi_rready;

  logic                      m_axi_awvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_awid;
  logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic [               7:0] m_axi_awlen;
  logic [               2:0] m_axi_awsize;
  logic [               1:0] m_axi_awburst;
  logic                      m_axi_awready;

  logic                      m_axi_wvalid;
  logic [AXI_DATA_WIDTH-1:0] m_axi_wdata;
  logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb;
  logic                      m_axi_wlast;
  logic                      m_axi_wready;

  logic                      m_axi_bvalid;
  logic [  AXI_ID_WIDTH-1:0] m_axi_bid;
  logic [               1:0] m_axi_bresp;
  logic                      m_axi_bready;

  //
  // RISC-V SoC with BRAM cache
  //
  // IMEM: BRAM initialized with coremark program
  // DMEM: Cache backed by svc_axi_mem (will convert to MIG later)
  //
  svc_rv_soc_bram_cache #(
      .XLEN            (32),
      .IMEM_DEPTH      (8704),
      .PIPELINED       (1),
      .FWD_REGFILE     (1),
      .FWD             (1),
      .BPRED           (1),
      .BTB_ENABLE      (1),
      .BTB_ENTRIES     (64),
      .RAS_ENABLE      (1),
      .RAS_DEPTH       (8),
      .EXT_ZMMUL       (0),
      .EXT_M           (1),
      .PC_REG          (1),
      .IMEM_INIT       ("../../../.build/sw/rv32im/coremark/coremark.hex"),
      .CACHE_SIZE_BYTES(4096),
      .CACHE_LINE_BYTES(32),
      .CACHE_TWO_WAY   (0),
      .AXI_ADDR_WIDTH  (AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH  (AXI_DATA_WIDTH),
      .AXI_ID_WIDTH    (AXI_ID_WIDTH)
  ) soc (
      .clk  (clk),
      .rst_n(rst_n),

      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),

      .m_axi_arvalid(m_axi_arvalid),
      .m_axi_arid   (m_axi_arid),
      .m_axi_araddr (m_axi_araddr),
      .m_axi_arlen  (m_axi_arlen),
      .m_axi_arsize (m_axi_arsize),
      .m_axi_arburst(m_axi_arburst),
      .m_axi_arready(m_axi_arready),

      .m_axi_rvalid(m_axi_rvalid),
      .m_axi_rid   (m_axi_rid),
      .m_axi_rdata (m_axi_rdata),
      .m_axi_rresp (m_axi_rresp),
      .m_axi_rlast (m_axi_rlast),
      .m_axi_rready(m_axi_rready),

      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),

      .m_axi_wvalid(m_axi_wvalid),
      .m_axi_wdata (m_axi_wdata),
      .m_axi_wstrb (m_axi_wstrb),
      .m_axi_wlast (m_axi_wlast),
      .m_axi_wready(m_axi_wready),

      .m_axi_bvalid(m_axi_bvalid),
      .m_axi_bid   (m_axi_bid),
      .m_axi_bresp (m_axi_bresp),
      .m_axi_bready(m_axi_bready),

      .ebreak(ebreak),
      .trap  ()
  );

  //
  // AXI memory backing store for data cache
  //
  // 17-bit address = 128KB with 128-bit data width
  //
  svc_axi_mem #(
      .AXI_ADDR_WIDTH(17),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH),
      .INIT_FILE     ("../../../.build/sw/rv32im/coremark/coremark_128.hex")
  ) axi_dmem (
      .clk  (clk),
      .rst_n(rst_n),

      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_arid   (m_axi_arid),
      .s_axi_araddr (m_axi_araddr[16:0]),
      .s_axi_arlen  (m_axi_arlen),
      .s_axi_arsize (m_axi_arsize),
      .s_axi_arburst(m_axi_arburst),
      .s_axi_arready(m_axi_arready),

      .s_axi_rvalid(m_axi_rvalid),
      .s_axi_rid   (m_axi_rid),
      .s_axi_rdata (m_axi_rdata),
      .s_axi_rresp (m_axi_rresp),
      .s_axi_rlast (m_axi_rlast),
      .s_axi_rready(m_axi_rready),

      .s_axi_awvalid(m_axi_awvalid),
      .s_axi_awid   (m_axi_awid),
      .s_axi_awaddr (m_axi_awaddr[16:0]),
      .s_axi_awlen  (m_axi_awlen),
      .s_axi_awsize (m_axi_awsize),
      .s_axi_awburst(m_axi_awburst),
      .s_axi_awready(m_axi_awready),

      .s_axi_wvalid(m_axi_wvalid),
      .s_axi_wdata (m_axi_wdata),
      .s_axi_wstrb (m_axi_wstrb),
      .s_axi_wlast (m_axi_wlast),
      .s_axi_wready(m_axi_wready),

      .s_axi_bvalid(m_axi_bvalid),
      .s_axi_bid   (m_axi_bid),
      .s_axi_bresp (m_axi_bresp),
      .s_axi_bready(m_axi_bready)
  );

  //
  // I/O register bank with UART
  //
  svc_soc_io_reg #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .MEM_TYPE  (1)
  ) io_regs (
      .clk     (clk),
      .rst_n   (rst_n),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),
      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .led     (sw_led),
      .gpio    (),
      .uart_tx (UART_TX)
  );

  //
  // MIG block design (for clock generation; DDR3 not used yet)
  //
  arty_s7_rv_coremark_axi_bd arty_s7_rv_coremark_axi_bd_i (
      .s_axi_araddr       (ddr_axi_araddr),
      .s_axi_arburst      (ddr_axi_arburst),
      .s_axi_arcache      (ddr_axi_arcache),
      .s_axi_arid         (ddr_axi_arid),
      .s_axi_arlen        (ddr_axi_arlen),
      .s_axi_arlock       (ddr_axi_arlock),
      .s_axi_arprot       (ddr_axi_arprot),
      .s_axi_arqos        (ddr_axi_arqos),
      .s_axi_arready      (ddr_axi_arready),
      .s_axi_arsize       (ddr_axi_arsize),
      .s_axi_arvalid      (ddr_axi_arvalid),
      .s_axi_awaddr       (ddr_axi_awaddr),
      .s_axi_awburst      (ddr_axi_awburst),
      .s_axi_awcache      (ddr_axi_awcache),
      .s_axi_awid         (ddr_axi_awid),
      .s_axi_awlen        (ddr_axi_awlen),
      .s_axi_awlock       (ddr_axi_awlock),
      .s_axi_awprot       (ddr_axi_awprot),
      .s_axi_awqos        (ddr_axi_awqos),
      .s_axi_awready      (ddr_axi_awready),
      .s_axi_awsize       (ddr_axi_awsize),
      .s_axi_awvalid      (ddr_axi_awvalid),
      .s_axi_bid          (ddr_axi_bid),
      .s_axi_bready       (ddr_axi_bready),
      .s_axi_bresp        (ddr_axi_bresp),
      .s_axi_bvalid       (ddr_axi_bvalid),
      .s_axi_rdata        (ddr_axi_rdata),
      .s_axi_rid          (ddr_axi_rid),
      .s_axi_rlast        (ddr_axi_rlast),
      .s_axi_rready       (ddr_axi_rready),
      .s_axi_rresp        (ddr_axi_rresp),
      .s_axi_rvalid       (ddr_axi_rvalid),
      .s_axi_wdata        (ddr_axi_wdata),
      .s_axi_wlast        (ddr_axi_wlast),
      .s_axi_wready       (ddr_axi_wready),
      .s_axi_wstrb        (ddr_axi_wstrb),
      .s_axi_wvalid       (ddr_axi_wvalid),
      .aresetn            (rst_n),
      .ddr3_addr          (ddr3_addr),
      .ddr3_ba            (ddr3_ba),
      .ddr3_cas_n         (ddr3_cas_n),
      .ddr3_ck_n          (ddr3_ck_n),
      .ddr3_ck_p          (ddr3_ck_p),
      .ddr3_cke           (ddr3_cke),
      .ddr3_cs_n          (ddr3_cs_n),
      .ddr3_dm            (ddr3_dm),
      .ddr3_dq            (ddr3_dq),
      .ddr3_dqs_n         (ddr3_dqs_n),
      .ddr3_dqs_p         (ddr3_dqs_p),
      .ddr3_odt           (ddr3_odt),
      .ddr3_ras_n         (ddr3_ras_n),
      .ddr3_reset_n       (ddr3_reset_n),
      .ddr3_we_n          (ddr3_we_n),
      .init_calib_complete(init_calib_complete),
      .mmcm_locked        (mmcm_locked),
      .reset              (reset),
      .clk_100            (CLK100MHZ),
      .ui_clk             (clk),
      .ui_clk_rst         (ui_clk_rst)
  );

endmodule
