`ifndef SVC_SOC_SIM_SV
`define SVC_SOC_SIM_SV

`include "svc.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"
`include "svc_soc_sim_uart.sv"

// SOC simulation infrastructure for RISC-V CPU demos
//
// Provides complete SOC simulation environment with:
// - Clock and reset generation
// - RISC-V CPU + BRAM memory + peripherals (UART, LED, GPIO)
// - UART terminal with console output
// - Watchdog timer and lifecycle management
// - Pipeline execution monitoring (optional via +SVC_CPU_DBG)
// - Banner and statistics reporting
//
module svc_soc_sim #(
    // Clock and reset
    parameter CLOCK_FREQ_MHZ = 100,
    parameter RESET_CYCLES   = 10,

    // CPU configuration
    parameter XLEN        = 32,
    parameter IMEM_DEPTH  = 4096,
    parameter DMEM_DEPTH  = 1024,
    parameter PIPELINED   = 1,
    parameter FWD_REGFILE = 1,
    parameter FWD         = 1,
    parameter BPRED       = 1,
    parameter EXT_ZMMUL   = 0,
    parameter EXT_M       = 0,
    parameter IMEM_INIT   = "",
    parameter DMEM_INIT   = "",
    parameter BAUD_RATE   = 115_200,

    // Simulation control
    parameter WATCHDOG_CYCLES = 100000,
    parameter PREFIX          = "",
    parameter SW_PATH         = ""
) (
    output logic       clk,
    output logic       rst_n,
    output logic       uart_tx,
    output logic       led,
    output logic [7:0] gpio,
    output logic       done
);

  //
  // Include RISC-V definitions for debug display
  //
  `include "svc_rv_defs.svh"

  // Calculate clock period and frequency
  localparam real CLOCK_PERIOD_NS = 1000.0 / CLOCK_FREQ_MHZ;
  localparam real HALF_PERIOD_NS = CLOCK_PERIOD_NS / 2.0;
  localparam int CLOCK_FREQ = CLOCK_FREQ_MHZ * 1_000_000;

  //
  // Clock generation
  //
  initial clk = 0;
  always #(HALF_PERIOD_NS) clk = ~clk;

  //
  // Reset generation
  //
  initial begin
    rst_n = 0;
    #(CLOCK_PERIOD_NS * RESET_CYCLES);
    rst_n = 1;
  end

  //
  // UART terminal (always instantiated to monitor uart_tx)
  //
  logic urx_pin_unused;

  svc_soc_sim_uart #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .PRINT_RX  (1),
      .PREFIX    (PREFIX)
  ) uart_terminal (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(urx_pin_unused),
      .utx_pin(uart_tx)
  );

  //
  // SOC I/O signals
  //
  logic        io_ren;
  logic [31:0] io_raddr;
  logic [31:0] io_rdata;
  logic        io_wen;
  logic [31:0] io_waddr;
  logic [31:0] io_wdata;
  logic [ 3:0] io_wstrb;
  logic        ebreak;

  //
  // RISC-V CPU with BRAM memory
  //
  svc_rv_soc_bram #(
      .XLEN       (XLEN),
      .IMEM_DEPTH (IMEM_DEPTH),
      .DMEM_DEPTH (DMEM_DEPTH),
      .PIPELINED  (PIPELINED),
      .FWD_REGFILE(FWD_REGFILE),
      .FWD        (FWD),
      .BPRED      (BPRED),
      .EXT_ZMMUL  (EXT_ZMMUL),
      .EXT_M      (EXT_M),
      .IMEM_INIT  (IMEM_INIT),
      .DMEM_INIT  (DMEM_INIT)
  ) bram_cpu (
      .clk     (clk),
      .rst_n   (rst_n),
      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),
      .ebreak  (ebreak)
  );

  //
  // I/O register bank with peripherals (UART, LED, GPIO)
  //
  svc_soc_io_reg #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
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
      .led     (led),
      .gpio    (gpio),
      .uart_tx (uart_tx)
  );

  //
  // Cycle counter (always enabled)
  //
  int cycle_count;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      cycle_count <= 0;
    end else begin
      cycle_count <= cycle_count + 1;
    end
  end

  //
  // Watchdog timer (optional)
  //
  logic timeout;

  if (WATCHDOG_CYCLES > 0) begin : gen_watchdog
    always_ff @(posedge clk) begin
      if (!rst_n) begin
        timeout <= 1'b0;
      end else begin
        if (cycle_count >= WATCHDOG_CYCLES) begin
          timeout <= 1'b1;
        end
      end
    end
  end else begin : gen_no_watchdog
    assign timeout = 1'b0;
  end

  //
  // Banner and lifecycle management
  //
  initial begin
    string  sep;
    string  P;
    integer sim_prefix_enabled;

    done = 0;

    // Wait for reset to complete
    wait (rst_n);

    // Build separator string
    sep = {80{"="}};

    // Build prefix string
    if ($value$plusargs(
            "SVC_SIM_PREFIX=%d", sim_prefix_enabled
        ) && sim_prefix_enabled != 0 && PREFIX != "") begin
      P = $sformatf("%-8s", {PREFIX, ":"});
    end else begin
      P = "";
    end

    // Print banner
    $display("%s%s", P, sep);

    if (SW_PATH != "") begin
      $display("%smain:        %s", P, SW_PATH);
    end

    $display("%swatchdog:    %0d cycles", P, WATCHDOG_CYCLES);

    // reach all the way into the cpu to print these to ensure we didn't
    // drop params along the way
    $display("%sPIPELINED:   %0d", P, bram_cpu.cpu.PIPELINED);
    $display("%sFWD_REGFILE: %0d", P, bram_cpu.cpu.FWD_REGFILE);
    $display("%sFWD:         %0d", P, bram_cpu.cpu.FWD);
    $display("%sBPRED:       %0d", P, bram_cpu.cpu.BPRED);
    $display("%sEXT_ZMMUL:   %0d", P, bram_cpu.cpu.EXT_ZMMUL);
    $display("%sEXT_M:       %0d", P, bram_cpu.cpu.EXT_M);
    $display("%s%s", P, sep);

    // Wait for completion
    wait (timeout || ebreak);

    // Print completion report
    $display("%s%s", P, sep);

    if (timeout) begin
      $display("%sreason: timeout", P);
    end else begin
      $display("%sreason: ebreak", P);
    end

    $display("%scycles: %0d", P, cycle_count);

    //
    // CPI reporting
    //
    begin
      logic [31:0] cycles;
      logic [31:0] instrs;
      real         cpi;

      cycles = bram_cpu.cpu.stage_ex.csr.cycle;
      instrs = bram_cpu.cpu.stage_ex.csr.instret;
      cpi    = real'(cycles) / real'(instrs);

      $display("%sinstrs: %0d", P, instrs);
      $display("%scpi:    %f", P, cpi);
    end

    done = 1;
    $finish(0);
  end

endmodule

`endif
