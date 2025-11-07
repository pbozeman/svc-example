`ifndef RV_BUBBLE_SORT_SV
`define RV_BUBBLE_SORT_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

//
// RISC-V bubble sort demo
//
// Runs software from sw/bubble_sort/main.c which performs a bubble sort
//
module rv_bubble_sort #(
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
  // Instantiate the RISC-V SoC with bubble_sort program
  //
  // Note: Both IMEM and DMEM initialized with same hex file
  // This allows program to access data from DMEM
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_DEPTH (4096),
      .DMEM_DEPTH (1024),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (1),
      .BPRED      (1),
      .IMEM_INIT  (".build/sw/rv32i/bubble_sort/bubble_sort.hex"),
      .DMEM_INIT  (".build/sw/rv32i/bubble_sort/bubble_sort.hex")
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
