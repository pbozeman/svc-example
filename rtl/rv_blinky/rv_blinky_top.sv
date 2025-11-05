`include "svc.sv"
`include "rv_blinky.sv"

//
// Top-level wrapper for RISC-V blinky demo
//
// For iCE40 FPGA synthesis
//
module rv_blinky_top (
    input logic clk_pin,
    input logic rst_n_pin,

    output logic       led_pin,
    output logic [7:0] gpio_pins
);

  logic       led;
  logic [7:0] gpio;
  logic       ebreak;

  rv_blinky core (
      .clk   (clk_pin),
      .rst_n (rst_n_pin),
      .led   (led),
      .gpio  (gpio),
      .ebreak(ebreak)
  );

  assign led_pin   = led;
  assign gpio_pins = gpio;

  //
  // Unused ebreak signal
  //
  `SVC_UNUSED(ebreak);

endmodule
