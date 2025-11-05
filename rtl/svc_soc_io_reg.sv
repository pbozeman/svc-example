`ifndef SVC_SOC_IO_REG_SV
`define SVC_SOC_IO_REG_SV

`include "svc.sv"
`include "svc_unused.sv"

//
// MMIO register bank for SoC I/O
//
// IMPORTANT: This is an initial quick prototype implementation for connecting
// RISC-V MMIO writes directly to hardware pins. A more appropriate long-term
// solution would use the AXI routing infrastructure (e.g., similar to
// blinky_reg.sv with AXI-Lite). However, the current RISC-V core does not
// support AXI yet, which is why we are using this simple direct-mapped
// register approach.
//
// Memory map:
//   0x80000000 + 0x00: LED register (bit 0)
//   0x80000000 + 0x04: GPIO register (bits 7:0)
//
module svc_soc_io_reg (
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
    output logic [7:0] gpio
);

  //
  // Internal registers
  //
  logic       led_reg;
  logic [7:0] gpio_reg;

  //
  // Write logic
  //
  always_ff @(posedge clk) begin
    if (!rst_n) begin
      led_reg  <= 1'b0;
      gpio_reg <= 8'h00;
    end else if (io_wen) begin
      case (io_waddr[7:0])
        8'h00:   led_reg <= io_wdata[0];
        8'h04:   gpio_reg <= io_wdata[7:0];
        default: ;
      endcase
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
  logic [7:0] raddr_sel;
  assign raddr_sel = io_raddr[7:0];

  always_comb begin
    io_rdata = 32'h0;
    if (io_ren) begin
      case (raddr_sel)
        8'h00:   io_rdata = {31'h0, led_reg};
        8'h04:   io_rdata = {24'h0, gpio_reg};
        default: io_rdata = 32'h0;
      endcase
    end
  end

  `SVC_UNUSED({io_wstrb, io_waddr[31:8], io_wdata[31:8], io_raddr[31:8]});

endmodule

`endif
