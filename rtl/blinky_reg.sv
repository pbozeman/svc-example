`ifndef BLINKY_REG_SV
`define BLINKY_REG_SV

`include "svc_accumulator.sv"
`include "svc_skidbuf.sv"

// Example of a memory mapped blinky controller.
//
// It's a somewhat contrived example, but allows it to expose a few
// registers, some RW and some RO for basic demo/testing of a module
// with memory mapped control registers.
//
// Addr                  Data
// 0x00       RW         Flags:
//                                      0:   enable (0 disabled, 1 enabled),
//                                      1:   blink  (0 solid, 1 blink)
//                                      2-31: reserved: values are don't care
// 0x01       RW         cnt_toggle:    toggle led at cnt_toggle
// 0x02       RO         clock_freq:    clock frequency in cycles per second
// 0x03       RO         cnt:           current value of the counter
// 0x04       RO         led:           current value of the led
//
// 0x04-0xFF             reserved

module blinky_reg #(
    parameter CLK_FREQ = 100_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic led,

    input  logic [ 7:0] s_axil_awaddr,
    input  logic        s_axil_awvalid,
    output logic        s_axil_awready,
    input  logic [31:0] s_axil_wdata,
    input  logic [ 3:0] s_axil_wstrb,
    input  logic        s_axil_wvalid,
    output logic        s_axil_wready,
    output logic        s_axil_bvalid,
    output logic [ 1:0] s_axil_bresp,
    input  logic        s_axil_bready,

    input  logic        s_axil_arvalid,
    input  logic [ 7:0] s_axil_araddr,
    output logic        s_axil_arready,
    output logic        s_axil_rvalid,
    output logic [31:0] s_axil_rdata,
    output logic [ 1:0] s_axil_rresp,
    input  logic        s_axil_rready
);
  //--------------------------------------------------------------------------
  //
  // The blinky
  //
  //--------------------------------------------------------------------------

  localparam DEFAULT_CNT_TOGGLE = CLK_FREQ / 2;

  logic [31:0] cnt_toggle;
  logic [31:0] cnt_toggle_next;

  logic [31:0] cnt;
  logic        cnt_clr;

  logic        flag_enable;
  logic        flag_enable_next;

  logic        flag_blink;
  logic        flag_blink_next;

  // This wasn't intended to be a timing demo, but once this is used with
  // a debug bridge in the design, the 32 bit add could not meet timing on
  // an ice40. Hence, the usage of the pipelined accumulator.
  svc_accumulator #(
      .WIDTH(32)
  ) svc_accumulator_i (
      .clk  (clk),
      .rst_n(rst_n),
      .clr  (cnt_clr),
      .en   (1'b1),
      .val  (1),
      .acc  (cnt)
  );

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      led     <= 1'b0;
      cnt_clr <= 1'b1;
    end else begin
      if (!flag_enable) begin
        led     <= 1'b0;
        cnt_clr <= 1'b1;
      end else begin
        cnt_clr <= 1'b0;
        if (!flag_blink) begin
          led <= 1'b1;
        end else if (cnt == cnt_toggle) begin
          cnt_clr <= 1'b1;
          led     <= ~led;
        end
      end
    end
  end

  //--------------------------------------------------------------------------
  //
  // The control interface
  //
  //--------------------------------------------------------------------------

  //
  // control interface writes
  //
  logic        sb_awvalid;
  logic [ 7:0] sb_awaddr;
  logic        sb_awready;

  logic        sb_wvalid;
  logic [31:0] sb_wdata;
  logic [ 3:0] sb_wstrb;
  logic        sb_wready;

  logic        s_axil_bvalid_next;
  logic [ 1:0] s_axil_bresp_next;

  svc_skidbuf #(
      .DATA_WIDTH(8)
  ) svc_skidbuf_aw (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(s_axil_awvalid),
      .i_data (s_axil_awaddr),
      .o_ready(s_axil_awready),

      .o_valid(sb_awvalid),
      .o_data (sb_awaddr),
      .i_ready(sb_awready)
  );

  svc_skidbuf #(
      .DATA_WIDTH(32 + 4)
  ) svc_skidbuf_w (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(s_axil_wvalid),
      .i_data ({s_axil_wstrb, s_axil_wdata}),
      .o_ready(s_axil_wready),

      .o_valid(sb_wvalid),
      .o_data ({sb_wstrb, sb_wdata}),
      .i_ready(sb_wready)
  );

  always_comb begin
    sb_awready         = 1'b0;
    sb_wready          = 1'b0;

    s_axil_bvalid_next = s_axil_bvalid && !s_axil_bready;
    s_axil_bresp_next  = s_axil_bresp;

    flag_blink_next    = flag_blink;
    flag_enable_next   = flag_enable;
    cnt_toggle_next    = cnt_toggle;

    // do both an incoming check and outgoing check here,
    // since we are going to set bvalid
    if (sb_awvalid && sb_wvalid && (!s_axil_bvalid || s_axil_bready)) begin
      sb_awready         = 1'b1;
      sb_wready          = 1'b1;
      s_axil_bvalid_next = 1'b1;
      s_axil_bresp_next  = 2'b00;

      // we only accept full writes
      if (sb_wstrb != '1) begin
        s_axil_bresp_next = 2'b10;
      end else begin
        case (sb_awaddr)
          8'h00:   {flag_blink_next, flag_enable_next} = 2'(sb_wdata);
          8'h01:   cnt_toggle_next = sb_wdata;
          8'h02:   s_axil_bresp_next = 2'b10;
          8'h03:   s_axil_bresp_next = 2'b10;
          8'h04:   s_axil_bresp_next = 2'b10;
          default: s_axil_bresp_next = 2'b11;
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axil_bvalid <= 1'b0;

      flag_enable   <= 1'b0;
      flag_blink    <= 1'b0;
      cnt_toggle    <= DEFAULT_CNT_TOGGLE;
    end else begin
      s_axil_bvalid <= s_axil_bvalid_next;
      flag_blink    <= flag_blink_next;
      flag_enable   <= flag_enable_next;
      cnt_toggle    <= cnt_toggle_next;
    end
  end

  always_ff @(posedge clk) begin
    s_axil_bresp <= s_axil_bresp_next;
  end

  //
  // control interface reads
  //
  logic        sb_arvalid;
  logic [ 7:0] sb_araddr;
  logic        sb_arready;

  logic        s_axil_rvalid_next;
  logic [31:0] s_axil_rdata_next;
  logic [ 1:0] s_axil_rresp_next;

  svc_skidbuf #(
      .DATA_WIDTH(8)
  ) svc_skidbuf_ar (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(s_axil_arvalid),
      .i_data (s_axil_araddr),
      .o_ready(s_axil_arready),

      .o_valid(sb_arvalid),
      .o_data (sb_araddr),
      .i_ready(sb_arready)
  );

  always_comb begin
    sb_arready         = 1'b0;
    s_axil_rvalid_next = s_axil_rvalid && !s_axil_rready;
    s_axil_rdata_next  = s_axil_rdata;
    s_axil_rresp_next  = s_axil_rresp;

    // do both an incoming check and outgoing check here,
    // since we are going to set rvalid
    if (sb_arvalid && (!s_axil_rvalid || !s_axil_rready)) begin
      sb_arready         = 1'b1;
      s_axil_rvalid_next = 1'b1;

      s_axil_rresp_next  = 2'b00;
      case (sb_araddr)
        8'h00:   s_axil_rdata_next = 32'({flag_blink, flag_enable});
        8'h01:   s_axil_rdata_next = cnt_toggle;
        8'h02:   s_axil_rdata_next = CLK_FREQ;
        8'h03:   s_axil_rdata_next = cnt;
        8'h04:   s_axil_rdata_next = 32'(led);
        default: s_axil_rresp_next = 2'b11;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axil_rvalid <= 1'b0;
    end else begin
      s_axil_rvalid <= s_axil_rvalid_next;
    end
  end

  always_ff @(posedge clk) begin
    s_axil_rdata <= s_axil_rdata_next;
    s_axil_rresp <= s_axil_rresp_next;
  end

endmodule
`endif
