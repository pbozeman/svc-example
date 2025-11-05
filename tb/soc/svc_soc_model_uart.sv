`ifndef SVC_SOC_MODEL_UART_SV
`define SVC_SOC_MODEL_UART_SV

`include "svc.sv"
`include "svc_uart_rx.sv"
`include "svc_uart_tx.sv"

// UART model for SoC-level testbenches
//
// This module simulates a UART peripheral/terminal connected to a SoC.
// It monitors the SoC's UART TX output and can drive the SoC's UART RX input.
//
// Features:
// - Automatic RX monitoring with optional character printing (uses svc_uart_rx)
// - TX tasks for sending characters/strings to the SoC
// - Character buffering for verification
// - Statistics tracking
//
// Based on patterns from svc_uart_{rx,tx}_tb.sv and svc_model_sram.sv

module svc_soc_model_uart #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115_200,
    parameter PRINT_RX   = 1,
    parameter DEBUG      = 0
) (
    input  logic clk,
    input  logic rst_n,
    output logic urx_pin,
    input  logic utx_pin
);
  // Statistics and buffers
  int         rx_char_count;
  int         tx_char_count;

  logic [7:0] rx_buffer     [$];

  // UART RX signals
  logic       urx_valid;
  logic [7:0] urx_data;
  logic       urx_ready;

  // UART TX signals
  logic       utx_valid;
  logic [7:0] utx_data;
  logic       utx_ready;

  // Initialize
  initial begin
    urx_ready = 1'b1;  // Always ready to receive
    utx_valid = 1'b0;  // Start with no TX data
    utx_data  = 8'h00;
  end

  //
  // RX Monitor - uses svc_uart_rx to watch utx_pin (SoC's TX output)
  //
  svc_uart_rx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) uart_rx_inst (
      .clk      (clk),
      .rst_n    (rst_n),
      .urx_valid(urx_valid),
      .urx_data (urx_data),
      .urx_ready(urx_ready),
      .urx_pin  (utx_pin)
  );

  // Capture received characters
  // Note: Using blocking assignments (=) for immediate visibility in testbench
  // tasks/functions. This is testbench-only code, not synthesizable.
  // verilator lint_off BLKSEQ
  always @(posedge clk) begin
    if (!rst_n) begin
      rx_char_count = 0;
      tx_char_count = 0;
      rx_buffer.delete();
    end else if (urx_valid && urx_ready) begin
      rx_buffer.push_back(urx_data);
      rx_char_count = rx_char_count + 1;

      if (PRINT_RX) begin
        // Print character (handle special chars)
        if (urx_data == 8'h0A) begin
          $display("");
        end else if (urx_data == 8'h0D) begin
          // Ignore CR (we'll handle CRLF with just LF)
        end else if (urx_data >= 8'h20 && urx_data <= 8'h7E) begin
          $write("%c", urx_data);
        end else if (DEBUG) begin
          $write("[0x%02h]", urx_data);
        end
      end

      if (DEBUG) begin
        $display("[UART MODEL] RX: 0x%02h ('%c') at time %0t", urx_data,
                 urx_data, $time);
      end
    end
  end
  // verilator lint_on BLKSEQ

  //
  // TX Driver - uses svc_uart_tx to drive urx_pin (SoC's RX input)
  //
  svc_uart_tx #(
      .CLOCK_FREQ(CLOCK_FREQ),
      .BAUD_RATE (BAUD_RATE)
  ) uart_tx_inst (
      .clk      (clk),
      .rst_n    (rst_n),
      .utx_valid(utx_valid),
      .utx_data (utx_data),
      .utx_ready(utx_ready),
      .utx_pin  (urx_pin)     // Connect to SoC's RX input
  );

  //
  // TX Tasks
  //

  // Send a single byte via UART
  task automatic send_byte(input logic [7:0] data);
    if (DEBUG) begin
      $display("[UART MODEL] TX: 0x%02h ('%c') at time %0t", data, data, $time);
    end

    // Wait for TX to be ready
    while (!utx_ready) begin
      @(posedge clk);
    end

    // Start transmission
    utx_valid = 1'b1;
    utx_data  = data;
    @(posedge clk);

    // Wait for handshake
    while (!utx_ready) begin
      @(posedge clk);
    end

    utx_valid = 1'b0;
    tx_char_count++;
  endtask

  // Send a single character (alias for send_byte)
  task automatic send_char(input logic [7:0] data);
    send_byte(data);
  endtask

  // Send a string
  task automatic send_string(input string str);
    for (int i = 0; i < str.len(); i++) begin
      send_byte(str[i]);
    end
  endtask

  //
  // Utility tasks
  //

  // Get received character from buffer (blocks if empty)
  task automatic get_rx_char(output logic [7:0] char_out);
    while (rx_buffer.size() == 0) begin
      @(posedge clk);
    end
    char_out = rx_buffer.pop_front();
  endtask

  // Check if RX buffer has data
  function automatic int has_rx_data();
    return rx_buffer.size();
  endfunction

  // Clear RX buffer
  task automatic clear_rx_buffer();
    rx_buffer = {};
  endtask

  // Wait for specific number of characters to be received
  task automatic wait_rx_count(input int count);
    while (rx_char_count < count) begin
      @(posedge clk);
    end
  endtask

endmodule

`endif
