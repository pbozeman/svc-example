`include "svc_unit.sv"
`include "svc_soc_io_reg.sv"

module svc_soc_io_reg_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  logic        io_wen;
  logic [31:0] io_waddr;
  logic [31:0] io_wdata;
  logic [ 3:0] io_wstrb;
  logic        io_ren;
  logic [31:0] io_raddr;
  logic [31:0] io_rdata;
  logic        led;
  logic [ 7:0] gpio;

  svc_soc_io_reg uut (
      .clk     (clk),
      .rst_n   (rst_n),
      .io_wen  (io_wen),
      .io_waddr(io_waddr),
      .io_wdata(io_wdata),
      .io_wstrb(io_wstrb),
      .io_ren  (io_ren),
      .io_raddr(io_raddr),
      .io_rdata(io_rdata),
      .led     (led),
      .gpio    (gpio)
  );

  //
  // Initialize signals in reset
  //
  always_ff @(posedge clk) begin
    if (~rst_n) begin
      io_wen   <= 1'b0;
      io_waddr <= 32'h0;
      io_wdata <= 32'h0;
      io_wstrb <= 4'h0;
      io_ren   <= 1'b0;
      io_raddr <= 32'h0;
    end
  end

  //
  // Test reset state
  //
  task automatic test_reset();
    `CHECK_EQ(led, 1'b0);
    `CHECK_EQ(gpio, 8'h00);
  endtask

  //
  // Test write LED register
  //
  task automatic test_write_led();
    io_wen   = 1'b1;
    io_waddr = 32'h80000000;
    io_wdata = 32'h00000001;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b1);
    `CHECK_EQ(gpio, 8'h00);

    io_waddr = 32'h80000000;
    io_wdata = 32'h00000000;
    io_wen   = 1'b1;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b0);
  endtask

  //
  // Test write GPIO register
  //
  task automatic test_write_gpio();
    io_wen   = 1'b1;
    io_waddr = 32'h80000004;
    io_wdata = 32'h000000AA;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b0);
    `CHECK_EQ(gpio, 8'hAA);

    io_waddr = 32'h80000004;
    io_wdata = 32'h00000055;
    io_wen   = 1'b1;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(gpio, 8'h55);
  endtask

  //
  // Test write both LED and GPIO
  //
  task automatic test_write_both();
    io_wen   = 1'b1;
    io_waddr = 32'h80000000;
    io_wdata = 32'h00000001;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_waddr = 32'h80000004;
    io_wdata = 32'h000000FF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b1);
    `CHECK_EQ(gpio, 8'hFF);
  endtask

  //
  // Test read LED register
  //
  task automatic test_read_led();
    io_wen   = 1'b1;
    io_waddr = 32'h80000000;
    io_wdata = 32'h00000001;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    io_ren   = 1'b1;
    io_raddr = 32'h80000000;

    `TICK(clk);

    `CHECK_EQ(io_rdata, 32'h00000001);

    io_ren = 1'b0;

    `TICK(clk);
  endtask

  //
  // Test read GPIO register
  //
  task automatic test_read_gpio();
    io_wen   = 1'b1;
    io_waddr = 32'h80000004;
    io_wdata = 32'h000000AA;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    io_ren   = 1'b1;
    io_raddr = 32'h80000004;

    `TICK(clk);

    `CHECK_EQ(io_rdata, 32'h000000AA);

    io_ren = 1'b0;

    `TICK(clk);
  endtask

  //
  // Test address decode uses lower 8 bits
  //
  task automatic test_address_decode();
    io_wen   = 1'b1;
    io_waddr = 32'hFFFFFF00;
    io_wdata = 32'h00000001;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b1);

    io_wen   = 1'b1;
    io_waddr = 32'hDEADBE04;
    io_wdata = 32'h00000042;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(gpio, 8'h42);
  endtask

  //
  // Test write to invalid address has no effect
  //
  task automatic test_invalid_address();
    io_wen   = 1'b1;
    io_waddr = 32'h80000000;
    io_wdata = 32'h00000001;
    io_wstrb = 4'hF;

    `TICK(clk);

    io_waddr = 32'h80000004;
    io_wdata = 32'h000000AA;

    `TICK(clk);

    io_waddr = 32'h80000008;
    io_wdata = 32'hDEADBEEF;

    `TICK(clk);

    io_wen = 1'b0;

    `TICK(clk);

    `CHECK_EQ(led, 1'b1);
    `CHECK_EQ(gpio, 8'hAA);
  endtask

  `TEST_SUITE_BEGIN(svc_soc_io_reg_tb);
  `TEST_CASE(test_reset);
  `TEST_CASE(test_write_led);
  `TEST_CASE(test_write_gpio);
  `TEST_CASE(test_write_both);
  `TEST_CASE(test_read_led);
  `TEST_CASE(test_read_gpio);
  `TEST_CASE(test_address_decode);
  `TEST_CASE(test_invalid_address);
  `TEST_SUITE_END();

endmodule
