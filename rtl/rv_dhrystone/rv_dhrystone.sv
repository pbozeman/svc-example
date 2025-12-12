`ifndef RV_DHRYSTONE_SV
`define RV_DHRYSTONE_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

//
// RISC-V Dhrystone benchmark module
//
// Runs Dhrystone 2.1 benchmark on bare-metal RISC-V with cycle counting
//
module rv_dhrystone #(
    parameter int CLOCK_FREQ = 100_000_000,
    parameter int BAUD_RATE  = 115_200
) (
    input  logic clk,
    input  logic rst_n,
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
  // Instantiate RISC-V SoC with BRAM memory
  //
  svc_rv_soc_bram #(
      .XLEN       (32),
      .IMEM_DEPTH (2560),
      .DMEM_DEPTH (4096),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (0),
      .BPRED      (0),
      .PC_REG     (0),
      .IMEM_INIT  (".build/sw/rv32i/dhrystone/dhrystone.hex"),
      .DMEM_INIT  (".build/sw/rv32i/dhrystone/dhrystone.hex")
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
      .ebreak  (ebreak),
      .trap    ()
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
      .uart_tx (uart_tx)
  );

endmodule

`endif
