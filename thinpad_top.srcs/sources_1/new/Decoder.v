`timescale 1ns / 1ps
`default_nettype none

module Decoder(
    input wire [31:0]   inst,
    input wire          flagZ,
    input wire [2:0]    stage,

    input wire          mode,

    input wire          addrMisal,
    input wire          addrFault,

    output reg          pcWr,
    output reg          pcNowWr,
    output reg [1:0]    pcSel,
    output reg          ramSel,
    output reg          ramWr,
    output reg          ramRd,
    output reg [1:0]    ramByte,
    output reg          irWr,
    output reg [2:0]    regDSel,
    output reg [2:0]    immSel,
    output reg          regWr,
    output reg [1:0]    aluASel,
    output reg [1:0]    aluBSel,
    output reg [2:0]    func3,
    output reg [6:0]    func7,
    output reg          aluRI,

    output reg          exceptFlag,
    output reg          retFlag,
    output reg [31:0]   mcauseIn,
    output reg [1:0]    csrWrOp,

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
        EXC = 3'b110, //exception
        ERR = 3'b111;

    parameter [6:0]
    // OpCode
        OP_R        = 7'b0110011,
        OP_I        = 7'b0010011,
        OP_S        = 7'b0100011,
        OP_L        = 7'b0000011,
        OP_B        = 7'b1100011,
        OP_JALR     = 7'b1100111,
        OP_JAL      = 7'b1101111,
        OP_AUIPC    = 7'b0010111,
        OP_LUI      = 7'b0110111,
        OP_SYS      = 7'b1110011;

    wire [6:0]  opCode, funct7;
    wire [2:0]  funct3;
    wire [11:0] funct12;


    assign opCode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign funct12 = inst[31:20];

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
            IF : begin
                pcWr        <= 1'b1;
                pcNowWr     <= 1'b1;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b1;
                ramByte     <= 2'b10;
                irWr        <= 1'b1;
                regDSel     <= 3'b011;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b00;
                aluBSel     <= 2'b00;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;
                retFlag     <= 1'b0;
                csrWrOp     <= 2'b00;
            end
            ID : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b10;
                irWr        <= 1'b0;
                regDSel     <= 3'b011;
                immSel      <= IMM_B;
                regWr       <= 1'b0;
                aluASel     <= 2'b01;
                aluBSel     <= 2'b10;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;
                retFlag     <= 1'b0;
                csrWrOp     <= 2'b00;
            end
            EXE : begin
                case (opCode)
                    OP_R : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        aluRI       <= 1'b0;
                        func3       <= funct3;
                        func7       <= funct7;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_I : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b1;
                        func3       <= funct3;
                        func7       <= funct7;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_S : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_B : begin
                        pcWr        <=
                            (funct3 == 3'b000) ? flagZ : (
                            (funct3 == 3'b001) ? ~flagZ : 1'b0);
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0100000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_JAL : begin
                        pcWr        <= 1'b1;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b010;
                        immSel      <= IMM_J;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b01;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_JALR : begin //JALR EXE
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10; //rs1
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_AUIPC : begin //AUIPC EXE
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b01;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'bXX;
                        ramSel      <= 1'bX;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'bXXX;
                        immSel      <= 3'bXXX;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        aluRI       <= 1'bX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                        exceptFlag  <= 1'bX;
                        retFlag     <= 1'bX;
                        csrWrOp     <= 2'bXX;
                    end
                endcase
            end
            MEM : begin
                case (opCode)
                    OP_S : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b1;
                        ramWr       <= 1'b1;
                        ramRd       <= 1'b0;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b1;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b1;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'bXX;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'bX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                        exceptFlag  <= 1'bX;
                        retFlag     <= 1'bX;
                        csrWrOp     <= 2'bXX;
                    end
                endcase
            end
            WB : begin
                case (opCode)
                    OP_I, OP_R : begin //OP_I, OP_R
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b001;
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b000;
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_JALR : begin //JALR PC<-C rd<-PC
                        pcWr        <= 1'b1;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00; //PC<-C
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b010;
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_LUI : begin //LUI rd<-imm
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011; //rd<-imm
                        immSel      <= IMM_U;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_AUIPC : begin //AUIPC rd<-C
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b001;
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;
                        retFlag     <= 1'b0;
                        csrWrOp     <= 2'b00;
                    end
                    OP_SYS : begin
                        case (funct3)
                            3'b000 : begin //mret
                                pcWr        <= 1'b1;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b11;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= 2'b11;
                                irWr        <= 1'b0;
                                regDSel     <= 3'b001;
                                immSel      <= IMM_N;
                                regWr       <= 1'b0;
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                aluRI       <= 1'b0;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;
                                retFlag     <= 1'b1;
                                csrWrOp     <= 2'b00;
                            end
                            default: begin //csr
                                pcWr        <= 1'b0;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b01;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= 2'b11;
                                irWr        <= 1'b0;
                                regDSel     <= 3'b100;
                                immSel      <= IMM_N;
                                regWr       <= 1'b1;
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                aluRI       <= 1'b0;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;
                                retFlag     <= 1'b0;
                                csrWrOp     <= funct3[1:0];
                            end
                        endcase
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        aluRI       <= 1'bX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                        exceptFlag  <= 1'bX;
                        retFlag     <= 1'bX;
                        csrWrOp     <= 2'bXX;
                    end
                endcase
            end
            EXC : begin
                pcWr        <= 1'b1;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b10;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b11;
                irWr        <= 1'b0;
                regDSel     <= 3'b001;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b11;
                aluBSel     <= 2'b11;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b1;
                retFlag     <= 1'b0;
                csrWrOp     <= 2'b00;
            end
            default : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b11;
                irWr        <= 1'b0;
                regDSel     <= 3'b011;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'bXX;
                aluBSel     <= 2'bXX;
                aluRI       <= 1'bX;
                func3       <= 3'bXXX;
                func7       <= 7'bXXXXXXX;
                exceptFlag  <= 1'bX;
                retFlag     <= 1'bX;
                csrWrOp     <= 2'bXX;
            end
        endcase
    end

    always @(*) begin
    // Next Stage Gen.
        mcauseIn = 32'hffffffff;
        case (stage)
            IDLE :
                stageNext = IF;
            IF : begin
                case ({addrFault, addrMisal})
                    2'b00   : stageNext = ID;
                    2'b01   : begin // instruction address misaligned
                        stageNext = EXC;
                        mcauseIn = 32'h00000000;
                    end
                    2'b10   : begin // instruction address fault
                        stageNext = EXC;
                        mcauseIn = 32'h00000001;
                    end
                    default : stageNext = ERR;
                endcase
            end
            ID : begin
                case (opCode)
                    OP_R        : stageNext = EXE;
                    OP_I        : stageNext = EXE;
                    OP_L        : stageNext = EXE;
                    OP_S        : stageNext = EXE;
                    OP_B        : stageNext = EXE;
                    OP_JAL      : stageNext = EXE;
                    OP_JALR     : stageNext = EXE;
                    OP_LUI      : stageNext = WB;
                    OP_AUIPC    : stageNext = EXE;
                    OP_SYS      : begin
                        case (funct3)
                            3'b000 : begin
                                case (funct12)
                                    12'b000000000000 : begin // ECALL from U
                                        stageNext = EXC;
                                        mcauseIn = 32'h00000008;
                                    end
                                    12'b000000000001 : begin // EBREAK
                                        stageNext = EXC;
                                        mcauseIn = 32'h00000003;
                                    end
                                    12'b001100000010 : begin // MRET
                                        case (mode)
                                            1'b1:
                                                stageNext = WB;
                                            1'b0: begin
                                                stageNext = EXC;
                                                mcauseIn = 32'h00000002;
                                            end
                                        endcase
                                    end
                                    default : stageNext = IF;
                                endcase
                            end
                            default : begin // CSRXX
                                case (mode)
                                    1'b1: stageNext = WB;
                                    1'b0: begin
                                        stageNext = EXC;
                                        mcauseIn = 32'h00000002;
                                    end
                                endcase
                            end
                        endcase
                    end
                    default     : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000002;
                    end //illegal instruction
                endcase
            end
            EXE : begin
                case (opCode)
                    OP_R        : stageNext = WB;
                    OP_I        : stageNext = WB;
                    OP_L        : stageNext = MEM;
                    OP_S        : stageNext = MEM;
                    OP_B        : stageNext = IF;
                    OP_JAL      : stageNext = IF;
                    OP_JALR     : stageNext = WB;
                    OP_AUIPC    : stageNext = WB;
                    default     : stageNext = ERR;
                endcase
            end
            MEM : begin
                case ({addrFault, addrMisal, opCode})
                    {2'b00, OP_L}       : stageNext = WB;
                    {2'b00, OP_S}       : stageNext = IF;
                    {2'b01, OP_L}       : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000004;
                    end //load address misaligned
                    {2'b01, OP_S}       : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000006;
                    end //store address misaligned
                    {2'b10, OP_L}       : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000005;
                    end //load address fault
                    {2'b10, OP_S}       : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000007;
                    end //store address fault
                    default: stageNext = ERR;
                endcase
            end
            WB :
                stageNext = IF;
            EXC :
                stageNext = IF;
            default:
                stageNext = ERR;
        endcase
    end

endmodule
