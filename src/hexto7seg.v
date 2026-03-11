`default_nettype none
// adapted from .sv to .v from previous use in cse125
/*
 * Copyright (c) 2024 Noah Laforet
 * SPDX-License-Identifier: Apache-2.0
 */

module hexto7seg (
    input  wire [3:0] hex_i,
    output wire [6:0] ssd_o
);

    reg [6:0] ssd_l;

    always @(*) begin
        case (hex_i)        // active HIGH - GFEDCBA (1 = segment on)
            4'h0 : ssd_l = 7'b0111111;
            4'h1 : ssd_l = 7'b0000110;
            4'h2 : ssd_l = 7'b1011011;
            4'h3 : ssd_l = 7'b1001111;
            4'h4 : ssd_l = 7'b1100110;
            4'h5 : ssd_l = 7'b1101101;
            4'h6 : ssd_l = 7'b1111101;
            4'h7 : ssd_l = 7'b0000111;
            4'h8 : ssd_l = 7'b1111111;
            4'h9 : ssd_l = 7'b1100111;
            4'ha : ssd_l = 7'b1110111;
            4'hb : ssd_l = 7'b1111100;
            4'hc : ssd_l = 7'b0111001;
            4'hd : ssd_l = 7'b1011110;
            4'he : ssd_l = 7'b1111001;
            4'hf : ssd_l = 7'b1110001;
            default : ssd_l = 7'b0000000;
        endcase
    end

    assign ssd_o = ssd_l;

endmodule