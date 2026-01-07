`include "svc.sv"

`include "svc_rv_soc_bram.sv"
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

  assign rst_n  = !ui_clk_rst;

  assign led[3] = mmcm_locked;
  assign led[2] = init_calib_complete;
  assign led[1] = ebreak;
  assign led[0] = 1'b0;

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

  // Tie off AXI master signals (no transactions)
  assign ddr_axi_arvalid = 1'b0;
  assign ddr_axi_araddr  = {AXI_ADDR_WIDTH{1'b0}};
  assign ddr_axi_arburst = 2'b01;  // INCR
  assign ddr_axi_arcache = 4'b0000;
  assign ddr_axi_arid    = {AXI_ID_WIDTH{1'b0}};
  assign ddr_axi_arlen   = 8'd0;
  assign ddr_axi_arlock  = 1'b0;
  assign ddr_axi_arprot  = 3'd0;
  assign ddr_axi_arqos   = 4'd0;
  assign ddr_axi_arsize  = 3'd4;  // 16 bytes

  assign ddr_axi_awvalid = 1'b0;
  assign ddr_axi_awaddr  = {AXI_ADDR_WIDTH{1'b0}};
  assign ddr_axi_awburst = 2'b01;  // INCR
  assign ddr_axi_awcache = 4'b0000;
  assign ddr_axi_awid    = {AXI_ID_WIDTH{1'b0}};
  assign ddr_axi_awlen   = 8'd0;
  assign ddr_axi_awlock  = 1'b0;
  assign ddr_axi_awprot  = 3'd0;
  assign ddr_axi_awqos   = 4'd0;
  assign ddr_axi_awsize  = 3'd4;  // 16 bytes

  assign ddr_axi_wvalid  = 1'b0;
  assign ddr_axi_wdata   = {AXI_DATA_WIDTH{1'b0}};
  assign ddr_axi_wstrb   = {AXI_STRB_WIDTH{1'b0}};
  assign ddr_axi_wlast   = 1'b0;

  assign ddr_axi_rready  = 1'b0;
  assign ddr_axi_bready  = 1'b0;

  //
  // SoC I/O signals
  //
  logic        io_ren;
  logic [31:0] io_raddr;
  logic [31:0] io_rdata;
  logic        io_wen;
  logic [31:0] io_waddr;
  logic [31:0] io_wdata;
  logic [ 3:0] io_wstrb;

  //
  // Instantiate the RISC-V SoC with dhrystone program
  //
  // Note: Paths are relative to Vivado working directory
  // (vivado/arty_s7_rv_dhrystone/vivado/)
  // Both IMEM and DMEM initialized with same hex file
  // This allows program to read .rodata constants from DMEM
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_DEPTH (2560),
      .DMEM_DEPTH (6144),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (1),
      .BPRED      (1),
      .BTB_ENABLE (1),
      .BTB_ENTRIES(64),
      .RAS_ENABLE (1),
      .RAS_DEPTH  (8),
      .EXT_ZMMUL  (0),
      .EXT_M      (1),
      .PC_REG     (0),
      .IMEM_INIT  ("../../../.build/sw/rv32im/dhrystone/dhrystone.hex"),
      .DMEM_INIT  ("../../../.build/sw/rv32im/dhrystone/dhrystone.hex")
  ) soc (
      .clk          (clk),
      .rst_n        (rst_n),
      .dbg_urx_valid(1'b0),
      .dbg_urx_data (8'h0),
      .dbg_urx_ready(),
      .dbg_utx_valid(),
      .dbg_utx_data (),
      .dbg_utx_ready(1'b1),
      .io_ren       (io_ren),
      .io_raddr     (io_raddr),
      .io_rdata     (io_rdata),
      .io_wen       (io_wen),
      .io_waddr     (io_waddr),
      .io_wdata     (io_wdata),
      .io_wstrb     (io_wstrb),
      .ebreak       (ebreak),
      .trap         ()
  );

  //
  // Instantiate the I/O register bank with UART
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
      .led     (),
      .gpio    (),
      .uart_tx (UART_TX)
  );

  //
  // Instantiate the MIG block design
  //
  arty_s7_rv_dhrystone_bd arty_s7_rv_dhrystone_bd_i (
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
