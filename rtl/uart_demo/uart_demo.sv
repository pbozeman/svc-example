`ifndef UART_DEMO_SV
`define UART_DEMO_SV

`include "svc.sv"
`include "svc_str_iter.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"

module uart_demo #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200
) (
    input logic clk,
    input logic rst_n,

    input  logic urx_pin,
    output logic utx_pin
);
  localparam STR_MAX_LEN = 128;
  localparam MSG_WIDTH = 8 * STR_MAX_LEN;

  typedef enum {
    STATE_IDLE,
    STATE_HELLO,
    STATE_HELLO_WAIT,
    STATE_ECHO
  } state_t;

  state_t                 state;

  logic                   utx_en;
  logic   [          7:0] utx_data;
  logic                   utx_busy;

  logic                   urx_valid;
  logic   [          7:0] urx_data;

  logic                   str_valid;
  logic   [MSG_WIDTH-1:0] str_msg;
  logic                   str_ready;

  logic                   chr_valid;
  logic   [          7:0] chr_data;
  logic                   chr_ready;

  logic                   echo_valid;
  logic   [          7:0] echo_data;

  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) svc_uart_rx_i (
      .clk  (clk),
      .rst_n(rst_n),

      .urx_valid(urx_valid),
      .urx_data (urx_data),

      .urx_pin(urx_pin)
  );

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

  always_ff @(posedge clk) begin
    if (!rst_n) begin
      state      <= STATE_IDLE;
      str_valid  <= 1'b0;
      echo_valid <= 1'b0;
      echo_data  <= 0;
    end else begin
      str_valid  <= str_valid && !str_ready;
      echo_valid <= echo_valid && !utx_busy;

      case (state)
        STATE_IDLE: begin
          state <= STATE_HELLO;
        end

        STATE_HELLO: begin
          str_valid <= 1'b1;
          str_msg   <= "Hello - to upper:\r\n";
          state     <= STATE_HELLO_WAIT;
        end

        STATE_HELLO_WAIT: begin
          // looking at str_ready here would be broken under normal
          // ready/valid handshake rules, because it wouldn't necessarily mean
          // that all the bytes were sent, just that it's ready to receive
          // more.. but with the current implementation, it's ok to do this.
          // This is probably a sign that the str iter needs a different api
          // that exposes when the iteration actually completed.
          if (str_ready) begin
            state <= STATE_ECHO;
          end
        end

        STATE_ECHO: begin
          if (urx_valid) begin
            echo_valid <= 1'b1;

            // to upper
            // a = 61, z = 7a
            // a - A = 8'h20;
            if (urx_data >= 8'h61 && urx_data <= 8'h7A) begin
              echo_data <= urx_data - 8'h20;
            end else begin
              echo_data <= urx_data;
            end
          end
        end
      endcase

    end
  end

  // This is a janky mux between the hello string and the data we received and
  // did a toupper on. It's fine for a demo.
  assign chr_ready = !utx_busy;
  assign utx_en    = (!utx_busy && (chr_valid || echo_valid));
  assign utx_data  = (state != STATE_ECHO ? chr_data : echo_data);

endmodule
`endif
