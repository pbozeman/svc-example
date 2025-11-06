`ifndef RV_BLINKY_SV
`define RV_BLINKY_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

//
// RISC-V blinky demo
//
// Runs software from sw/blinky/main.c which toggles an LED via MMIO writes
//
module rv_blinky (
    input logic clk,
    input logic rst_n,

    output logic       led,
    output logic [7:0] gpio,
    output logic       ebreak
);

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
  // Instantiate the RISC-V SoC with blinky program
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_DEPTH (1024),
      .DMEM_DEPTH (1024),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (0),
      .BPRED      (0),
      .IMEM_INIT  (".build/sw/blinky/blinky.hex")
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
  // UART TX (unused in blinky, but svc_soc_io_reg instantiates it)
  //
  logic uart_tx_unused;

  //
  // Instantiate the I/O register bank
  //
  svc_soc_io_reg io_regs (
      .clk     (clk),
      .rst_n   (rst_n),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),
      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .led     (led),
      .gpio    (gpio),
      .uart_tx (uart_tx_unused)
  );

endmodule

`endif
