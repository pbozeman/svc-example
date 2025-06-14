`ifndef MEM_TEST_AXI_SV
`define MEM_TEST_AXI_SV

`include "svc.sv"
`include "svc_unused.sv"

module mem_test_axi #(
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8,
    parameter NUM_BURSTS     = 8,
    parameter NUM_BEATS      = 3
) (
    input logic clk,
    input logic rst_n,

    // tester signals
    output logic test_done,
    output logic test_pass,

    // debug/output signals
    output logic [7:0] debug0,
    output logic [7:0] debug1,
    output logic [7:0] debug2,

    output logic                      m_axi_awvalid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_awaddr,
    output logic [  AXI_ID_WIDTH-1:0] m_axi_awid,
    output logic [               7:0] m_axi_awlen,
    output logic [               2:0] m_axi_awsize,
    output logic [               1:0] m_axi_awburst,
    input  logic                      m_axi_awready,
    output logic                      m_axi_wvalid,
    output logic [AXI_DATA_WIDTH-1:0] m_axi_wdata,
    output logic [AXI_STRB_WIDTH-1:0] m_axi_wstrb,
    output logic                      m_axi_wlast,
    input  logic                      m_axi_wready,
    input  logic                      m_axi_bvalid,
    input  logic [  AXI_ID_WIDTH-1:0] m_axi_bid,
    input  logic [               1:0] m_axi_bresp,
    output logic                      m_axi_bready,

    output logic                      m_axi_arvalid,
    output logic [  AXI_ID_WIDTH-1:0] m_axi_arid,
    output logic [AXI_ADDR_WIDTH-1:0] m_axi_araddr,
    output logic [               7:0] m_axi_arlen,
    output logic [               2:0] m_axi_arsize,
    output logic [               1:0] m_axi_arburst,
    input  logic                      m_axi_arready,
    input  logic                      m_axi_rvalid,
    input  logic [  AXI_ID_WIDTH-1:0] m_axi_rid,
    input  logic [AXI_DATA_WIDTH-1:0] m_axi_rdata,
    input  logic [               1:0] m_axi_rresp,
    input  logic                      m_axi_rlast,
    output logic                      m_axi_rready
);
  localparam DATA_WIDTH = AXI_DATA_WIDTH;

  localparam BURST_ADDR_BASE = AXI_ADDR_WIDTH'(8'h00);
  localparam BEAT_DATA_BASE = DATA_WIDTH'(8'hD0);

  localparam BYTES_PER_BEAT = AXI_DATA_WIDTH / 8;
  localparam BYTES_PER_BURST = BYTES_PER_BEAT * NUM_BEATS;

  typedef enum {
    STATE_IDLE,
    STATE_BURST_INIT,
    STATE_BURST,
    STATE_DONE,
    STATE_FAIL
  } state_t;

  state_t                      w_state;
  state_t                      w_state_next;

  logic   [AXI_ADDR_WIDTH-1:0] w_burst_addr;
  logic   [AXI_ADDR_WIDTH-1:0] w_burst_addr_next;

  logic   [              15:0] w_burst_cnt;
  logic   [              15:0] w_burst_cnt_next;

  logic   [               7:0] w_beat_cnt;
  logic   [               7:0] w_beat_cnt_next;

  logic   [               7:0] w_data_cnt;
  logic   [               7:0] w_data_cnt_next;

  logic   [    DATA_WIDTH-1:0] w_data_calc;

  logic                        m_axi_awvalid_next;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_awaddr_next;
  logic   [               7:0] m_axi_awlen_next;

  logic                        m_axi_wvalid_next;
  logic   [AXI_DATA_WIDTH-1:0] m_axi_wdata_next;
  logic                        m_axi_wlast_next;

  logic                        r_enable;
  logic                        r_enable_next;

  state_t                      r_state;
  state_t                      r_state_next;

  logic   [AXI_ADDR_WIDTH-1:0] r_burst_addr;
  logic   [AXI_ADDR_WIDTH-1:0] r_burst_addr_next;

  logic   [              15:0] r_burst_cnt;
  logic   [              15:0] r_burst_cnt_next;

  logic   [               7:0] r_data_cnt;
  logic   [               7:0] r_data_cnt_next;

  logic   [    DATA_WIDTH-1:0] r_data_calc;

  logic   [    DATA_WIDTH-1:0] r_data_actual;
  logic   [    DATA_WIDTH-1:0] r_data_actual_next;

  logic   [    DATA_WIDTH-1:0] r_data_expected_save;
  logic   [    DATA_WIDTH-1:0] r_data_expected_save_next;

  logic                        m_axi_arvalid_next;
  logic   [AXI_ADDR_WIDTH-1:0] m_axi_araddr_next;
  logic   [               7:0] m_axi_arlen_next;

  logic   [               7:0] done_cnt;

  assign m_axi_awsize  = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);
  assign m_axi_awid    = 0;
  assign m_axi_awburst = 2'b01;

  assign m_axi_arsize  = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);
  assign m_axi_arid    = 0;
  assign m_axi_arburst = 2'b01;

  //
  // Write state machine
  //
  assign m_axi_wstrb   = '1;
  assign m_axi_bready  = 1'b1;

  assign w_data_calc   = BEAT_DATA_BASE + DATA_WIDTH'(w_data_cnt);

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
          m_axi_wdata_next   = AXI_DATA_WIDTH'(w_data_calc);
          m_axi_wlast_next   = w_beat_cnt_next == NUM_BEATS;
        end
      end

      STATE_BURST: begin
        if (m_axi_wvalid && m_axi_wready) begin
          if (w_beat_cnt != NUM_BEATS) begin
            w_beat_cnt_next   = w_beat_cnt + 1;
            m_axi_wvalid_next = 1'b1;
            w_data_cnt_next   = w_data_cnt + 1;
            m_axi_wdata_next  = AXI_DATA_WIDTH'(w_data_calc);
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
        w_state_next  = STATE_IDLE;
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

  assign r_data_calc  = BEAT_DATA_BASE + DATA_WIDTH'(r_data_cnt);

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
          r_data_actual_next        = DATA_WIDTH'(m_axi_rdata);
          r_data_expected_save_next = r_data_calc;
          if (DATA_WIDTH'(m_axi_rdata) != r_data_calc) begin
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

  `SVC_UNUSED({m_axi_bid, m_axi_bresp, m_axi_rid, m_axi_rresp, m_axi_rdata});

endmodule

`endif
