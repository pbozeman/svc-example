`ifndef AXI_PERF_SV
`define AXI_PERF_SV

`include "svc.sv"
`include "svc_axi_stats_wr.sv"
`include "svc_hex_fmt_stream.sv"
`include "svc_print.sv"
`include "svc_uart_tx.sv"

`include "axi_perf_wr.sv"


// This is still a bit hacky and still in POC phase for both stats and how
// reporting is going to work

// verilator lint_off: UNUSEDPARAM
// verilator lint_off: UNUSEDSIGNAL
// verilator lint_off: UNDRIVEN
module axi_perf #(
    parameter NAME           = "axi_perf",
    parameter CLOCK_FREQ     = 100_000_000,
    parameter CLOCK_FREQ_STR = "100",
    parameter BAUD_RATE      = 115_200,
    parameter AXI_ADDR_WIDTH = 20,
    parameter AXI_DATA_WIDTH = 16,
    parameter AXI_ID_WIDTH   = 4,
    parameter AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8,
    parameter STAT_WIDTH     = 32
) (
    input logic clk,
    input logic rst_n,

    output logic utx_pin,

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
    output logic                      m_axi_bready
);
  localparam AW = AXI_ADDR_WIDTH;
  localparam SW = STAT_WIDTH;

  // vivado doesn't support \r in a string, so this is the work around. (the
  // \r becomes just r)
  localparam CRLF = 16'h0D0A;

  typedef enum {
    STATE_IDLE,
    STATE_HEADER,
    STATE_HEADER_WAIT,
    STATE_RUN,
    STATE_RUN_WAIT,
    STATE_REPORT,
    STATE_REPORT_ITER,
    STATE_REPORT_ITER_SEND,
    STATE_REPORT_ITER_SEND_WAIT,
    STATE_REPORT_ITER_SEND_DONE,
    STATE_DONE
  } state_t;

  state_t            state;
  state_t            state_next;

  logic              utx_en;
  logic   [     7:0] utx_data;
  logic              utx_busy;

  logic              wr_start;
  logic              wr_busy;

  logic   [  AW-1:0] wr_base_addr;
  logic   [     7:0] wr_burst_beats;
  logic   [  AW-1:0] wr_burst_stride;
  logic   [    15:0] wr_burst_num;
  logic   [     2:0] wr_burst_awsize;

  logic              stat_iter_start;
  logic              stat_iter_valid;
  logic   [     7:0] stat_iter_id;
  logic   [  SW-1:0] stat_iter_val;
  logic              stat_iter_last;
  logic              stat_iter_ready;

  logic              fmt_iter_valid;
  logic   [     7:0] fmt_iter_id;
  logic   [SW*2-1:0] fmt_iter_val_str;
  logic   [ 8*2-1:0] fmt_iter_id_str;
  logic              fmt_iter_last;
  logic              fmt_iter_ready;

  assign wr_base_addr    = 0;
  assign wr_burst_beats  = 64;
  assign wr_burst_stride = 128 * (AXI_DATA_WIDTH / 8);
  assign wr_burst_num    = 16;
  assign wr_burst_awsize = `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);

  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_tx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .utx_en  (utx_en),
      .utx_data(utx_data),
      .utx_busy(utx_busy),

      .utx_pin(utx_pin)
  );

  axi_perf_wr #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH)
  ) axi_perf_wr_i (
      .clk  (clk),
      .rst_n(rst_n),

      .start(wr_start),
      .busy (wr_busy),

      .base_addr   (wr_base_addr),
      .burst_beats (wr_burst_beats),
      .burst_stride(wr_burst_stride),
      .burst_num   (wr_burst_num),
      .burst_awsize(wr_burst_awsize),

      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wlast  (m_axi_wlast),
      .m_axi_wready (m_axi_wready),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bid    (m_axi_bid),
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bready (m_axi_bready)
  );

  svc_axi_stats_wr #(
      .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
      .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
      .AXI_ID_WIDTH  (AXI_ID_WIDTH),
      .STAT_WIDTH    (STAT_WIDTH)
  ) svc_axi_stats_wr_i (
      .clk  (clk),
      .rst_n(rst_n),

      .stat_clear(1'b0),
      .stat_err  (),

      .stat_iter_start(stat_iter_start),
      .stat_iter_valid(stat_iter_valid),
      .stat_iter_id   (stat_iter_id),
      .stat_iter_val  (stat_iter_val),
      .stat_iter_last (stat_iter_last),
      .stat_iter_ready(stat_iter_ready),

      .m_axi_awvalid(m_axi_awvalid),
      .m_axi_awaddr (m_axi_awaddr),
      .m_axi_awid   (m_axi_awid),
      .m_axi_awlen  (m_axi_awlen),
      .m_axi_awsize (m_axi_awsize),
      .m_axi_awburst(m_axi_awburst),
      .m_axi_awready(m_axi_awready),
      .m_axi_wvalid (m_axi_wvalid),
      .m_axi_wdata  (m_axi_wdata),
      .m_axi_wstrb  (m_axi_wstrb),
      .m_axi_wlast  (m_axi_wlast),
      .m_axi_wready (m_axi_wready),
      .m_axi_bvalid (m_axi_bvalid),
      .m_axi_bid    (m_axi_bid),
      .m_axi_bresp  (m_axi_bresp),
      .m_axi_bready (m_axi_bready)
  );

  svc_hex_fmt_stream #(
      .WIDTH     (STAT_WIDTH),
      .USER_WIDTH(1 + 8)
  ) svc_hex_fmt_stream_i (
      .clk  (clk),
      .rst_n(rst_n),

      .s_valid(stat_iter_valid),
      .s_data (stat_iter_val),
      .s_user ({stat_iter_last, stat_iter_id}),
      .s_ready(stat_iter_ready),

      .m_valid(fmt_iter_valid),
      .m_data (fmt_iter_val_str),
      .m_user ({fmt_iter_last, fmt_iter_id}),
      .m_ready(fmt_iter_ready)
  );

  svc_hex_fmt #(
      .WIDTH(8)
  ) svc_hex_fmt_i (
      .val  (fmt_iter_id),
      .ascii(fmt_iter_id_str)
  );

  `SVC_PRINT_INIT(utx_en, utx_data, utx_busy);

  always_comb begin
    state_next      = state;
    wr_start        = 1'b0;

    stat_iter_start = 1'b0;
    fmt_iter_ready  = 1'b0;

    case (state)
      STATE_IDLE: begin
        state_next = STATE_HEADER;
      end

      STATE_HEADER: begin
        state_next = STATE_HEADER_WAIT;
      end

      STATE_HEADER_WAIT: begin
        if (!`SVC_PRINT_BUSY) begin
          state_next = STATE_RUN;
        end
      end

      STATE_RUN: begin
        wr_start   = 1'b1;
        state_next = STATE_RUN_WAIT;
      end

      STATE_RUN_WAIT: begin
        if (!wr_busy) begin
          state_next = STATE_REPORT;
        end
      end

      STATE_REPORT: begin
        stat_iter_start = 1'b1;
        state_next      = STATE_REPORT_ITER;
      end

      STATE_REPORT_ITER: begin
        if (fmt_iter_valid) begin
          state_next = STATE_REPORT_ITER_SEND;
        end
      end

      STATE_REPORT_ITER_SEND: begin
        state_next = STATE_REPORT_ITER_SEND_WAIT;
      end

      STATE_REPORT_ITER_SEND_WAIT: begin
        if (!`SVC_PRINT_BUSY) begin
          state_next = STATE_REPORT_ITER_SEND_DONE;
        end
      end

      STATE_REPORT_ITER_SEND_DONE: begin
        fmt_iter_ready = 1'b1;
        if (!fmt_iter_last) begin
          state_next = STATE_REPORT_ITER;
        end else begin
          state_next = STATE_DONE;
        end
      end

      STATE_DONE: begin
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state <= STATE_IDLE;
    end else begin
      state <= state_next;
    end
  end

  always @(posedge clk) begin
    `SVC_PRINT_INIT_FF;

    case (state)
      STATE_HEADER: begin
        `SVC_PRINT({
                   CRLF,
                   "AXI perf",
                   CRLF,
                   " name: ",
                   NAME,
                   CRLF,
                   " freq: ",
                   CLOCK_FREQ_STR,
                   CRLF
                   });
      end

      STATE_REPORT_ITER_SEND: begin
        // TODO: this is on the edge of not meeting timing due to the hex
        // conversions and moving around a bunch of bits. Ultimately, this
        // will all need get swapped out conversions that generate a char
        // at a time that get sent to the uart directly.
        `SVC_PRINT({" ", fmt_iter_id_str, ": 0x", fmt_iter_val_str, CRLF});
      end

      default: begin
      end
    endcase
  end

endmodule
`endif
