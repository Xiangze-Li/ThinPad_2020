`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/08 14:24:08
// Design Name: 
// Module Name: ImmGen
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ImmGen(
    input wire[31:0]    inst,
    input wire[2:0]     immSel,

    output reg[31:0]    immOut
    );

    parameter [2:0]
        IMM_I = 3'b001,
        IMM_S = 3'b010,
        IMM_B = 3'b011,
        IMM_U = 3'b100,
        IMM_J = 3'b101;

    wire[31:0] immI, immS, immB, immU, immJ;

    assign immI = { {21{inst[31]}}, inst[30:25], inst[24:21], inst[20] };
    assign immS = { {21{inst[31]}}, inst[30:25], inst[11:8], inst[7] };
    assign immB = { {20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0 };
    assign immU = { inst[31], inst[30:20], inst[19:12], 12'b0 };
    assign immJ = { {12{inst[31]}}, inst[19:12], inst[20], inst[30:25], inst[24:21], 1'b0 };

    always @(*)
        case (immSel)
            IMM_I : immOut = immI;
            IMM_S : immOut = immS;
            IMM_B : immOut = immB;
            IMM_U : immOut = immU;
            IMM_J : immOut = immJ;
            default:immOut = 32'hFFFF_FFFF;
        endcase
endmodule
