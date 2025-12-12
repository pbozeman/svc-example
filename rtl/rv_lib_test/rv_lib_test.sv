`ifndef RV_LIB_TEST_SV
`define RV_LIB_TEST_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"

//
// RISC-V lib_test - infrastructure test module
//
// Tests libsvc functions (CSR, string, malloc) in preparation for Dhrystone
//
module rv_lib_test #(
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
      .IMEM_DEPTH (4096),
      .DMEM_DEPTH (4096),
      .PIPELINED  (1),
      .FWD_REGFILE(1),
      .FWD        (0),
      .BPRED      (0),
      .PC_REG     (0),
      .IMEM_INIT  (".build/sw/rv32i/lib_test/lib_test.hex"),
      .DMEM_INIT  (".build/sw/rv32i/lib_test/lib_test.hex")
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
