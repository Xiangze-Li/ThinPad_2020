`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/11/08 14:33:20
// Design Name: 
// Module Name: Decoder
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


module Decoder(
    input wire [31:0]   inst,
    input wire          flagZ,
    input wire [2:0]    stage,

    output reg          pcWr,
    output reg          pcNowWr,
    output reg          pcSel,
    output reg          ramSel,
    output reg          ramWr,
    output reg          ramRd,
    output reg[1:0]    ramByte,
    output reg          irWr,
    output reg [1:0]    regDSel,
    output reg [2:0]    immSel,
    output reg          regWr,
    output reg [1:0]    aluASel,
    output reg [1:0]    aluBSel,
    output wire [2:0]    func3,
    output wire [6:0]    func7,

    output reg [2:0]    stageNext
    );

    parameter [2:0]
    // Stages
        IDLE = 3'b000,
        IF = 3'b001,
        ID  = 3'b010,
        EXE = 3'b011,
        MEM = 3'b100,
        WB  = 3'b101,
        ERR = 3'b111;
    
    parameter [6:0]
    // OpCode
        OP_R        = 7'b0110011,
        OP_I        = 7'b0010011,
        OP_S        = 7'b0100011,
        OP_L        = 7'b0000011,
        OP_B        = 7'b1100011,
        // opcodes below not used in exp-5
        //OP_LOAD     = 7'b0000011,
        OP_JALR     = 7'b1100111,
        OP_JAL      = 7'b1101111,
        OP_AUIPC    = 7'b0010111,
        OP_LUI      = 7'b0110111;

    assign func3 = inst[14:12];
    assign func7 = inst[31:25];

    wire [6:0]  opCode;
    assign opCode = inst[6:0];

    parameter [2:0]
        IMM_N = 3'b000,
        // immSel
        IMM_I = 3'b001,
        IMM_S = 3'b010,
        IMM_B = 3'b011,
        IMM_U = 3'b100,
        IMM_J = 3'b101;

    always @(*) begin
        case (stage)
        // 每个阶段为当前阶段准备控制信号!
            IF : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 1'b1;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b1;
                ramByte     <= func3[1:0];
                irWr        <= 1'b1;
                regDSel     <= 2'b11;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b00;
                aluBSel     <= 2'b00;
            end
            ID : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 1'b1;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= func3[1:0];
                irWr        <= 1'b0;
                regDSel     <= 2'b11;
                immSel      <= IMM_B;
                regWr       <= 1'b0;
                aluASel     <= 2'b01;
                aluBSel     <= 2'b10;
            end
            EXE : begin
                case (opCode)
                    OP_R : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                    end
                    OP_I : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                    end
                    OP_S : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                    end
                    OP_B : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                    end
                    OP_JAL : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_J;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b00; //PC
                        aluBSel     <= 2'b10; //imm
                    end
                    OP_JALR : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10; //rs1
                        aluBSel     <= 2'b10; //imm
                    end
                    OP_LUI : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11; //不选择
                        aluBSel     <= 2'b10; //imm
                    end
                    OP_AUIPC : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11; //不选择
                        aluBSel     <= 2'b10; //imm
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'bX;
                        ramSel      <= 1'bX;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'bXX;
                        immSel      <= 3'bXXX;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                    end
                endcase
            end
            MEM : begin
                case (opCode)
                    OP_S : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b1;
                        ramWr       <= 1'b1;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b1;
                        ramWr       <= 1'b1;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                    end
                endcase
            end
            WB : begin
                case (opCode)
                    OP_I, OP_R : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b01; //写回rd
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b00; //写回ram中的数据
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                    end
                    OP_JALR, OP_JAL : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b10; //写回pc+4
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                    end
                    OP_LUI, OP_AUIPC : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b10; //写回rd
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b1;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                    end
                endcase
            end
            default : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 1'b1;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b11;
                irWr        <= 1'b0;
                regDSel     <= 2'b11;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'bXX;
                aluBSel     <= 2'bXX;
            end
        endcase
    end

    always @(*) begin
    // Next Stage Gen.
        case (stage)
            IF :
                stageNext = ID;
            ID  :
                stageNext = EXE;
            EXE : begin
                case (opCode)
                    OP_R, OP_I  : stageNext = WB;
                    OP_JAL      : stageNext = WB;
                    OP_JALR     : stageNext = WB;
                    OP_AUIPC    : stageNext = WB;
                    OP_LUI      : stageNext = WB;
                    OP_L, OP_S  : stageNext = MEM;
                    OP_B        : stageNext = IF;
                    default     : stageNext = ERR;
                endcase
            end
            MEM : begin
                case (opCode)
                    OP_S : stageNext = IF;
                    OP_L : stageNext = WB;
                    default: stageNext = ERR;
                endcase
            end
            WB :
                stageNext = IF;
            default:
                stageNext = ERR;
        endcase
    end

endmodule
