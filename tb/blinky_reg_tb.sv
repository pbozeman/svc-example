`include "svc_unit.sv"
`include "blinky_reg.sv"

module blinky_reg_tb;
  `TEST_CLK_NS(clk, 10);
  `TEST_RST_N(clk, rst_n);

  localparam AW = 8;
  localparam DW = 32;
  localparam SW = DW / 8;

  localparam CLK_FREQ = 100_000_000;

  logic          led;

  logic [AW-1:0] m_axil_awaddr;
  logic          m_axil_awvalid;
  logic          m_axil_awready;
  logic [DW-1:0] m_axil_wdata;
  logic [SW-1:0] m_axil_wstrb;
  logic          m_axil_wvalid;
  logic          m_axil_wready;
  logic [   1:0] m_axil_bresp;
  logic          m_axil_bvalid;
  logic          m_axil_bready;

  logic [AW-1:0] m_axil_araddr;
  logic          m_axil_arvalid;
  logic          m_axil_arready;
  logic [DW-1:0] m_axil_rdata;
  logic [   1:0] m_axil_rresp;
  logic          m_axil_rvalid;
  logic          m_axil_rready;

  blinky_reg #(
      .CLK_FREQ       (CLK_FREQ),
      .AXIL_ADDR_WIDTH(AW),
      .AXIL_DATA_WIDTH(DW)
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
      m_axil_awaddr  <= AW'(0);

      m_axil_wvalid  <= 1'b0;
      m_axil_wstrb   <= SW'(0);
      m_axil_wdata   <= DW'(0);

      m_axil_bready  <= 1'b0;

      m_axil_araddr  <= AW'(00);
      m_axil_arvalid <= 1'b0;

      m_axil_rready  <= 1'b0;
    end else begin
      m_axil_awvalid <= m_axil_awvalid && !m_axil_awready;
      m_axil_wvalid  <= m_axil_wvalid && !m_axil_wready;
    end
  end

  task automatic axi_write(input logic [AW-1:0] addr,
                           input logic [DW-1:0] data);
    m_axil_awaddr  = addr;
    m_axil_awvalid = 1'b1;
    m_axil_wdata   = data;
    m_axil_wstrb   = '1;
    m_axil_wvalid  = 1'b1;
    m_axil_bready  = 1'b1;
    `TICK(clk);

    `CHECK_WAIT_FOR(clk, m_axil_bvalid && m_axil_bready);
    `CHECK_EQ(m_axil_bresp, 2'b00);
    `TICK(clk);
    m_axil_bready = 1'b0;
    `TICK(clk);
  endtask

  task automatic axi_read(input logic [AW-1:0] addr,
                          output logic [DW-1:0] data);
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
    logic [DW-1:0] rd_data;

    axi_read(AW'(0), rd_data);
    `CHECK_EQ(rd_data, 0);

    axi_read(AW'(4), rd_data);
    `CHECK_EQ(rd_data, CLK_FREQ / 2);

    axi_read(AW'(8), rd_data);
    `CHECK_EQ(rd_data, CLK_FREQ);
  endtask

  task automatic test_enable_led();
    logic [DW-1:0] rd_data;

    axi_write(AW'(0), 32'h1);
    `TICK(clk);

    axi_read(AW'(0), rd_data);
    `CHECK_EQ(rd_data, DW'(1));

    repeat (10) `TICK(clk);
    `CHECK_TRUE(led);
  endtask

  task automatic test_invalid_access();
    // there are 4 valid registers
    m_axil_awaddr  = AW'(5 * 4);
    m_axil_awvalid = 1'b1;
    m_axil_wdata   = DW'(0);
    m_axil_wstrb   = '1;
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
