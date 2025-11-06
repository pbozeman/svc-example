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
// Usage example:
//   logic uart_tx, led, ebreak, done;
//   logic [7:0] gpio;
//   int cycle_count;
//   svc_soc_sim #(
//       .CLOCK_FREQ_MHZ(25),
//       .IMEM_INIT(".build/sw/hello/hello.hex"),
//       .WATCHDOG_CYCLES(500_000),
//       .TITLE("Hello World"),
//       .SW_PATH("sw/hello/main.c")
//   ) sim (
//       .clk(clk),
//       .rst_n(rst_n),
//       .uart_tx(uart_tx),
//       .led(led),
//       .gpio(gpio),
//       .ebreak(ebreak),
//       .done(done),
//       .cycle_count(cycle_count)
//   );

module svc_soc_sim #(
    // Clock and reset
    parameter CLOCK_FREQ_MHZ = 100,
    parameter RESET_CYCLES   = 10,

    // CPU configuration
    parameter XLEN        = 32,
    parameter IMEM_AW     = 12,
    parameter DMEM_AW     = 10,
    parameter PIPELINED   = 1,
    parameter FWD_REGFILE = 1,
    parameter FWD         = 1,
    parameter BPRED       = 1,
    parameter IMEM_INIT   = "",
    parameter DMEM_INIT   = "",
    parameter BAUD_RATE   = 115_200,

    // Simulation control
    parameter int WATCHDOG_CYCLES = 100000,

    // Banner configuration
    parameter TITLE       = "",
    parameter SW_PATH     = "",
    parameter DESCRIPTION = ""
) (
    output logic       clk,
    output logic       rst_n,
    output logic       uart_tx,
    output logic       led,
    output logic [7:0] gpio,
    output logic       done
);

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
      .PRINT_RX  (1)
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
      .IMEM_AW    (IMEM_AW),
      .DMEM_AW    (DMEM_AW),
      .PIPELINED  (PIPELINED),
      .FWD_REGFILE(FWD_REGFILE),
      .FWD        (FWD),
      .BPRED      (BPRED),
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

  assign done = timeout || ebreak;

  //
  // Pipeline execution monitoring
  // (optional, controlled by SVC_CPU_DBG runtime flag)
  //
  `include "svc_rv_dasm.svh"

  logic cpu_dbg_enabled;

  initial begin
    if ($test$plusargs("SVC_CPU_DBG")) begin
      cpu_dbg_enabled = 1'b1;
    end else begin
      cpu_dbg_enabled = 1'b0;
    end
  end

  always @(posedge clk) begin
    if (rst_n && cpu_dbg_enabled) begin
      $display("[%12t] %-4s %08x  %-28s  %08x %08x -> %08x", $time, "",
               bram_cpu.cpu.pc_ex, dasm_inst(bram_cpu.cpu.instr_ex),
               bram_cpu.cpu.alu_a_ex, bram_cpu.cpu.alu_b_ex,
               bram_cpu.cpu.alu_result_ex);

      if (io_ren) begin
        $display("[%12t] %-4s %08x  %-28s  %08x %8s -> %08x", $time, "MR:",
                 bram_cpu.cpu.pc_plus4_mem - 4, "",
                 bram_cpu.cpu.alu_result_mem, "", io_rdata);
      end else if (io_wen) begin
        $display("[%12t] %-4s %08x  %-28s  %08x %8s -> %08x", $time, "MW:",
                 bram_cpu.cpu.pc_plus4_mem - 4, "",
                 bram_cpu.cpu.alu_result_mem, "", io_wdata);
      end
    end
  end

  //
  // Banner and lifecycle management (optional)
  //
  if (WATCHDOG_CYCLES > 0) begin : gen_lifecycle
    initial begin
      string sep;

      // Wait for reset to complete
      wait (rst_n);

      // Build separator string
      sep = {80{"="}};

      // Print banner
      $display("");
      if (TITLE != "") begin
        $display("=== RISC-V %s Simulation ===", TITLE);
      end else begin
        $display("=== Simulation ===");
      end

      if (SW_PATH != "") begin
        $display("Running software from %s", SW_PATH);
      end

      if (CLOCK_FREQ_MHZ > 0) begin
        $display("Clock frequency: %0d MHz", CLOCK_FREQ_MHZ);
      end

      if (BAUD_RATE > 0) begin
        $display("UART baud rate: %0d", BAUD_RATE);
      end

      if (DESCRIPTION != "") begin
        $display("%s", DESCRIPTION);
      end

      $display("Will run for %0d cycles", WATCHDOG_CYCLES);
      $display("%s", sep);

      // Wait for completion
      wait (done);

      // Print completion report
      $display("%s", sep);
      if (timeout) begin
        $display("Reason: timeout");
      end else begin
        $display("Reason: ebreak");
      end

      $display("Cycles: %0d", cycle_count);
      $display("");

      $finish(0);
    end
  end

endmodule

`endif
