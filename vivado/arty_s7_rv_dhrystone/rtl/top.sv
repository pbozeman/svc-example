`include "svc.sv"

`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

module top (
    input  wire       CLK100MHZ,
    input  wire       reset,
    output wire [3:0] led,
    output wire       UART_TX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  wire clk = CLK100MHZ;
  wire rst_n = reset;

  wire ebreak;

  assign led[3] = reset;
  assign led[2] = ebreak;
  assign led[1] = 1'b0;
  assign led[0] = 1'b0;

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
      .FWD        (0),
      .BPRED      (0),
      .BTB_ENABLE (0),
      .BTB_ENTRIES(8),
      .EXT_ZMMUL  (0),
      .EXT_M      (0),
      .IMEM_INIT  ("../../../.build/sw/rv32i/dhrystone/dhrystone.hex"),
      .DMEM_INIT  ("../../../.build/sw/rv32i/dhrystone/dhrystone.hex")
  ) soc (
      .clk     (clk),
      .rst_n   (rst_n),
      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),
      .ebreak  (ebreak)
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

endmodule
