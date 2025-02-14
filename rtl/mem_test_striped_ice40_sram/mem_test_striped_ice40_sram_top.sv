`include "svc.sv"
`include "svc_init.sv"

`include "mem_test_striped_ice40_sram.sv"

// This is currently more of a quick test of the axi stack rather than a full
// sram tester. Fully testing and stressing the actual chip as part of hw
// acceptance testing is TBD.

// FIXME: for now only use 12 bits, because bit 12 on R_SRAM_B_ADDR_BUS
// doesn't work on the my main dev board. Fix this once repaired.
module mem_test_striped_ice40_sram_top #(
    parameter NUM_S            = 4,
    parameter SRAM_ADDR_WIDTH  = 11,
    parameter SRAM_DATA_WIDTH  = 16,
    parameter SRAM_RDATA_WIDTH = 12,
    parameter NUM_BURSTS       = 255,
    parameter NUM_BEATS        = 128
) (
    // board signals
    input  logic CLK,
    output logic LED1,
    output logic LED2,

    // SRAM A
    output logic                        L_SRAM_256_A_OE_N,
    output logic                        L_SRAM_256_A_WE_N,
    output logic [ SRAM_ADDR_WIDTH-1:0] L_SRAM_256_A_ADDR_BUS,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] L_SRAM_256_A_DATA_BUS,

    // SRAM B
    output logic                        L_SRAM_256_B_OE_N,
    output logic                        L_SRAM_256_B_WE_N,
    output logic [ SRAM_ADDR_WIDTH-1:0] L_SRAM_256_B_ADDR_BUS,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] L_SRAM_256_B_DATA_BUS,

    // SRAM C
    output logic                        R_SRAM_256_A_OE_N,
    output logic                        R_SRAM_256_A_WE_N,
    output logic [ SRAM_ADDR_WIDTH-1:0] R_SRAM_256_A_ADDR_BUS,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] R_SRAM_256_A_DATA_BUS,

    // SRAM D
    output logic                        R_SRAM_256_B_OE_N,
    output logic                        R_SRAM_256_B_WE_N,
    output logic [ SRAM_ADDR_WIDTH-1:0] R_SRAM_256_B_ADDR_BUS,
    inout  wire  [SRAM_RDATA_WIDTH-1:0] R_SRAM_256_B_DATA_BUS,

    // debug signals
    output logic [7:0] R_E,
    output logic [7:0] R_F,
    output logic [7:0] R_I
);

  logic       rst_n;
  logic       test_done;
  logic       test_pass;

  logic [7:0] done_cnt;

  svc_init #(
      .RST_CYCLES(255)
  ) svc_init_i (
      .clk  (CLK),
      .en   (1'b1),
      .rst_n(rst_n)
  );

  mem_test_striped_ice40_sram #(
      .NUM_S           (NUM_S),
      .SRAM_ADDR_WIDTH (SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH (SRAM_DATA_WIDTH),
      .SRAM_RDATA_WIDTH(SRAM_RDATA_WIDTH),
      .NUM_BURSTS      (NUM_BURSTS),
      .NUM_BEATS       (NUM_BEATS)
  ) mem_test_new_i (
      .clk  (CLK),
      .rst_n(rst_n),

      .test_done(test_done),
      .test_pass(test_pass),

      .debug0(R_E),
      .debug1(R_F),
      .debug2(R_I),

      .sram_io_addr({
        R_SRAM_256_B_ADDR_BUS,
        R_SRAM_256_A_ADDR_BUS,
        L_SRAM_256_B_ADDR_BUS,
        L_SRAM_256_A_ADDR_BUS
      }),
      .sram_io_data({
        R_SRAM_256_B_DATA_BUS,
        R_SRAM_256_A_DATA_BUS,
        L_SRAM_256_B_DATA_BUS,
        L_SRAM_256_A_DATA_BUS
      }),
      .sram_io_ce_n(),
      .sram_io_we_n({
        R_SRAM_256_B_WE_N,
        R_SRAM_256_A_WE_N,
        L_SRAM_256_B_WE_N,
        L_SRAM_256_A_WE_N
      }),
      .sram_io_oe_n({
        R_SRAM_256_B_OE_N,
        R_SRAM_256_A_OE_N,
        L_SRAM_256_B_OE_N,
        L_SRAM_256_A_OE_N
      })
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
