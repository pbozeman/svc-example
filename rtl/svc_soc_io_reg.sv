`ifndef SVC_SOC_IO_REG_SV
`define SVC_SOC_IO_REG_SV

`include "svc.sv"
`include "svc_unused.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"

//
// MMIO register bank for SoC I/O
//
// Provides memory-mapped I/O peripherals for RISC-V SoC:
// - UART TX for serial output
// - LED control
// - GPIO pins
//
// IMPORTANT: This is an initial implementation using direct MMIO mapping.
// A more appropriate long-term solution would use the AXI routing
// infrastructure (e.g., similar to blinky_reg.sv with AXI-Lite). However,
// the current RISC-V core does not support AXI yet, which is why we are
// using this simple direct-mapped register approach.
//
// Memory map:
//   0x80000000 + 0x00: UART TX data register (write-only, bits 7:0)
//   0x80000000 + 0x04: UART TX status register (read-only, bit 0 = TX ready)
//   0x80000000 + 0x08: LED register (bit 0)
//   0x80000000 + 0x0C: GPIO register (bits 7:0)
//   0x80000000 + 0x10: Clock frequency register (read-only, Hz)
//   0x80000000 + 0x14: UART RX data register (read-only, bits 7:0, read clears)
//   0x80000000 + 0x18: UART RX status register (read-only, bit 0 = data avail)
//
module svc_soc_io_reg #(
    parameter     CLOCK_FREQ = 25_000_000,
    parameter     BAUD_RATE  = 115_200,
    parameter int MEM_TYPE   = 1
) (
    input logic clk,
    input logic rst_n,

    //
    // MMIO write interface from SoC
    //
    input logic        io_wen,
    input logic [31:0] io_waddr,
    input logic [31:0] io_wdata,
    input logic [ 3:0] io_wstrb,

    //
    // MMIO read interface
    //
    input  logic        io_ren,
    input  logic [31:0] io_raddr,
    output logic [31:0] io_rdata,

    //
    // Hardware I/O
    //
    output logic       led,
    output logic [7:0] gpio,
    output logic       uart_tx,
    input  logic       uart_rx
);

  //
  // Internal registers
  //
  logic       led_reg;
  logic [7:0] gpio_reg;

  //
  // UART TX signals
  //
  logic       uart_tx_valid;
  logic [7:0] uart_tx_data;
  logic       uart_tx_ready;

  //
  // UART TX instantiation
  //
  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) uart_tx_inst (
      .clk      (clk),
      .rst_n    (rst_n),
      .utx_valid(uart_tx_valid),
      .utx_data (uart_tx_data),
      .utx_ready(uart_tx_ready),
      .utx_pin  (uart_tx)
  );

  //
  // UART RX signals
  //
  logic       uart_rx_valid;
  logic [7:0] uart_rx_data;
  logic       uart_rx_ready;

  //
  // UART RX instantiation
  //
  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) uart_rx_inst (
      .clk      (clk),
      .rst_n    (rst_n),
      .urx_valid(uart_rx_valid),
      .urx_data (uart_rx_data),
      .urx_ready(uart_rx_ready),
      .urx_pin  (uart_rx)
  );

  //
  // Write logic
  //
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      led_reg  <= 1'b0;
      gpio_reg <= 8'h00;
    end else if (io_wen) begin
      case (io_waddr[7:0])
        8'h08:   led_reg <= io_wdata[0];
        8'h0C:   gpio_reg <= io_wdata[7:0];
        default: ;
      endcase
    end
  end

  //
  // UART TX write logic
  //
  logic       uart_tx_write;
  logic [7:0] io_wdata_byte;

  assign uart_tx_write = io_wen && (io_waddr[7:0] == 8'h00);
  assign io_wdata_byte = io_wdata[7:0];

  always_comb begin
    uart_tx_valid = 1'b0;
    uart_tx_data  = 8'h00;

    if (uart_tx_write) begin
      uart_tx_valid = 1'b1;
      uart_tx_data  = io_wdata_byte;
    end
  end

  //
  // Drive outputs
  //
  assign led  = led_reg;
  assign gpio = gpio_reg;

  //
  // Read logic
  //
  // IMPORTANT: Read timing must match memory type:
  // - BRAM (MEM_TYPE=1): 1-cycle registered reads
  // - SRAM (MEM_TYPE=0): 0-cycle combinational reads
  //
  `include "svc_rv_defs.svh"

  logic [ 7:0] raddr_sel;
  logic [31:0] io_rdata_comb;

  assign raddr_sel = io_raddr[7:0];

  always_comb begin
    io_rdata_comb = 32'h0;
    if (io_ren) begin
      case (raddr_sel)
        8'h00:   io_rdata_comb = 32'h0;
        8'h04:   io_rdata_comb = {31'h0, uart_tx_ready};
        8'h08:   io_rdata_comb = {31'h0, led_reg};
        8'h0C:   io_rdata_comb = {24'h0, gpio_reg};
        8'h10:   io_rdata_comb = CLOCK_FREQ;
        8'h14:   io_rdata_comb = {24'h0, uart_rx_data};
        8'h18:   io_rdata_comb = {31'h0, uart_rx_valid};
        default: io_rdata_comb = 32'h0;
      endcase
    end
  end

  //
  // UART RX ready logic
  //
  // Pulse ready when SW reads the RX data register to acknowledge receipt.
  // This clears uart_rx_valid on the next cycle.
  //
  assign uart_rx_ready = io_ren && (raddr_sel == 8'h14);

  //
  // Output timing based on memory type
  //
  // BRAM_CACHE uses BRAM timing for I/O since its I/O interface
  // uses BRAM-style registered reads (1-cycle latency).
  //
  if (MEM_TYPE == MEM_TYPE_BRAM ||
      MEM_TYPE == MEM_TYPE_BRAM_CACHE) begin : bram_timing
    //
    // Register output to match BRAM timing (1-cycle latency)
    //
    always_ff @(posedge clk) begin
      if (!rst_n) begin
        io_rdata <= 32'h0;
      end else if (io_ren) begin
        io_rdata <= io_rdata_comb;
      end
    end
  end else begin : sram_timing
    //
    // Combinational output for SRAM timing (0-cycle latency)
    //
    assign io_rdata = io_rdata_comb;
  end

  `SVC_UNUSED({io_wstrb, io_waddr[31:8], io_wdata[31:8], io_raddr[31:8]});

endmodule

`endif
