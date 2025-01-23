`include "svc.sv"
`include "svc_init.sv"

`include "mem_test.sv"

// This is currently more of a quick test of the axi stack rather than a full
// sram tester. Fully testing and stressing the actual chip as part of hw
// acceptance testing is TBD.

module mem_test_top #(
    parameter integer SRAM_ADDR_WIDTH = 20,
    parameter integer SRAM_DATA_WIDTH = 16
) (
    // board signals
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // Buses
    output logic [SRAM_ADDR_WIDTH-1:0] R_SRAM_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] R_SRAM_DATA_BUS,

    // Control signals
    output logic R_SRAM_CS_N,
    output logic R_SRAM_OE_N,
    output logic R_SRAM_WE_N,

    output logic [7:0] R_E,
    output logic [7:0] R_F,
    output logic [7:0] R_H
);
  localparam NUM_BURSTS = 255;
  localparam NUM_BEATS = 255;

  logic       rst_n;
  logic       test_done;
  logic       test_pass;

  logic [7:0] done_cnt;

  svc_init svc_init_i (
      .clk  (CLK),
      .rst_n(rst_n)
  );

  mem_test #(
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
      .NUM_BURSTS     (NUM_BURSTS),
      .NUM_BEATS      (NUM_BEATS)
  ) mem_test_new_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .test_done(test_done),
      .test_pass(test_pass),

      .debug0(R_E),
      .debug1(R_F),
      .debug2(R_H),

      .sram_io_addr(R_SRAM_ADDR_BUS),
      .sram_io_data(R_SRAM_DATA_BUS),
      .sram_io_ce_n(R_SRAM_CS_N),
      .sram_io_we_n(R_SRAM_WE_N),
      .sram_io_oe_n(R_SRAM_OE_N)
  );

  always_ff @(posedge CLK) begin
    if (!rst_n) begin
      done_cnt <= 0;
    end else begin
      if (test_done) begin
        done_cnt <= done_cnt + 1;
      end
    end
  end

  assign LED1 = done_cnt[7];
  assign LED2 = !test_pass;

endmodule
