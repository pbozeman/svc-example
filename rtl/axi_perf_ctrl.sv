`ifndef AXI_PERF_CTRL_SV
`define AXI_PERF_CTRL_SV

`include "svc.sv"
`include "svc_skidbuf.sv"
`include "svc_unused.sv"

// TODO: this same pattern is used in the blinky_reg demo and in the top level
// axi_perf controller. They are all the same other than the name of the
// signals and if each is r/w. Given that this is a few hundred lines,
// consider moving it to a parameterized module. It could take N reg and then
// the have an array of register values. RW can be passed in as a bitmap, or,
// there could be both a _rd and _wr version that gets instantiated
// separately, or the r/w reg could have a cutoff where everything above
// a particular index is ro. Let the actual usage and larger ecosystem settle
// down and then factor something out here.
module axi_perf_ctrl #(
    parameter AXI_ADDR_WIDTH  = 20,
    parameter AXI_DATA_WIDTH  = 16,
    parameter AXIL_ADDR_WIDTH = 32,
    parameter AXIL_DATA_WIDTH = 32,
    parameter AXIL_STRB_WIDTH = AXIL_DATA_WIDTH / 8
) (
    input logic clk,
    input logic rst_n,

    output logic [AXI_ADDR_WIDTH-1:0] base_addr,
    output logic [               7:0] burst_beats,
    output logic [AXI_ADDR_WIDTH-1:0] burst_stride,
    output logic [               2:0] burst_awsize,
    output logic [              15:0] burst_num,

    input  logic [AXIL_ADDR_WIDTH-1:0] s_axil_awaddr,
    input  logic                       s_axil_awvalid,
    output logic                       s_axil_awready,
    input  logic [AXIL_DATA_WIDTH-1:0] s_axil_wdata,
    input  logic [AXIL_STRB_WIDTH-1:0] s_axil_wstrb,
    input  logic                       s_axil_wvalid,
    output logic                       s_axil_wready,
    output logic                       s_axil_bvalid,
    output logic [                1:0] s_axil_bresp,
    input  logic                       s_axil_bready,

    input  logic                       s_axil_arvalid,
    input  logic [AXIL_ADDR_WIDTH-1:0] s_axil_araddr,
    output logic                       s_axil_arready,
    output logic                       s_axil_rvalid,
    output logic [AXIL_DATA_WIDTH-1:0] s_axil_rdata,
    output logic [                1:0] s_axil_rresp,
    input  logic                       s_axil_rready
);
  localparam AW = AXI_ADDR_WIDTH;

  localparam R_AW = AXIL_ADDR_WIDTH;
  localparam R_DW = AXIL_DATA_WIDTH;
  localparam R_SW = AXIL_STRB_WIDTH;

  // convert byte addr to word addr (reg idx)
  parameter R_ADDRLSB = $clog2(AXIL_DATA_WIDTH) - 3;
  parameter R_W = R_AW - R_ADDRLSB;

  typedef enum logic [R_W-1:0] {
    REG_BASE_ADDR    = 0,
    REG_BURST_BEATS  = 1,
    REG_BURST_STRIDE = 2,
    REG_BURST_AWSIZE = 3,
    REG_BURST_NUM    = 4
  } reg_id_t;

  logic [    AW-1:0] base_addr_next;
  logic [       7:0] burst_beats_next;
  logic [    AW-1:0] burst_stride_next;
  logic [       2:0] burst_awsize_next;
  logic [      15:0] burst_num_next;

  //
  // control interface writes
  //
  logic              sb_awvalid;
  logic [   R_W-1:0] sb_wreg;
  logic              sb_awready;

  logic              sb_wvalid;
  logic [  R_DW-1:0] sb_wdata;
  logic [R_SW-1 : 0] sb_wstrb;
  logic              sb_wready;

  logic              s_axil_bvalid_next;
  logic [       1:0] s_axil_bresp_next;

  svc_skidbuf #(
      .DATA_WIDTH(R_W)
  ) svc_skidbuf_aw (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(s_axil_awvalid),
      .i_data (s_axil_awaddr[R_AW-1:R_ADDRLSB]),
      .o_ready(s_axil_awready),

      .o_valid(sb_awvalid),
      .o_data (sb_wreg),
      .i_ready(sb_awready)
  );

  svc_skidbuf #(
      .DATA_WIDTH(R_DW + R_SW)
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

    base_addr_next     = base_addr;
    burst_beats_next   = burst_beats;
    burst_stride_next  = burst_stride;
    burst_awsize_next  = burst_awsize;
    burst_num_next     = burst_num;

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
        case (sb_wreg)
          REG_BASE_ADDR:    base_addr_next = AW'(sb_wdata);
          REG_BURST_BEATS:  burst_beats_next = 8'(sb_wdata);
          REG_BURST_STRIDE: burst_stride_next = AW'(sb_wdata);
          REG_BURST_AWSIZE: burst_awsize_next = 3'(sb_wdata);
          REG_BURST_NUM:    burst_num_next = 16'(sb_wdata);
          default:          s_axil_bresp_next = 2'b11;
        endcase
      end
    end
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      s_axil_bvalid <= 1'b0;
    end else begin
      s_axil_bvalid <= s_axil_bvalid_next;
    end
  end

  always_ff @(posedge clk) begin
    s_axil_bresp <= s_axil_bresp_next;
  end

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      base_addr    <= 0;
      burst_beats  <= 64;
      burst_stride <= 128 * (AXI_DATA_WIDTH / 8);
      burst_awsize <= `SVC_MAX_AXSIZE(AXI_DATA_WIDTH);
      burst_num    <= 16;
    end else begin
      base_addr    <= base_addr_next;
      burst_beats  <= burst_beats_next;
      burst_stride <= burst_stride_next;
      burst_awsize <= burst_awsize_next;
      burst_num    <= burst_num_next;
    end
  end

  //
  // control interface reads
  //
  logic            sb_arvalid;
  logic [ R_W-1:0] sb_rreg;
  logic            sb_arready;

  logic            s_axil_rvalid_next;
  logic [R_DW-1:0] s_axil_rdata_next;
  logic [     1:0] s_axil_rresp_next;

  svc_skidbuf #(
      .DATA_WIDTH(R_W)
  ) svc_skidbuf_ar (
      .clk  (clk),
      .rst_n(rst_n),

      .i_valid(s_axil_arvalid),
      .i_data (s_axil_araddr[R_AW-1:R_ADDRLSB]),
      .o_ready(s_axil_arready),

      .o_valid(sb_arvalid),
      .o_data (sb_rreg),
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
      case (sb_rreg)
        REG_BASE_ADDR:    s_axil_rdata_next = R_DW'(base_addr);
        REG_BURST_BEATS:  s_axil_rdata_next = R_DW'(burst_beats);
        REG_BURST_STRIDE: s_axil_rdata_next = R_DW'(burst_stride);
        REG_BURST_AWSIZE: s_axil_rdata_next = R_DW'(burst_awsize);
        REG_BURST_NUM:    s_axil_rdata_next = R_DW'(burst_num);
        default:          s_axil_rresp_next = 2'b11;
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

  `SVC_UNUSED({s_axil_araddr[R_ADDRLSB-1:0], s_axil_awaddr[R_ADDRLSB-1:0],
               sb_wdata});

endmodule
`endif
