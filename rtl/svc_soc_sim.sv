`ifndef SVC_SOC_SIM_SV
`define SVC_SOC_SIM_SV

// Common simulation infrastructure for standalone SOC simulations
//
// Provides clock and reset generation for interactive simulations.
// This is NOT for testbenches - use svc_unit.sv test macros for those.
//
// Usage:
//   logic clk, rst_n;
//   svc_soc_sim #(.CLOCK_FREQ_MHZ(100)) sim_infra (.clk(clk), .rst_n(rst_n));

module svc_soc_sim #(
    parameter CLOCK_FREQ_MHZ = 100,
    parameter RESET_CYCLES   = 10
) (
    output logic clk,
    output logic rst_n
);
  // Calculate clock period in nanoseconds
  localparam real CLOCK_PERIOD_NS = 1000.0 / CLOCK_FREQ_MHZ;
  localparam real HALF_PERIOD_NS = CLOCK_PERIOD_NS / 2.0;

  // Clock generation
  initial clk = 0;
  always #(HALF_PERIOD_NS) clk = ~clk;

  // Reset generation
  initial begin
    rst_n = 0;
    #(CLOCK_PERIOD_NS * RESET_CYCLES);
    rst_n = 1;
  end

endmodule

`endif
