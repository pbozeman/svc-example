`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V libsvc test suite
//
// Architecture-generic: hex file path set by Makefile via RV_LIB_TEST_HEX define
//
// Usage:
//   make sw
//   make rv_lib_test_i_sim        # RV32I variant
//   make rv_lib_test_im_sim       # RV32IM variant
//   make rv_lib_test_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
`ifndef RV_LIB_TEST_HEX
`define RV_LIB_TEST_HEX ".build/sw/rv32i/lib_test/lib_test.hex"
`endif

`ifdef RV_ARCH_ZMMUL
`define EXT_ZMMUL_VAL 1
`else
`define EXT_ZMMUL_VAL 0
`endif

`ifdef RV_ARCH_M
`define EXT_M_VAL 1
`else
`define EXT_M_VAL 0
`endif

`ifdef SVC_MEM_SRAM
`define MEM_TYPE_VAL 0
`else
`define MEM_TYPE_VAL 1
`endif

`ifdef SVC_CPU_SINGLE_CYCLE
`define PIPELINED_VAL 0
`else
`define PIPELINED_VAL 1
`endif

`ifndef RV_IMEM_DEPTH
`define RV_IMEM_DEPTH 4096
`endif

`ifndef RV_DMEM_DEPTH
`define RV_DMEM_DEPTH 4096
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
      .IMEM_DEPTH     (`RV_IMEM_DEPTH),
      .DMEM_DEPTH     (`RV_DMEM_DEPTH),
      .MEM_TYPE       (`MEM_TYPE_VAL),
      .PIPELINED      (`PIPELINED_VAL),
      .EXT_ZMMUL      (`EXT_ZMMUL_VAL),
      .EXT_M          (`EXT_M_VAL),
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
