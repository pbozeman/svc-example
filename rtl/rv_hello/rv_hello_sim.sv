`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V hello world demo
//
// Architecture-generic: hex file path set by Makefile via RV_HELLO_HEX define
//
// Usage:
//   make sw
//   make rv_hello_i_sim      # RV32I variant
//   make rv_hello_im_sim     # RV32IM variant
//
`ifndef RV_HELLO_HEX
`define RV_HELLO_HEX ".build/sw/rv32i/hello/hello.hex"
`endif

module rv_hello_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 1_000_000;


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_DEPTH     (4096),
      .DMEM_DEPTH     (1024),
      .IMEM_INIT      (`RV_HELLO_HEX),
      .DMEM_INIT      (`RV_HELLO_HEX),
      .BAUD_RATE      (115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX         ("hello"),
      .SW_PATH        ("sw/hello/main.c")
  ) sim (
      .clk    (),
      .rst_n  (),
      .uart_tx(),
      .led    (),
      .gpio   (),
      .done   ()
  );

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_hello_sim.vcd");
  //   $dumpvars(0, rv_hello_sim);
  // end

endmodule
