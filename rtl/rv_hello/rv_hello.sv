`ifndef RV_HELLO_SV
`define RV_HELLO_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

//
// RISC-V hello world demo
//
// Runs software from sw/hello/main.c which prints "Hello, World!" via UART
//
module rv_hello #(
    parameter CLOCK_FREQ = 25_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input logic clk,
    input logic rst_n,

    output logic uart_tx,
    output logic ebreak
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
  // Instantiate the RISC-V SoC with hello program
  //
  // Note: Both IMEM and DMEM initialized with same hex file
  // This allows program to read .rodata constants from DMEM
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_DEPTH (4096),
      .DMEM_DEPTH (1024),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (0),
      .BPRED      (0),
      .IMEM_INIT  (".build/sw/hello/hello.hex"),
      .DMEM_INIT  (".build/sw/hello/hello.hex")
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
      .BAUD_RATE (BAUD_RATE)
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
      .uart_tx (uart_tx)
  );


endmodule

`endif
