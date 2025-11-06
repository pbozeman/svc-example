`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V hello world demo
//
// Usage:
//   make sw
//   make rv_hello_sim
//
module rv_hello_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 500_000;  // 20ms at 25MHz


  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_AW        (12),
      .DMEM_AW        (10),
      .IMEM_INIT      (".build/sw/hello/hello.hex"),
      .DMEM_INIT      (".build/sw/hello/hello.hex"),
      .BAUD_RATE      (115_200),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .TITLE          ("Hello World"),
      .SW_PATH        ("sw/hello/main.c"),
      .DESCRIPTION    ("Watching UART output...")
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
