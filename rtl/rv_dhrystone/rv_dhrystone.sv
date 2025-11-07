`include "svc.sv"

`include "svc_rv_soc_bram.sv"
`include "svc_soc_sim_uart.sv"

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
  // Instantiate RISC-V SoC with BRAM memory
  //
  svc_rv_soc_bram #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .IMEM_DEPTH(2560),
      .DMEM_DEPTH(4096),
      .IMEM_INIT (".build/sw/rv32i/dhrystone/dhrystone.hex"),
      .DMEM_INIT (".build/sw/rv32i/dhrystone/dhrystone.hex")
  ) soc (
      .clk     (clk),
      .rst_n   (rst_n),
      .uart_tx (uart_tx),
      .uart_rx (1'b1),
      .gpio_in (8'h00),
      .gpio_out(),
      .ebreak  (ebreak)
  );

endmodule
