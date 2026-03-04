/*
 * Copyright (c) 2024 Noah Laforet
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_morse_to_hex (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  // ==========================================================================
  // Button edge detection
  // --------------------------------------------------------------------------
  // Each button needs a one-cycle rising-edge pulse so that holding a button
  // only registers a single input, no matter how long it is held.
  //
  // How it works:
  //   - *_prev stores what the button read last clock cycle
  //   - *_rise is HIGH only when the button is currently HIGH but was LOW last
  //     cycle (i.e., the exact cycle the button transitions 0->1)
  //   - Every subsequent cycle while held, both the input and *_prev are HIGH,
  //     so *_rise goes back LOW until the button is released and re-pressed
  // ==========================================================================
  reg dot_prev, dash_prev, confirm_prev, clear_prev;

  wire dot_rise     = ui_in[0] & ~dot_prev;   // dot button clicked
  wire dash_rise    = ui_in[1] & ~dash_prev;   // dash button clicked
  wire confirm_rise = ui_in[2] & ~confirm_prev; // confirm/decode clicked
  wire clear_rise   = ui_in[3] & ~clear_prev;  // clear/reset clicked

  // Capture button state each cycle for next-cycle comparison
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      dot_prev     <= 1'b0;
      dash_prev    <= 1'b0;
      confirm_prev <= 1'b0;
      clear_prev   <= 1'b0;
    end else begin
      dot_prev     <= ui_in[0];
      dash_prev    <= ui_in[1];
      confirm_prev <= ui_in[2];
      clear_prev   <= ui_in[3];
    end
  end

  // ==========================================================================
  // Morse input buffer and symbol counter
  // --------------------------------------------------------------------------
  // buffer: 5-bit shift register holding the current morse sequence.
  //   Each new symbol shifts in at the MSB (bit 4) and existing bits move
  //   right. Dots are stored as 0, dashes as 1.
  //   Example building "A" (dot then dash):
  //     After dot:  buffer = 00000, count = 1
  //     After dash: buffer = 10000, count = 2
  //   morseToHex uses {count, buffer} to identify the sequence.
  //
  // count: tracks how many symbols have been entered (max 5).
  //   Used alongside buffer to distinguish sequences of different lengths
  //   that share the same bit pattern (e.g. 5-dot "5" vs 1-dot "E").
  // ==========================================================================
  reg [4:0] buffer;
  reg [2:0] count;

  // ==========================================================================
  // Decoded output registers
  // --------------------------------------------------------------------------
  // hex_latched: holds the last successfully confirmed hex digit (0-F).
  //   Stays on the display until clear is pressed or a new confirm happens.
  // error: set HIGH when confirm is pressed on an unrecognised morse sequence.
  //   Drives the error LED on uo_out[7].
  // ==========================================================================
  reg [3:0] hex_latched;
  reg       error;

  // ==========================================================================
  // Morse-to-hex lookup (combinational, from morseToHex.v)
  // --------------------------------------------------------------------------
  // Always decoding the *current* buffer/count combinationally.
  // hex_decoded and valid update instantly as symbols are entered,
  // but we only latch them into hex_latched/error on a confirm press.
  // ==========================================================================
  wire [3:0] hex_decoded;
  wire       valid;

  morseToHex lookup (
    .count_i (count),       // how many symbols are in the buffer
    .buffer_i(buffer),      // the symbol shift register
    .hex_o   (hex_decoded), // decoded hex digit (0-F)
    .valid_o (valid)        // 1 if the pattern matches a known morse code
  );

  // ==========================================================================
  // 7-segment display encoder (combinational, from hexto7seg.v)
  // --------------------------------------------------------------------------
  // hex2ssd outputs active-HIGH segment signals (1 = segment on).
  // TinyTapeout's demo board expects active-HIGH on uo_out[6:0],
  // so ssd_raw is assigned directly with no inversion.
  // ==========================================================================
  wire [6:0] ssd_raw;

  hex2ssd ssd (
    .hex_i(hex_latched), // the latched hex digit to display
    .ssd_o(ssd_raw)      // active-HIGH segment pattern (GFEDCBA)
  );

  // ==========================================================================
  // Main state machine
  // --------------------------------------------------------------------------
  // Handles all state transitions on each rising clock edge.
  // Button priority (highest to lowest): clear > confirm > dot/dash
  //   - clear:   resets everything back to initial state
  //   - confirm: latches the current decode result onto the display
  //   - dot:     shifts 0 into buffer MSB, increments count
  //   - dash:    shifts 1 into buffer MSB, increments count
  // dot/dash are ignored once count reaches 5 (max morse length).
  // ==========================================================================
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      buffer      <= 5'b0;
      count       <= 3'b0;
      hex_latched <= 4'b0;
      error       <= 1'b0;
    end else begin
      if (clear_rise) begin
        // Reset all state; display goes blank (shows '0' since hex_latched=0)
        buffer      <= 5'b0;
        count       <= 3'b0;
        hex_latched <= 4'b0;
        error       <= 1'b0;
      end else if (confirm_rise) begin
        // Decode current buffer and lock result onto display
        hex_latched <= hex_decoded;
        error       <= ~valid; // light error LED if no morse match found
      end else if (dot_rise && count < 3'd5) begin
        // Shift 0 (dot) into MSB of buffer, push existing bits right
        buffer <= {1'b0, buffer[4:1]};
        count  <= count + 1'b1;
      end else if (dash_rise && count < 3'd5) begin
        // Shift 1 (dash) into MSB of buffer, push existing bits right
        buffer <= {1'b1, buffer[4:1]};
        count  <= count + 1'b1;
      end
    end
  end

  // ==========================================================================
  // Output assignments
  // ==========================================================================

  // uo_out[6:0]: 7-seg segments, active-high (1 = segment on, direct from hex2ssd)
  // uo_out[7]:   error LED, HIGH when last confirm was an invalid sequence
  assign uo_out  = {error, ssd_raw};

  // uio_out[4:0]: morse buffer LEDs — shows which symbols have been entered
  //               (1=dash, 0=dot); only positions 0..count-1 are meaningful
  // uio_out[7:5]: symbol count — how many morse symbols are currently buffered
  assign uio_out = {count, buffer};

  // Set all bidirectional pins as outputs (1 = output mode)
  assign uio_oe  = 8'hFF;

  // Tie off unused inputs to prevent synthesis warnings
  wire _unused = &{ena, uio_in, ui_in[7:4], 1'b0};

endmodule
