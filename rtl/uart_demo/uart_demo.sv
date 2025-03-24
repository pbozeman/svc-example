`ifndef UART_DEMO_SV
`define UART_DEMO_SV

`include "svc.sv"
`include "svc_str.sv"
`include "svc_str_iter.sv"
`include "svc_uart_tx.sv"

module uart_demo #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input  logic clk,
    input  logic rst_n,
    output logic utx_pin
);
  localparam STR_MAX_LEN = 128;
  localparam MSG_WIDTH = 8 * STR_MAX_LEN;

  logic                 utx_en;
  logic [          7:0] utx_data;
  logic                 utx_busy;

  logic                 str_valid;
  logic [MSG_WIDTH-1:0] str_msg;
  logic                 str_ready;

  logic                 chr_valid;
  logic [          7:0] chr_data;
  logic                 chr_ready;

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

  svc_str_iter #(
      .MAX_STR_LEN(STR_MAX_LEN)
  ) svc_str_iter_i (
      .clk      (clk),
      .rst_n    (rst_n),
      .s_valid  (str_valid),
      .s_msg    (str_msg),
      .s_bin    (1'b0),
      .s_bin_len('0),
      .s_ready  (str_ready),
      .m_valid  (chr_valid),
      .m_char   (chr_data),
      .m_ready  (chr_ready)
  );

  assign chr_ready = !utx_busy;
  assign utx_en    = chr_valid && !utx_busy;
  assign utx_data  = chr_data;

  // This is a little janky and would be better with a state machine,
  // but it's fine for a demo
  logic first_done;
  logic second_done;

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      second_done <= 1'b0;
      first_done  <= 1'b0;
      str_valid   <= 1'b0;
    end else begin
      if (!str_valid || str_ready) begin
        if (!first_done) begin
          first_done <= 1'b1;
          str_valid  <= 1'b1;
          `SVC_STR_INIT(str_msg, "First\r\n");
        end else if (!second_done) begin
          second_done <= 1'b1;
          str_valid   <= 1'b1;
          `SVC_STR_INIT(str_msg, "Second\r\n");
        end else begin
          str_valid <= 1'b0;
        end
      end
    end
  end

endmodule
`endif
