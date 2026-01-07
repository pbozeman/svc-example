`include "svc.sv"

`include "svc_rv_soc_bram.sv"
`include "svc_soc_io_reg.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"

module top (
    input  wire       CLK100MHZ,
    input  wire       reset,
    output wire [3:0] led,
    input  wire       UART_RX,
    output wire       UART_TX
);
  localparam CLOCK_FREQ = 100_000_000;
  localparam BAUD_RATE = 115_200;

  wire clk = CLK100MHZ;
  wire rst_n = reset;

  wire ebreak;

  assign led[3] = reset;
  assign led[2] = ebreak;
  assign led[1] = 1'b0;
  assign led[0] = 1'b0;

  //
  // Debug UART signals (for loading programs via debug bridge)
  //
  logic       dbg_urx_valid;
  logic [7:0] dbg_urx_data;
  logic       dbg_urx_ready;
  logic       dbg_utx_valid;
  logic [7:0] dbg_utx_data;
  logic       dbg_utx_ready;

  //
  // SoC I/O signals
  //
  logic        io_ren;
  logic [31:0] io_raddr;
  logic [31:0] io_rdata;
  logic        io_wen;
  logic [31:0] io_waddr;
  logic [31:0] io_wdata;
  logic [ 3:0] io_wstrb;

  //
  // Debug UART RX - decode serial input for debug bridge
  //
  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) dbg_uart_rx (
      .clk      (clk),
      .rst_n    (rst_n),
      .urx_valid(dbg_urx_valid),
      .urx_data (dbg_urx_data),
      .urx_ready(dbg_urx_ready),
      .urx_pin  (UART_RX)
  );

  //
  // Debug UART TX - encode debug bridge output to serial
  //
  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) dbg_uart_tx (
      .clk      (clk),
      .rst_n    (rst_n),
      .utx_valid(dbg_utx_valid),
      .utx_data (dbg_utx_data),
      .utx_ready(dbg_utx_ready),
      .utx_pin  (UART_TX)
  );

  //
  // Instantiate the RISC-V SoC with debug loader enabled
  //
  // CPU starts stalled and in reset, waiting for commands via the debug UART.
  // Use rv_loader.py to load and run programs.
  //
  svc_rv_soc_bram #(
      .XLEN        (32),
      .IMEM_DEPTH  (2048),
      .DMEM_DEPTH  (2048),
      .PIPELINED   (1),
      .FWD_REGFILE (1),
      .FWD         (1),
      .BPRED       (1),
      .BTB_ENABLE  (1),
      .BTB_ENTRIES (64),
      .RAS_ENABLE  (1),
      .RAS_DEPTH   (8),
      .EXT_ZMMUL   (0),
      .EXT_M       (1),
      .PC_REG      (1),
      .DEBUG_ENABLED(1),
      .IMEM_INIT   (""),
      .DMEM_INIT   ("")
  ) soc (
      .clk          (clk),
      .rst_n        (rst_n),

      // Debug UART interface
      .dbg_urx_valid(dbg_urx_valid),
      .dbg_urx_data (dbg_urx_data),
      .dbg_urx_ready(dbg_urx_ready),
      .dbg_utx_valid(dbg_utx_valid),
      .dbg_utx_data (dbg_utx_data),
      .dbg_utx_ready(dbg_utx_ready),

      // I/O interface
      .io_ren       (io_ren),
      .io_raddr     (io_raddr),
      .io_rdata     (io_rdata),
      .io_wen       (io_wen),
      .io_waddr     (io_waddr),
      .io_wdata     (io_wdata),
      .io_wstrb     (io_wstrb),

      .ebreak       (ebreak),
      .trap         ()
  );

  //
  // Instantiate the I/O register bank
  //
  // Note: Application UART TX is unconnected since UART_TX is used for debug.
  // Application UART RX is tied idle since debug loader owns the RX pin.
  //
  svc_soc_io_reg #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE),
      .MEM_TYPE  (1)
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
      .led     (),
      .gpio    (),
      .uart_tx ()
  );

endmodule