`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V libsvc test suite
//
// Architecture-generic: hex file path set by Makefile via RV_LIB_TEST_HEX define
//
// Usage:
//   make sw
//   make rv_lib_test_i_sim      # RV32I variant
//   make rv_lib_test_im_sim     # RV32IM variant
//
`ifndef RV_LIB_TEST_HEX
`define RV_LIB_TEST_HEX ".build/sw/rv32i/lib_test/lib_test.hex"
`endif

module rv_lib_test_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 2_000_000;  // Increased for malloc tests


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_DEPTH     (4096),
      .DMEM_DEPTH     (4096),                 // 16KB for Dhrystone-sized heap
      .IMEM_INIT      (`RV_LIB_TEST_HEX),
      .DMEM_INIT      (`RV_LIB_TEST_HEX),
      .BAUD_RATE      (115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX         ("lib_test"),
      .SW_PATH        ("sw/lib_test/main.c")
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
  //   $dumpfile("rv_lib_test_sim.vcd");
  //   $dumpvars(0, rv_lib_test_sim);
  // end

endmodule
