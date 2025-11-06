`include "svc.sv"

`include "svc_rv_soc_bram.sv"
`include "svc_soc_sim_uart.sv"

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
  // Instantiate RISC-V SoC with BRAM memory
  //
  svc_rv_soc_bram #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE(BAUD_RATE),
      .IMEM_DEPTH(4096),  // 16KB instruction memory
      .DMEM_DEPTH(4096),  // 16KB data memory (for Dhrystone-sized heap)
      .IMEM_INIT(".build/sw/lib_test/lib_test.hex"),
      .DMEM_INIT(".build/sw/lib_test/lib_test.hex")
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
