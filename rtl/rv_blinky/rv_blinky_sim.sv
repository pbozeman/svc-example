`include "svc.sv"

`include "svc_soc_sim.sv"

//
// Standalone interactive simulation for RISC-V blinky demo
//
// Architecture-generic: hex file path set by Makefile via RV_BLINKY_HEX define
//
// Usage:
//   make sw
//   make rv_blinky_i_sim        # RV32I variant
//   make rv_blinky_im_sim       # RV32IM variant
//   make rv_blinky_i_zmmul_sim  # RV32I_Zmmul variant (hardware multiply)
//
`ifndef RV_BLINKY_HEX
`define RV_BLINKY_HEX ".build/sw/rv32i/blinky/blinky.hex"
`endif

`ifdef RV_ARCH_ZMMUL
`define EXT_ZMMUL_VAL 1
`else
`define EXT_ZMMUL_VAL 0
`endif

module rv_blinky_sim;
  //
  // Simulation parameters
  //
  localparam int WATCHDOG_CYCLES = 100000;

  //
  // Signals
  //
  logic       clk;
  logic       rst_n;
  logic       uart_tx_unused;
  logic       led;
  logic [7:0] gpio;
  logic       done;

  //
  // SOC simulation with CPU, peripherals, and lifecycle management
  //
  svc_soc_sim #(
      .CLOCK_FREQ_MHZ (25),
      .IMEM_DEPTH     (1024),
      .DMEM_DEPTH     (1024),
      .EXT_ZMMUL      (`EXT_ZMMUL_VAL),
      .IMEM_INIT      (`RV_BLINKY_HEX),
      .WATCHDOG_CYCLES(WATCHDOG_CYCLES),
      .PREFIX         ("blinky"),
      .SW_PATH        ("sw/blinky/main.c")
  ) sim (
      .clk    (clk),
      .rst_n  (rst_n),
      .uart_tx(uart_tx_unused),
      .led    (led),
      .gpio   (gpio),
      .done   (done)
  );

  //
  // Monitor LED changes
  //
  logic led_prev;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      led_prev <= 1'b0;
    end else begin
      led_prev <= led;
    end
  end

  //
  // Build prefix for local displays
  //
  string P;

  initial begin
    if ($test$plusargs("SVC_SIM_PREFIX")) begin
      P = $sformatf("%-8s", "blinky:");
    end else begin
      P = "";
    end
  end

  always @(posedge clk) begin
    if (rst_n && led != led_prev) begin
      $display("%s[%0t] LED changed: %b -> %b", P, $time, led_prev, led);
    end
  end

  //
  // Debug: Count data memory writes
  //
  int dmem_write_count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      dmem_write_count <= 0;
    end else if (sim.bram_cpu.dmem_wen) begin
      dmem_write_count <= dmem_write_count + 1;
    end
  end

  //
  // Additional statistics reporting on completion
  //
  initial begin
    wait (done);
    $display("%sFinal LED state: %b", P, led);
    $display("%sFinal GPIO state: 0x%02x", P, gpio);
    $display("%sData mem writes seen: %0d", P, dmem_write_count);
  end

  //
  // Optional: Generate VCD for waveform viewing
  //
  // initial begin
  //   $dumpfile("rv_blinky_sim.vcd");
  //   $dumpvars(0, rv_blinky_sim);
  // end

endmodule
