`ifndef SVC_SOC_SIM_SV
`define SVC_SOC_SIM_SV

`include "svc.sv"
`include "svc_axi_mem.sv"
`include "svc_rv_soc_bram.sv"
`include "svc_rv_soc_bram_cache.sv"
`include "svc_rv_soc_sram.sv"
`include "svc_soc_io_reg.sv"
`include "svc_soc_sim_uart.sv"

// SOC simulation infrastructure for RISC-V CPU demos
//
// Provides complete SOC simulation environment with:
// - Clock and reset generation
// - RISC-V CPU + memory (BRAM/SRAM) + peripherals (UART, LED, GPIO)
// - UART terminal with console output
// - Watchdog timer and lifecycle management
// - Pipeline execution monitoring (optional debug flags):
//   +SVC_RV_DBG_CPU=1  - Enable all pipeline stage debug output
//   +SVC_RV_DBG_IF=1   - Instruction Fetch stage debug
//   +SVC_RV_DBG_ID=1   - Instruction Decode stage debug
//   +SVC_RV_DBG_EX=1   - Execute stage debug
//   +SVC_RV_DBG_MEM=1  - Memory stage debug
//   +SVC_RV_DBG_WB=1   - Write Back stage debug
//   +SVC_RV_DBG_HAZ=1  - Hazard detection debug
// - Banner and statistics reporting
//
// Memory type controlled by MEM_TYPE parameter (MEM_TYPE_BRAM or MEM_TYPE_SRAM)
//
//
// verilator lint_off: UNUSEDSIGNAL
// verilator lint_off: UNUSEDPARAM
module svc_soc_sim #(
    // Clock and reset
    parameter CLOCK_FREQ   = 100_000_000,
    parameter RESET_CYCLES = 10,

    // CPU configuration
    parameter     XLEN        = 32,
    parameter     IMEM_DEPTH  = 4096,
    parameter     DMEM_DEPTH  = 1024,
    parameter int MEM_TYPE    = 1,
    parameter     PIPELINED   = 1,
    parameter     FWD_REGFILE = 1,
    parameter     FWD         = 1,
    parameter     BPRED       = 1,
    parameter     BTB_ENABLE  = 1,
    parameter     BTB_ENTRIES = 64,
    parameter     RAS_ENABLE  = 1,
    parameter     RAS_DEPTH   = 8,
    parameter     EXT_ZMMUL   = 0,
    parameter     EXT_M       = 0,
    parameter     PC_REG      = 0,
    parameter     IMEM_INIT   = "",
    parameter     DMEM_INIT   = "",
    parameter     BAUD_RATE   = 115_200,

    // AXI parameters for BRAM_CACHE mode
    parameter int AXI_ADDR_WIDTH = 32,
    parameter int AXI_DATA_WIDTH = 128,
    parameter int AXI_ID_WIDTH   = 4,

    // Simulation control
    parameter WATCHDOG_CYCLES = 100000,
    parameter PREFIX          = "",
    parameter SW_PATH         = ""
) ();

  //
  // Internal signals (previously outputs)
  //
  logic       clk;
  logic       rst_n;
  logic       uart_tx;
  logic       led;
  logic [7:0] gpio;
  logic       done;

  //
  // Include RISC-V definitions for debug display
  //
  `include "svc_rv_defs.svh"

  // Calculate clock period from frequency
  localparam real CLOCK_PERIOD_NS = 1_000_000_000.0 / CLOCK_FREQ;
  localparam real HALF_PERIOD_NS = CLOCK_PERIOD_NS / 2.0;

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
  // UART terminal (always instantiated to monitor uart_tx and drive uart_rx)
  //
  logic uart_rx;

  svc_soc_sim_uart #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .PRINT_RX  (1),
      .PREFIX    (PREFIX)
  ) uart_terminal (
      .clk    (clk),
      .rst_n  (rst_n),
      .urx_pin(uart_rx),
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
  // For SRAM, generate io_ren from address (combinational reads always active)
  //
  if (MEM_TYPE == MEM_TYPE_SRAM) begin : sram_io_ren
    assign io_ren = 1'b1;
  end

  //
  // RISC-V CPU with memory (BRAM or SRAM based on MEM_TYPE)
  //
  if (MEM_TYPE == MEM_TYPE_SRAM) begin : sram_soc
    svc_rv_soc_sram #(
        .XLEN       (XLEN),
        .IMEM_DEPTH (IMEM_DEPTH),
        .DMEM_DEPTH (DMEM_DEPTH),
        .PIPELINED  (PIPELINED),
        .FWD_REGFILE(FWD_REGFILE),
        .FWD        (FWD),
        .BPRED      (BPRED),
        .BTB_ENABLE (BTB_ENABLE),
        .BTB_ENTRIES(BTB_ENTRIES),
        .RAS_ENABLE (RAS_ENABLE),
        .RAS_DEPTH  (RAS_DEPTH),
        .EXT_ZMMUL  (EXT_ZMMUL),
        .EXT_M      (EXT_M),
        .PC_REG     (PC_REG),
        .IMEM_INIT  (IMEM_INIT),
        .DMEM_INIT  (DMEM_INIT)
    ) rv_cpu (
        .clk     (clk),
        .rst_n   (rst_n),
        .io_raddr(io_raddr),
        .io_rdata(io_rdata),
        .io_wen  (io_wen),
        .io_waddr(io_waddr),
        .io_wdata(io_wdata),
        .io_wstrb(io_wstrb),
        .ebreak  (ebreak),
        .trap    ()
    );
  end else if (MEM_TYPE == MEM_TYPE_BRAM_CACHE) begin : cache_soc
    //
    // AXI signals for data memory backing store
    //
    logic                        m_axi_arvalid;
    logic [    AXI_ID_WIDTH-1:0] m_axi_arid;
    logic [  AXI_ADDR_WIDTH-1:0] m_axi_araddr;
    logic [                 7:0] m_axi_arlen;
    logic [                 2:0] m_axi_arsize;
    logic [                 1:0] m_axi_arburst;
    logic                        m_axi_arready;

    logic                        m_axi_rvalid;
    logic [    AXI_ID_WIDTH-1:0] m_axi_rid;
    logic [  AXI_DATA_WIDTH-1:0] m_axi_rdata;
    logic [                 1:0] m_axi_rresp;
    logic                        m_axi_rlast;
    logic                        m_axi_rready;

    logic                        m_axi_awvalid;
    logic [    AXI_ID_WIDTH-1:0] m_axi_awid;
    logic [  AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
    logic [                 7:0] m_axi_awlen;
    logic [                 2:0] m_axi_awsize;
    logic [                 1:0] m_axi_awburst;
    logic                        m_axi_awready;

    logic                        m_axi_wvalid;
    logic [  AXI_DATA_WIDTH-1:0] m_axi_wdata;
    logic [AXI_DATA_WIDTH/8-1:0] m_axi_wstrb;
    logic                        m_axi_wlast;
    logic                        m_axi_wready;

    logic                        m_axi_bvalid;
    logic [    AXI_ID_WIDTH-1:0] m_axi_bid;
    logic [                 1:0] m_axi_bresp;
    logic                        m_axi_bready;

    svc_rv_soc_bram_cache #(
        .XLEN       (XLEN),
        .IMEM_DEPTH (IMEM_DEPTH),
        .PIPELINED  (PIPELINED),
        .FWD_REGFILE(FWD_REGFILE),
        .FWD        (FWD),
        .BPRED      (BPRED),
        .BTB_ENABLE (BTB_ENABLE),
        .BTB_ENTRIES(BTB_ENTRIES),
        .RAS_ENABLE (RAS_ENABLE),
        .RAS_DEPTH  (RAS_DEPTH),
        .EXT_ZMMUL  (EXT_ZMMUL),
        .EXT_M      (EXT_M),
        .PC_REG     (PC_REG),
        .IMEM_INIT  (IMEM_INIT),

        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH  (AXI_ID_WIDTH)
    ) rv_cpu (
        .clk  (clk),
        .rst_n(rst_n),

        .io_ren  (io_ren),
        .io_raddr(io_raddr),
        .io_rdata(io_rdata),

        .io_wen  (io_wen),
        .io_waddr(io_waddr),
        .io_wdata(io_wdata),
        .io_wstrb(io_wstrb),

        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arid   (m_axi_arid),
        .m_axi_araddr (m_axi_araddr),
        .m_axi_arlen  (m_axi_arlen),
        .m_axi_arsize (m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arready(m_axi_arready),

        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rid   (m_axi_rid),
        .m_axi_rdata (m_axi_rdata),
        .m_axi_rresp (m_axi_rresp),
        .m_axi_rlast (m_axi_rlast),
        .m_axi_rready(m_axi_rready),

        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awid   (m_axi_awid),
        .m_axi_awaddr (m_axi_awaddr),
        .m_axi_awlen  (m_axi_awlen),
        .m_axi_awsize (m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awready(m_axi_awready),

        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wdata (m_axi_wdata),
        .m_axi_wstrb (m_axi_wstrb),
        .m_axi_wlast (m_axi_wlast),
        .m_axi_wready(m_axi_wready),

        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bid   (m_axi_bid),
        .m_axi_bresp (m_axi_bresp),
        .m_axi_bready(m_axi_bready),

        .ebreak(ebreak),
        .trap  ()
    );

    //
    // AXI memory backing store for data cache
    //
    // Address width computed from DMEM_DEPTH to ensure memory is large enough.
    // DMEM_DEPTH is in 32-bit words, so byte address width = clog2(DMEM_DEPTH) + 2
    //
    localparam int DMEM_AXI_AW = $clog2(DMEM_DEPTH) + 2;

    svc_axi_mem #(
        .AXI_ADDR_WIDTH(DMEM_AXI_AW),
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        .AXI_ID_WIDTH  (AXI_ID_WIDTH),
        .INIT_FILE     (DMEM_INIT)
    ) axi_dmem (
        .clk  (clk),
        .rst_n(rst_n),

        .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arid   (m_axi_arid),
        .s_axi_araddr (m_axi_araddr[DMEM_AXI_AW-1:0]),
        .s_axi_arlen  (m_axi_arlen),
        .s_axi_arsize (m_axi_arsize),
        .s_axi_arburst(m_axi_arburst),
        .s_axi_arready(m_axi_arready),

        .s_axi_rvalid(m_axi_rvalid),
        .s_axi_rid   (m_axi_rid),
        .s_axi_rdata (m_axi_rdata),
        .s_axi_rresp (m_axi_rresp),
        .s_axi_rlast (m_axi_rlast),
        .s_axi_rready(m_axi_rready),

        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awid   (m_axi_awid),
        .s_axi_awaddr (m_axi_awaddr[DMEM_AXI_AW-1:0]),
        .s_axi_awlen  (m_axi_awlen),
        .s_axi_awsize (m_axi_awsize),
        .s_axi_awburst(m_axi_awburst),
        .s_axi_awready(m_axi_awready),

        .s_axi_wvalid(m_axi_wvalid),
        .s_axi_wdata (m_axi_wdata),
        .s_axi_wstrb (m_axi_wstrb),
        .s_axi_wlast (m_axi_wlast),
        .s_axi_wready(m_axi_wready),

        .s_axi_bvalid(m_axi_bvalid),
        .s_axi_bid   (m_axi_bid),
        .s_axi_bresp (m_axi_bresp),
        .s_axi_bready(m_axi_bready)
    );

    //
    // Upper address bits unused (memory is 64KB)
    //
    `SVC_UNUSED({m_axi_araddr[31:16], m_axi_awaddr[31:16]})

  end else begin : bram_soc
    svc_rv_soc_bram #(
        .XLEN       (XLEN),
        .IMEM_DEPTH (IMEM_DEPTH),
        .DMEM_DEPTH (DMEM_DEPTH),
        .PIPELINED  (PIPELINED),
        .FWD_REGFILE(FWD_REGFILE),
        .FWD        (FWD),
        .BPRED      (BPRED),
        .BTB_ENABLE (BTB_ENABLE),
        .BTB_ENTRIES(BTB_ENTRIES),
        .RAS_ENABLE (RAS_ENABLE),
        .RAS_DEPTH  (RAS_DEPTH),
        .EXT_ZMMUL  (EXT_ZMMUL),
        .EXT_M      (EXT_M),
        .PC_REG     (PC_REG),
        .IMEM_INIT  (IMEM_INIT),
        .DMEM_INIT  (DMEM_INIT)
    ) rv_cpu (
        .clk     (clk),
        .rst_n   (rst_n),
        .io_ren  (io_ren),
        .io_raddr(io_raddr),
        .io_rdata(io_rdata),
        .io_wen  (io_wen),
        .io_waddr(io_waddr),
        .io_wdata(io_wdata),
        .io_wstrb(io_wstrb),
        .ebreak  (ebreak),
        .trap    ()
    );
  end

  //
  // I/O register bank with peripherals (UART, LED, GPIO)
  //
  svc_soc_io_reg #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .MEM_TYPE  (MEM_TYPE)
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
      .uart_tx (uart_tx),
      .uart_rx (uart_rx)
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

    $display("SVC_SOC_SIM: Starting...");
    $display("SVC_SOC_SIM: IMEM_INIT=%s", IMEM_INIT);
    $display("SVC_SOC_SIM: DMEM_INIT=%s", DMEM_INIT);
    $fflush();

    done = 0;

    // Wait for reset to complete
    wait (rst_n);

    $display("SVC_SOC_SIM: Reset complete");
    $fflush();

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

    // Print config (before separator - separator brackets sim output only)
    if (SW_PATH != "") begin
      $display("%smain:        %s", P, SW_PATH);
    end

    $display("%swatchdog:    %0d cycles", P, WATCHDOG_CYCLES);

    $display(
        "%smem type:    %s", P,
        (MEM_TYPE == MEM_TYPE_SRAM) ?
            "SRAM" : (MEM_TYPE == MEM_TYPE_BRAM_CACHE) ? "BRAM_CACHE" : "BRAM");

`ifndef VERILATOR
    //
    // reach all the way into the cpu to print these to ensure we didn't
    // drop params along the way
    //
    if (MEM_TYPE == MEM_TYPE_SRAM) begin
      $display("%sPIPELINED:   %0d", P, sram_soc.rv_cpu.cpu.PIPELINED);
      $display("%sFWD_REGFILE: %0d", P, sram_soc.rv_cpu.cpu.FWD_REGFILE);
      $display("%sFWD:         %0d", P, sram_soc.rv_cpu.cpu.FWD);
      $display("%sBPRED:       %0d", P, sram_soc.rv_cpu.cpu.BPRED);
      $display("%sBTB_ENABLE:  %0d", P, sram_soc.rv_cpu.cpu.BTB_ENABLE);
      $display("%sBTB_ENTRIES: %0d", P, sram_soc.rv_cpu.cpu.BTB_ENTRIES);
      $display("%sRAS_ENABLE:  %0d", P, sram_soc.rv_cpu.cpu.RAS_ENABLE);
      $display("%sRAS_DEPTH:   %0d", P, sram_soc.rv_cpu.cpu.RAS_DEPTH);
      $display("%sPC_REG:      %0d", P, sram_soc.rv_cpu.cpu.PC_REG);
      $display("%sEXT_ZMMUL:   %0d", P, sram_soc.rv_cpu.cpu.EXT_ZMMUL);
      $display("%sEXT_M:       %0d", P, sram_soc.rv_cpu.cpu.EXT_M);
    end else if (MEM_TYPE == MEM_TYPE_BRAM_CACHE) begin
      $display("%sPIPELINED:   %0d", P, cache_soc.rv_cpu.cpu.PIPELINED);
      $display("%sFWD_REGFILE: %0d", P, cache_soc.rv_cpu.cpu.FWD_REGFILE);
      $display("%sFWD:         %0d", P, cache_soc.rv_cpu.cpu.FWD);
      $display("%sBPRED:       %0d", P, cache_soc.rv_cpu.cpu.BPRED);
      $display("%sBTB_ENABLE:  %0d", P, cache_soc.rv_cpu.cpu.BTB_ENABLE);
      $display("%sBTB_ENTRIES: %0d", P, cache_soc.rv_cpu.cpu.BTB_ENTRIES);
      $display("%sRAS_ENABLE:  %0d", P, cache_soc.rv_cpu.cpu.RAS_ENABLE);
      $display("%sRAS_DEPTH:   %0d", P, cache_soc.rv_cpu.cpu.RAS_DEPTH);
      $display("%sPC_REG:      %0d", P, cache_soc.rv_cpu.cpu.PC_REG);
      $display("%sEXT_ZMMUL:   %0d", P, cache_soc.rv_cpu.cpu.EXT_ZMMUL);
      $display("%sEXT_M:       %0d", P, cache_soc.rv_cpu.cpu.EXT_M);
    end else begin
      $display("%sPIPELINED:   %0d", P, bram_soc.rv_cpu.cpu.PIPELINED);
      $display("%sFWD_REGFILE: %0d", P, bram_soc.rv_cpu.cpu.FWD_REGFILE);
      $display("%sFWD:         %0d", P, bram_soc.rv_cpu.cpu.FWD);
      $display("%sBPRED:       %0d", P, bram_soc.rv_cpu.cpu.BPRED);
      $display("%sBTB_ENABLE:  %0d", P, bram_soc.rv_cpu.cpu.BTB_ENABLE);
      $display("%sBTB_ENTRIES: %0d", P, bram_soc.rv_cpu.cpu.BTB_ENTRIES);
      $display("%sRAS_ENABLE:  %0d", P, bram_soc.rv_cpu.cpu.RAS_ENABLE);
      $display("%sRAS_DEPTH:   %0d", P, bram_soc.rv_cpu.cpu.RAS_DEPTH);
      $display("%sPC_REG:      %0d", P, bram_soc.rv_cpu.cpu.PC_REG);
      $display("%sEXT_ZMMUL:   %0d", P, bram_soc.rv_cpu.cpu.EXT_ZMMUL);
      $display("%sEXT_M:       %0d", P, bram_soc.rv_cpu.cpu.EXT_M);
    end
`endif

    $display("SVC_SOC_SIM: Waiting for timeout or ebreak...");
    $fflush();

    // Separator brackets simulation output only
    $display("%s%s", P, sep);

    // Wait for completion
    wait (timeout || ebreak);

    // End of simulation output
    $display("%s%s", P, sep);

    $display("SVC_SOC_SIM: Complete!");
    $fflush();

    if (timeout) begin
      $display("%sreason: timeout", P);
    end else begin
      $display("%sreason: ebreak", P);
    end

    $display("%scycles: %0d", P, cycle_count);

`ifndef VERILATOR
    if (PIPELINED == 1) begin : g_cpi_rpt
      //
      // CPI reporting
      //
      begin
        logic [31:0] cycles;
        logic [31:0] instrs;
        real         cpi;

        if (MEM_TYPE == MEM_TYPE_SRAM) begin
          cycles = sram_soc.rv_cpu.cpu.stage_ex.csr.cycle;
          instrs = sram_soc.rv_cpu.cpu.stage_ex.csr.instret;
        end else if (MEM_TYPE == MEM_TYPE_BRAM_CACHE) begin
          cycles = cache_soc.rv_cpu.cpu.stage_ex.csr.cycle;
          instrs = cache_soc.rv_cpu.cpu.stage_ex.csr.instret;
        end else begin
          cycles = bram_soc.rv_cpu.cpu.stage_ex.csr.cycle;
          instrs = bram_soc.rv_cpu.cpu.stage_ex.csr.instret;
        end

        cpi = real'(cycles) / real'(instrs);

        $display("%sinstrs: %0d", P, instrs);
      end
    end
`endif

    done = 1;
    $finish(0);
  end

endmodule

`endif
