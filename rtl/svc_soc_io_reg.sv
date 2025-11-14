`ifndef SVC_SOC_IO_REG_SV
`define SVC_SOC_IO_REG_SV

`include "svc.sv"
`include "svc_unused.sv"
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
//   0x80000000 + 0x04: UART status register (read-only, bit 0 = TX ready)
//   0x80000000 + 0x08: LED register (bit 0)
//   0x80000000 + 0x0C: GPIO register (bits 7:0)
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
    // Hardware outputs
    //
    output logic       led,
    output logic [7:0] gpio,
    output logic       uart_tx
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
  ) uart (
      .clk      (clk),
      .rst_n    (rst_n),
      .utx_valid(uart_tx_valid),
      .utx_data (uart_tx_data),
      .utx_ready(uart_tx_ready),
      .utx_pin  (uart_tx)
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
        default: io_rdata_comb = 32'h0;
      endcase
    end
  end

  //
  // Output timing based on memory type
  //
  if (MEM_TYPE == MEM_TYPE_BRAM) begin : bram_timing
    //
    // Register output to match BRAM timing (1-cycle latency)
    //
    always_ff @(posedge clk) begin
      if (!rst_n) begin
        io_rdata <= 32'h0;
      end else begin
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
