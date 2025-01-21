`ifndef MEM_TEST_SV
`define MEM_TEST_SV

`include "svc_ice40_axi_sram.sv"

module mem_test #(
    parameter SRAM_ADDR_WIDTH = 20,
    parameter SRAM_DATA_WIDTH = 16,
    parameter NUM_BURSTS      = 8,
    parameter NUM_BEATS       = 3
) (
    // tester signals
    input logic clk,
    input logic rst_n,

    output logic test_done,
    output logic test_pass,

    // debug/output signals
    output logic [7:0] debug0,
    output logic [7:0] debug1,
    output logic [7:0] debug2,

    // sram controller to io pins
    output logic [SRAM_ADDR_WIDTH-1:0] sram_io_addr,
    inout  wire  [SRAM_DATA_WIDTH-1:0] sram_io_data,
    output logic                       sram_io_we_n,
    output logic                       sram_io_oe_n,
    output logic                       sram_io_ce_n
);
  localparam AXI_ADDR_WIDTH = SRAM_ADDR_WIDTH + $clog2(SRAM_DATA_WIDTH / 8);
  localparam AXI_DATA_WIDTH = SRAM_DATA_WIDTH;
  localparam AXI_STRB_WIDTH = SRAM_DATA_WIDTH / 8;

  localparam BURST_ADDR_BASE = AXI_ADDR_WIDTH'(8'h0A);
  localparam BEAT_DATA_BASE = AXI_DATA_WIDTH'(8'hD0);

  localparam BYTES_PER_BEAT = SRAM_DATA_WIDTH / 8;
  localparam BYTES_PER_BURST = BYTES_PER_BEAT * NUM_BEATS;

  typedef enum {
    STATE_IDLE,
    STATE_BURST_INIT,
    STATE_BURST,
    STATE_DONE,
    STATE_FAIL
  } state_t;

  logic                        m_axi_awvalid;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_awaddr;
  logic   [               7:0] m_axi_awlen;
  logic   [               2:0] m_axi_awsize;
  logic                        m_axi_awready;

  logic                        m_axi_wvalid;
  logic   [AXI_DATA_WIDTH-1:0] m_axi_wdata;
  logic   [AXI_STRB_WIDTH-1:0] m_axi_wstrb;
  logic                        m_axi_wlast;
  logic                        m_axi_wready;

  logic                        m_axi_bvalid;
  logic                        m_axi_bready;

  logic                        m_axi_arvalid;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_araddr;
  logic   [               7:0] m_axi_arlen;
  logic                        m_axi_arready;

  logic                        m_axi_rvalid;
  logic   [AXI_DATA_WIDTH-1:0] m_axi_rdata;
  logic                        m_axi_rlast;
  logic                        m_axi_rready;

  state_t                      w_state;
  state_t                      w_state_next;

  logic   [AXI_ADDR_WIDTH-1:0] w_burst_addr;
  logic   [AXI_ADDR_WIDTH-1:0] w_burst_addr_next;

  logic   [               7:0] w_burst_cnt;
  logic   [               7:0] w_burst_cnt_next;

  logic   [               7:0] w_beat_cnt;
  logic   [               7:0] w_beat_cnt_next;

  logic   [               7:0] w_data_cnt;
  logic   [               7:0] w_data_cnt_next;

  logic   [AXI_DATA_WIDTH-1:0] w_data_calc;

  logic                        m_axi_awvalid_next;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_next;
  logic   [               7:0] m_axi_awlen_next;
  logic   [               2:0] m_axi_arsize;

  logic                        m_axi_wvalid_next;
  logic   [AXI_DATA_WIDTH-1:0] m_axi_wdata_next;
  logic                        m_axi_wlast_next;

  logic                        r_enable;
  logic                        r_enable_next;

  state_t                      r_state;
  state_t                      r_state_next;

  logic   [AXI_ADDR_WIDTH-1:0] r_burst_addr;
  logic   [AXI_ADDR_WIDTH-1:0] r_burst_addr_next;

  logic   [               7:0] r_burst_cnt;
  logic   [               7:0] r_burst_cnt_next;

  logic   [               7:0] r_data_cnt;
  logic   [               7:0] r_data_cnt_next;

  logic   [AXI_DATA_WIDTH-1:0] r_data_calc;

  logic   [AXI_DATA_WIDTH-1:0] r_data_actual;
  logic   [AXI_DATA_WIDTH-1:0] r_data_actual_next;

  logic   [AXI_DATA_WIDTH-1:0] r_data_expected_save;
  logic   [AXI_DATA_WIDTH-1:0] r_data_expected_save_next;

  logic                        m_axi_arvalid_next;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_araddr_next;
  logic   [               7:0] m_axi_arlen_next;

  logic   [               7:0] done_cnt;

  assign m_axi_awsize = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);
  assign m_axi_arsize = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);

  svc_ice40_axi_sram #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH)
  ) svc_ice40_axi_sram_i (
      .clk          (clk),
      .rst_n        (rst_n),
      .s_axi_awvalid(m_axi_awvalid),
      .s_axi_awaddr (m_axi_awaddr),
      .s_axi_awid   (),
      .s_axi_awlen  (m_axi_awlen),
      .s_axi_awsize (m_axi_awsize),
      .s_axi_awburst(2'b01),
      .s_axi_awready(m_axi_awready),
      .s_axi_wdata  (m_axi_wdata),
      .s_axi_wstrb  (m_axi_wstrb),
      .s_axi_wlast  (m_axi_wlast),
      .s_axi_wvalid (m_axi_wvalid),
      .s_axi_wready (m_axi_wready),
      .s_axi_bresp  (),
      .s_axi_bid    (),
      .s_axi_bvalid (m_axi_bvalid),
      .s_axi_bready (m_axi_bready),
      .s_axi_arvalid(m_axi_arvalid),
      .s_axi_araddr (m_axi_araddr),
      .s_axi_arid   (),
      .s_axi_arready(m_axi_arready),
      .s_axi_arlen  (m_axi_arlen),
      .s_axi_arsize (m_axi_arsize),
      .s_axi_arburst(2'b01),
      .s_axi_rdata  (m_axi_rdata),
      .s_axi_rresp  (),
      .s_axi_rvalid (m_axi_rvalid),
      .s_axi_rready (m_axi_rready),
      .s_axi_rlast  (m_axi_rlast),
      .s_axi_rid    (),
      .sram_io_addr (sram_io_addr),
      .sram_io_data (sram_io_data),
      .sram_io_we_n (sram_io_we_n),
      .sram_io_oe_n (sram_io_oe_n),
      .sram_io_ce_n (sram_io_ce_n)
  );

  //
  // Write state machine
  //

  assign m_axi_wstrb  = '1;
  assign m_axi_bready = 1'b1;

  assign w_data_calc  = BEAT_DATA_BASE + AXI_DATA_WIDTH'(w_data_cnt);

  always_comb begin
    w_state_next       = w_state;

    w_burst_addr_next  = w_burst_addr;
    w_burst_cnt_next   = w_burst_cnt;
    w_beat_cnt_next    = w_beat_cnt;
    w_data_cnt_next    = w_data_cnt;

    m_axi_awvalid_next = m_axi_awvalid && !m_axi_awready;
    m_axi_awaddr_next  = m_axi_awaddr;
    m_axi_awlen_next   = m_axi_awlen;

    m_axi_wvalid_next  = m_axi_wvalid && !m_axi_wready;
    m_axi_wdata_next   = m_axi_wdata;
    m_axi_wlast_next   = m_axi_wlast;

    r_enable_next      = r_enable;

    case (w_state)
      STATE_IDLE: begin
        w_state_next      = STATE_BURST_INIT;
        w_burst_addr_next = BURST_ADDR_BASE;
        w_burst_cnt_next  = 0;
        w_beat_cnt_next   = 0;
        w_data_cnt_next   = 0;
      end

      STATE_BURST_INIT: begin
        // When we loop around for a second+ burst, it might be the case that awready
        // was held low by the subordinate. Don't just assume we can start.
        if (!m_axi_awvalid || m_axi_awready) begin
          w_state_next       = STATE_BURST;

          m_axi_awvalid_next = 1'b1;
          m_axi_awaddr_next  = w_burst_addr;
          m_axi_awlen_next   = NUM_BEATS - 1;

          // TODO: There technically could be a protocol violation here on our
          // second+ burst. We are only here after receiving a bvalid/bready
          // for the last write, but that doesn't necessarily mean that the
          // sub finalized the w channel acknowledgment. The svc ones wouldn't
          // be like that, but logic should be added to address this.
          w_burst_cnt_next   = w_burst_cnt + 1;
          w_beat_cnt_next    = w_beat_cnt + 1;
          w_data_cnt_next    = w_data_cnt + 1;

          m_axi_wvalid_next  = 1'b1;
          m_axi_wdata_next   = w_data_calc;
          m_axi_wlast_next   = w_beat_cnt_next == NUM_BEATS;
        end
      end

      STATE_BURST: begin
        if (m_axi_wvalid && m_axi_wready) begin
          if (w_beat_cnt != NUM_BEATS) begin
            w_beat_cnt_next   = w_beat_cnt + 1;
            m_axi_wvalid_next = 1'b1;
            w_data_cnt_next   = w_data_cnt + 1;
            m_axi_wdata_next  = w_data_calc;
            m_axi_wlast_next  = w_beat_cnt_next == NUM_BEATS;
          end
        end

        if (m_axi_bvalid && m_axi_bready) begin
          if (w_burst_cnt != NUM_BURSTS) begin
            w_beat_cnt_next = 0;
            w_state_next = STATE_BURST_INIT;
            w_burst_addr_next = w_burst_addr + AXI_ADDR_WIDTH'(BYTES_PER_BURST);
          end else begin
            w_state_next = STATE_DONE;
          end
        end
      end

      STATE_DONE: begin
        r_enable_next = 1'b1;
        // w_state_next  = STATE_IDLE;
      end

      STATE_FAIL: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      w_state       <= STATE_IDLE;

      m_axi_awvalid <= 1'b0;
      m_axi_wvalid  <= 1'b0;

      r_enable      <= 1'b0;
    end else begin
      w_state       <= w_state_next;

      m_axi_awvalid <= m_axi_awvalid_next;
      m_axi_wvalid  <= m_axi_wvalid_next;

      r_enable      <= r_enable_next;
    end
  end

  always_ff @(posedge clk) begin
    w_burst_addr <= w_burst_addr_next;
    w_burst_cnt  <= w_burst_cnt_next;
    w_beat_cnt   <= w_beat_cnt_next;
    w_data_cnt   <= w_data_cnt_next;

    m_axi_awaddr <= m_axi_awaddr_next;
    m_axi_awlen  <= m_axi_awlen_next;
    m_axi_wdata  <= m_axi_wdata_next;
    m_axi_wlast  <= m_axi_wlast_next;
  end

  //
  // Read state machine
  //

  assign m_axi_rready = 1'b1;

  assign r_data_calc  = BEAT_DATA_BASE + AXI_DATA_WIDTH'(r_data_cnt);

  always_comb begin
    r_state_next              = r_state;

    r_burst_addr_next         = r_burst_addr;
    r_burst_cnt_next          = r_burst_cnt;
    r_data_cnt_next           = r_data_cnt;

    m_axi_arvalid_next        = m_axi_arvalid && !m_axi_arready;
    m_axi_araddr_next         = m_axi_araddr;
    m_axi_arlen_next          = m_axi_arlen;

    r_data_actual_next        = r_data_actual;
    r_data_expected_save_next = r_data_expected_save;

    test_done                 = 1'b0;
    test_pass                 = 1'b1;

    case (r_state)
      STATE_IDLE: begin
        r_burst_addr_next = BURST_ADDR_BASE;
        r_burst_cnt_next  = 0;
        r_data_cnt_next   = 0;

        if (r_enable) begin
          r_state_next = STATE_BURST_INIT;
        end
      end

      STATE_BURST_INIT: begin
        if (!m_axi_arvalid || m_axi_arready) begin
          r_state_next       = STATE_BURST;

          m_axi_arvalid_next = 1'b1;
          m_axi_araddr_next  = r_burst_addr;
          m_axi_arlen_next   = NUM_BEATS - 1;

          r_burst_cnt_next   = r_burst_cnt + 1;
        end
      end

      STATE_BURST: begin
        if (m_axi_rvalid && m_axi_rready) begin
          r_data_cnt_next           = r_data_cnt + 1;
          r_data_actual_next        = m_axi_rdata;
          r_data_expected_save_next = r_data_calc;
          if (m_axi_rdata != r_data_calc) begin
            r_state_next = STATE_FAIL;
          end else begin
            if (m_axi_rlast) begin
              if (r_burst_cnt != NUM_BURSTS) begin
                r_state_next = STATE_BURST_INIT;
                r_burst_addr_next = (r_burst_addr +
                                     AXI_ADDR_WIDTH'(BYTES_PER_BURST));
              end else begin
                r_state_next = STATE_DONE;
              end
            end
          end
        end
      end

      STATE_DONE: begin
        test_done    = 1'b1;
        r_state_next = STATE_IDLE;
      end

      STATE_FAIL: begin
        test_pass = 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      r_state       <= STATE_IDLE;
      m_axi_arvalid <= 1'b0;
    end else begin
      r_state       <= r_state_next;
      m_axi_arvalid <= m_axi_arvalid_next;
    end
  end

  always_ff @(posedge clk) begin
    r_burst_addr         <= r_burst_addr_next;
    r_burst_addr         <= r_burst_addr_next;
    r_burst_cnt          <= r_burst_cnt_next;
    r_data_cnt           <= r_data_cnt_next;
    r_data_actual        <= r_data_actual_next;
    r_data_expected_save <= r_data_expected_save_next;

    m_axi_araddr         <= m_axi_araddr_next;
    m_axi_arlen          <= m_axi_arlen_next;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      done_cnt <= 0;
    end else begin
      if (r_state == STATE_DONE) begin
        done_cnt <= done_cnt + 1;
      end
    end
  end

  assign debug0 = 8'(r_data_actual);
  assign debug1 = 8'(r_data_expected_save);
  assign debug2 = 8'(done_cnt);

endmodule

`endif
