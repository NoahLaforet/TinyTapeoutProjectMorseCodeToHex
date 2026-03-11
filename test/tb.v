`default_nettype none
`timescale 1ns / 1ps

module tb;

  reg        clk, rst_n, ena;
  reg  [7:0] ui_in, uio_in;
  wire [7:0] uo_out, uio_out, uio_oe;

`ifdef GL_TEST
  wire VPWR = 1'b1;
  wire VGND = 1'b0;

  tt_um_morse_to_hex dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n),
    .VPWR   (VPWR),
    .VGND   (VGND)
  );
`else
  tt_um_morse_to_hex dut (
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
  );
`endif

  initial clk = 0;
  always #5 clk = ~clk;

  integer pass_count, fail_count;

  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);

    pass_count = 0;
    fail_count = 0;

    // Hold reset for 20 cycles (GL needs longer than RTL)
    rst_n = 0; ena = 1; ui_in = 8'h00; uio_in = 8'h00;
    repeat(20) @(posedge clk);
    rst_n = 1;
    repeat(5) @(posedge clk);

    // =========================================================================
    // TEST 1: E  ->  .
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1111001 && uo_out[7]===1'b0)
      begin $display("[PASS] E  | input: .        | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] E  | input: .        | got ssd=%07b err=%b | exp ssd=1111001 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 2: A  ->  . -
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1110111 && uo_out[7]===1'b0)
      begin $display("[PASS] A  | input: .-       | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] A  | input: .-       | got ssd=%07b err=%b | exp ssd=1110111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 3: D  ->  - . .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1011110 && uo_out[7]===1'b0)
      begin $display("[PASS] D  | input: -..      | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] D  | input: -..      | got ssd=%07b err=%b | exp ssd=1011110 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 4: B  ->  - . . .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1111100 && uo_out[7]===1'b0)
      begin $display("[PASS] B  | input: -...     | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] B  | input: -...     | got ssd=%07b err=%b | exp ssd=1111100 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 5: C  ->  - . - .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b0111001 && uo_out[7]===1'b0)
      begin $display("[PASS] C  | input: -.-.     | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] C  | input: -.-.     | got ssd=%07b err=%b | exp ssd=0111001 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 6: F  ->  . . - .
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1110001 && uo_out[7]===1'b0)
      begin $display("[PASS] F  | input: ..-.     | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] F  | input: ..-.     | got ssd=%07b err=%b | exp ssd=1110001 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 7: 0  ->  - - - - -
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b0111111 && uo_out[7]===1'b0)
      begin $display("[PASS] 0  | input: -----    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 0  | input: -----    | got ssd=%07b err=%b | exp ssd=0111111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 8: 1  ->  . - - - -
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b0000110 && uo_out[7]===1'b0)
      begin $display("[PASS] 1  | input: .----    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 1  | input: .----    | got ssd=%07b err=%b | exp ssd=0000110 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 9: 2  ->  . . - - -
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1011011 && uo_out[7]===1'b0)
      begin $display("[PASS] 2  | input: ..---    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 2  | input: ..---    | got ssd=%07b err=%b | exp ssd=1011011 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 10: 3  ->  . . . - -
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1001111 && uo_out[7]===1'b0)
      begin $display("[PASS] 3  | input: ...--    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 3  | input: ...--    | got ssd=%07b err=%b | exp ssd=1001111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 11: 4  ->  . . . . -
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1100110 && uo_out[7]===1'b0)
      begin $display("[PASS] 4  | input: ....-    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 4  | input: ....-    | got ssd=%07b err=%b | exp ssd=1100110 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 12: 5  ->  . . . . .
    // =========================================================================
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1101101 && uo_out[7]===1'b0)
      begin $display("[PASS] 5  | input: .....    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 5  | input: .....    | got ssd=%07b err=%b | exp ssd=1101101 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 13: 6  ->  - . . . .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1111101 && uo_out[7]===1'b0)
      begin $display("[PASS] 6  | input: -....    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 6  | input: -....    | got ssd=%07b err=%b | exp ssd=1111101 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 14: 7  ->  - - . . .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b0000111 && uo_out[7]===1'b0)
      begin $display("[PASS] 7  | input: --...    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 7  | input: --...    | got ssd=%07b err=%b | exp ssd=0000111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 15: 8  ->  - - - . .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1111111 && uo_out[7]===1'b0)
      begin $display("[PASS] 8  | input: ---..    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 8  | input: ---..    | got ssd=%07b err=%b | exp ssd=1111111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 16: 9  ->  - - - - .
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[0]=1; @(posedge clk); @(negedge clk); ui_in[0]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[6:0]===7'b1100111 && uo_out[7]===1'b0)
      begin $display("[PASS] 9  | input: ----.    | ssd=%07b  err=%b", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] 9  | input: ----.    | got ssd=%07b err=%b | exp ssd=1100111 err=0", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // TEST 17: INVALID  ->  - - - -
    // =========================================================================
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[1]=1; @(posedge clk); @(negedge clk); ui_in[1]=0; @(posedge clk);
    @(negedge clk); ui_in[2]=1; @(posedge clk); @(negedge clk); ui_in[2]=0; @(posedge clk);
    #1;
    if (uo_out[7]===1'b1)
      begin $display("[PASS] ?  | input: ----     | ssd=%07b  err=%b  (error LED high as expected)", uo_out[6:0], uo_out[7]); pass_count=pass_count+1; end
    else
      begin $display("[FAIL] ?  | input: ----     | got ssd=%07b err=%b | exp err=1 (no morse match)", uo_out[6:0], uo_out[7]); fail_count=fail_count+1; end
    @(negedge clk); ui_in[3]=1; @(posedge clk); @(negedge clk); ui_in[3]=0; @(posedge clk);

    // =========================================================================
    // Summary
    // =========================================================================
    $display("----------------------------------------");
    $display("Results: %0d passed, %0d failed", pass_count, fail_count);
    if (fail_count == 0) begin
      $display("ALL TESTS PASSED");
      $finish;
    end else begin
      $display("SOME TESTS FAILED");
      $fatal(1, "Test suite failed with %0d failure(s)", fail_count);
    end
  end

endmodule