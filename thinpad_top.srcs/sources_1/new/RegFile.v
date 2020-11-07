`timescale 1ns / 1ps
`default_nettype none

module RegFile(input wire clk,
               input wire rst,
               input wire regWr,          // 1 for write enable
               input wire[4:0] rs1,
               rs2,
               rd,
               input wire[31:0] inData,
               output wire[31:0] rs1Data,
               rs2Data);
    
    reg[31:0] registers[31:0];
    
    assign rs1Data = registers[rs1];
    assign rs2Data = registers[rs2];
    
    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i<32; i = i+1) begin
                registers[i] = 32'b0;
            end
        end
        else
            if (regWr) begin
                Regs[rd] = data;
            end
            registers[0] = 32'b0;
    end
    
endmodule
