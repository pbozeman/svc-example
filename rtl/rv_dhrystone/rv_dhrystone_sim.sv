`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V Dhrystone benchmark
//
// Architecture-generic: hex file path set by Makefile via RV_DHRYSTONE_HEX define
//
// Usage:
//   make sw
//   make rv_dhrystone_i_sim        # RV32I variant
//   make rv_dhrystone_im_sim       # RV32IM variant
//   make rv_dhrystone_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
`ifndef RV_DHRYSTONE_HEX
`define RV_DHRYSTONE_HEX ".build/sw/rv32i/dhrystone/dhrystone.hex"
`endif

`ifdef RV_ARCH_ZMMUL
`define EXT_ZMMUL_VAL 1
`else
`define EXT_ZMMUL_VAL 0
`endif

module rv_dhrystone_sim;
  //
  // Simulation parameters
  //
  localparam
      int WATCHDOG_CYCLES = 100_000_000;  // 100M cycles for full benchmark


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ(25),
      .IMEM_DEPTH(8192),  // 32KB for larger Dhrystone code
      .DMEM_DEPTH(4096),  // 16KB for Dhrystone globals + heap
      .EXT_ZMMUL(`EXT_ZMMUL_VAL),
      .IMEM_INIT(`RV_DHRYSTONE_HEX),
      .DMEM_INIT(`RV_DHRYSTONE_HEX),
      .BAUD_RATE(115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX("dhrystone"),
      .SW_PATH("sw/dhrystone/dhry_1.c")
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
  //   $dumpfile("rv_dhrystone_sim.vcd");
  //   $dumpvars(0, rv_dhrystone_sim);
  // end

endmodule
