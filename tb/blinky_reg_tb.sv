`include "svc_unit.sv"
`include "blinky_reg.sv"

module blinky_reg_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  localparam CLK_FREQ = 100_000_000;

  logic        led;

  logic [ 7:0] m_axil_awaddr;
  logic        m_axil_awvalid;
  logic        m_axil_awready;
  logic [31:0] m_axil_wdata;
  logic [ 3:0] m_axil_wstrb;
  logic        m_axil_wvalid;
  logic        m_axil_wready;
  logic [ 1:0] m_axil_bresp;
  logic        m_axil_bvalid;
  logic        m_axil_bready;

  logic [ 7:0] m_axil_araddr;
  logic        m_axil_arvalid;
  logic        m_axil_arready;
  logic [31:0] m_axil_rdata;
  logic [ 1:0] m_axil_rresp;
  logic        m_axil_rvalid;
  logic        m_axil_rready;

  blinky_reg #(
      .CLK_FREQ(CLK_FREQ)
  ) uut (
      .clk  (clk),
      .rst_n(rst_n),
      .led  (led),

      .s_axil_awaddr (m_axil_awaddr),
      .s_axil_awvalid(m_axil_awvalid),
      .s_axil_awready(m_axil_awready),
      .s_axil_wdata  (m_axil_wdata),
      .s_axil_wstrb  (m_axil_wstrb),
      .s_axil_wvalid (m_axil_wvalid),
      .s_axil_wready (m_axil_wready),
      .s_axil_bresp  (m_axil_bresp),
      .s_axil_bvalid (m_axil_bvalid),
      .s_axil_bready (m_axil_bready),

      .s_axil_araddr (m_axil_araddr),
      .s_axil_arvalid(m_axil_arvalid),
      .s_axil_arready(m_axil_arready),
      .s_axil_rdata  (m_axil_rdata),
      .s_axil_rresp  (m_axil_rresp),
      .s_axil_rvalid (m_axil_rvalid),
      .s_axil_rready (m_axil_rready)
  );

  always_ff @(posedge clk) begin
    if (~rst_n) begin
      m_axil_awvalid <= 1'b0;
      m_axil_awaddr  <= 8'h00;

      m_axil_wvalid  <= 1'b0;
      m_axil_wstrb   <= 4'h0;
      m_axil_wdata   <= 32'h0;

      m_axil_bready  <= 1'b0;

      m_axil_araddr  <= 8'h00;
      m_axil_arvalid <= 1'b0;

      m_axil_rready  <= 1'b0;
    end else begin
      m_axil_awvalid <= m_axil_awvalid && !m_axil_awready;
      m_axil_wvalid  <= m_axil_wvalid && !m_axil_wready;
    end
  end

  task automatic axi_write(input logic [7:0] addr, input logic [31:0] data);
    m_axil_awaddr  = addr;
    m_axil_awvalid = 1'b1;
    m_axil_wdata   = data;
    m_axil_wstrb   = 4'hF;
    m_axil_wvalid  = 1'b1;
    m_axil_bready  = 1'b1;
    `TICK(clk);

    `CHECK_WAIT_FOR(clk, m_axil_bvalid && m_axil_bready);
    `CHECK_EQ(m_axil_bresp, 2'b00);
    `TICK(clk);
    m_axil_bready = 1'b0;
    `TICK(clk);
  endtask

  task automatic axi_read(input logic [7:0] addr, output logic [31:0] data);
    m_axil_araddr  = addr;
    m_axil_arvalid = 1'b1;
    m_axil_rready  = 1'b1;
    `TICK(clk);

    `CHECK_WAIT_FOR(clk, m_axil_arvalid && m_axil_arready);
    m_axil_arvalid = 1'b0;

    `CHECK_WAIT_FOR(clk, m_axil_rvalid && m_axil_rready);
    `CHECK_EQ(m_axil_rresp, 2'b00);
    data = m_axil_rdata;
  endtask

  task automatic test_reset();
    `CHECK_FALSE(led);
  endtask

  task automatic test_default_register_values();
    logic [31:0] rd_data;

    axi_read(8'h00, rd_data);
    `CHECK_EQ(rd_data, 32'h0);

    axi_read(8'h01, rd_data);
    `CHECK_EQ(rd_data, 32'd1);

    axi_read(8'h02, rd_data);
    `CHECK_EQ(rd_data, CLK_FREQ);
  endtask

  task automatic test_enable_led();
    logic [31:0] rd_data;

    axi_write(8'h00, 32'h1);
    `TICK(clk);

    axi_read(8'h00, rd_data);
    `CHECK_EQ(rd_data, 32'h1);

    repeat (10) `TICK(clk);
    `CHECK_TRUE(led);
  endtask

  task automatic test_invalid_access();
    m_axil_awaddr  = 8'h04;
    m_axil_awvalid = 1'b1;
    m_axil_wdata   = 32'h0;
    m_axil_wstrb   = 4'hF;
    m_axil_wvalid  = 1'b1;
    m_axil_bready  = 1'b1;

    `TICK(clk);
    `CHECK_WAIT_FOR(clk, m_axil_awready && m_axil_wready);

    m_axil_awvalid = 1'b0;
    m_axil_wvalid  = 1'b0;

    `CHECK_WAIT_FOR(clk, m_axil_bvalid);

    `CHECK_EQ(m_axil_bresp, 2'b11);
    m_axil_bready = 1'b0;
    `TICK(clk);
  endtask

  `TEST_SUITE_BEGIN(blinky_reg_tb);
  `TEST_CASE(test_reset);
  `TEST_CASE(test_default_register_values);
  `TEST_CASE(test_enable_led);
  `TEST_CASE(test_invalid_access);
  `TEST_SUITE_END();
endmodule
