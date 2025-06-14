`include "svc.sv"
`include "svc_init.sv"

`include "mem_test_ice40_sram.sv"

// This is currently more of a quick test of the axi stack rather than a full
// sram tester. Fully testing and stressing the actual chip as part of hw
// acceptance testing is TBD.

module mem_test_ice40_sram_top #(
    parameter SRAM_ADDR_WIDTH = 18,
    parameter SRAM_DATA_WIDTH = 16,
    // parameter NUM_BURSTS      = 2047,
    parameter NUM_BURSTS      = 1024,
    parameter NUM_BEATS       = 128
) (
    // board signals
    input  logic CLK,
    output logic LED1,

    // output logic [7:0] PMOD_A,
    // output logic [7:0] PMOD_B,

    // Buses
    output logic [SRAM_ADDR_WIDTH-1:0] SRAM_256_D_ADDR_BUS,
    inout  wire  [SRAM_DATA_WIDTH-1:0] SRAM_256_D_DATA_BUS,

    // Control signals
    output logic SRAM_256_D_OE_N,
    output logic SRAM_256_D_WE_N,
    output logic SRAM_256_D_UB_N,
    output logic SRAM_256_D_LB_N,

    output logic SPI_SS
);

  logic        rst_n;
  // verilator lint_off: UNUSEDSIGNAL
  logic        test_done;
  logic        test_pass;
  // verilator lint_on: UNUSEDSIGNAL

  logic [24:0] done_cnt;

  svc_init #(
      .RST_CYCLES(1023)
  ) svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  mem_test_ice40_sram #(
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
      .NUM_BURSTS     (NUM_BURSTS),
      .NUM_BEATS      (NUM_BEATS)
  ) mem_test_new_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .test_done(test_done),
      .test_pass(test_pass),

      .debug0(),
      .debug1(),
      .debug2(),

      .sram_io_addr(SRAM_256_D_ADDR_BUS),
      .sram_io_data(SRAM_256_D_DATA_BUS),
      .sram_io_ce_n(),
      .sram_io_we_n(SRAM_256_D_WE_N),
      .sram_io_oe_n(SRAM_256_D_OE_N)
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

  assign LED1            = done_cnt[7];
  // assign LED1            = test_pass;

  assign SRAM_256_D_UB_N = 1'b0;
  assign SRAM_256_D_LB_N = 1'b0;
  assign SPI_SS          = 1'b1;

  // assign SRAM_256_D_ADDR_BUS[17:1] = 1'b0;

endmodule
