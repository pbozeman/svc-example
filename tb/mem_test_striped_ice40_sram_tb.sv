`include "svc.sv"
`include "svc_model_sram.sv"
`include "svc_unit.sv"

`include "mem_test_striped_ice40_sram.sv"

module mem_test_striped_ice40_sram_tb;
  localparam NUM_S = 4;
  localparam SRAM_ADDR_WIDTH = 18;
  localparam SRAM_DATA_WIDTH = 16;
  localparam NUM_BURSTS = 16;
  localparam NUM_BEATS = 128;

  logic [NUM_S-1:0][SRAM_ADDR_WIDTH-1:0] sram_io_addr;
  wire  [NUM_S-1:0][SRAM_DATA_WIDTH-1:0] sram_io_data;
  logic [NUM_S-1:0]                      sram_io_we_n;
  logic [NUM_S-1:0]                      sram_io_oe_n;
  logic [NUM_S-1:0]                      sram_io_ce_n;

  logic                                  done;
  logic                                  pass;

  logic [      7:0]                      done_cnt;

  `TEST_CLK_NS(clk, 20);
  `TEST_RST_N(clk, rst_n);

  mem_test_striped_ice40_sram #(
      .NUM_S          (NUM_S),
      .SRAM_ADDR_WIDTH(SRAM_ADDR_WIDTH),
      .SRAM_DATA_WIDTH(SRAM_DATA_WIDTH),
      .NUM_BURSTS     (NUM_BURSTS),
      .NUM_BEATS      (NUM_BEATS)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),

      .test_done(done),
      .test_pass(pass),
      .debug0   (),
      .debug1   (),
      .debug2   (),

      .sram_io_addr(sram_io_addr),
      .sram_io_data(sram_io_data),
      .sram_io_we_n(sram_io_we_n),
      .sram_io_oe_n(sram_io_oe_n),
      .sram_io_ce_n(sram_io_ce_n)
  );

  for (genvar i = 0; i < NUM_S; i++) begin : gen_sram
    svc_model_sram #(
        .ADDR_WIDTH(SRAM_ADDR_WIDTH),
        .DATA_WIDTH(SRAM_DATA_WIDTH)
    ) svc_model_sram_i (
        .rst_n  (rst_n),
        .we_n   (sram_io_we_n[i]),
        .oe_n   (sram_io_oe_n[i]),
        .ce_n   (sram_io_ce_n[i]),
        .addr   (sram_io_addr[i]),
        .data_io(sram_io_data[i])
    );
  end

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      done_cnt <= 0;
    end else begin
      if (done) begin
        done_cnt <= done_cnt + 1;
      end
    end
  end

  task automatic test_pass();
    `CHECK_FALSE(done);
    `CHECK_TRUE(pass);

    wait (done_cnt == 3 || !pass);
    `CHECK_TRUE(pass);
    `CHECK_EQ(done_cnt, 3);
  endtask

  `TEST_SUITE_BEGIN(mem_test_striped_ice40_sram_tb);
  `TEST_CASE(test_pass);
  `TEST_SUITE_END();
endmodule
