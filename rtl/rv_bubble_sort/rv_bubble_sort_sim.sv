`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V bubble sort demo
//
// Architecture-generic: hex file path set by Makefile via RV_BUBBLE_SORT_HEX define
//
// Usage:
//   make sw
//   make rv_bubble_sort_i_sim      # RV32I variant
//   make rv_bubble_sort_im_sim     # RV32IM variant
//
`ifndef RV_BUBBLE_SORT_HEX
`define RV_BUBBLE_SORT_HEX ".build/sw/rv32i/bubble_sort/bubble_sort.hex"
`endif

module rv_bubble_sort_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 500_000;  // 20ms at 25MHz


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_DEPTH     (4096),
      .DMEM_DEPTH     (1024),
      .IMEM_INIT      (`RV_BUBBLE_SORT_HEX),
      .DMEM_INIT      (`RV_BUBBLE_SORT_HEX),
      .BAUD_RATE      (115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX         ("bubble"),
      .SW_PATH        ("sw/bubble_sort/main.c")
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
  //   $dumpfile("rv_bubble_sort_sim.vcd");
  //   $dumpvars(0, rv_bubble_sort_sim);
  // end

endmodule
