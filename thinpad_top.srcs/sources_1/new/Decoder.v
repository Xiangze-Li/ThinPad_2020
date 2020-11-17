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
    //ExceptionHandler的输出项
    input wire          mode, //用来标记当前机器态？
    //ramController传来的关于地址错误的信号
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
    output reg [1:0]    regDSel,
    output reg [2:0]    immSel,
    output reg          regWr,
    output reg [1:0]    aluASel,
    output reg [1:0]    aluBSel,
    output reg [2:0]    func3,
    output reg [6:0]    func7,
    output reg          aluRI,
    //下列全部是ExcepHandler的输入项
    output reg          exceptFlag,
    output reg [31:0]   mcauseIn, //根据异常原因给出
    output reg          csrRd,//读使能
    output reg [1:0]    csrWrOp,//写入选项

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
        EXC = 3'b110; //exception 异常处理状态
        ERR = 3'b111;

    parameter [6:0]
    // OpCode
        OP_R        = 7'b0110011,
        OP_I        = 7'b0010011,
        OP_S        = 7'b0100011,
        OP_L        = 7'b0000011,
        OP_B        = 7'b1100011,
        // opcodes below not used in exp-5
        OP_JALR     = 7'b1100111,
        OP_JAL      = 7'b1101111,
        OP_AUIPC    = 7'b0010111,
        OP_LUI      = 7'b0110111;
        //异常中断指令
        OP_SYS      = 7'b1110011;

    wire [6:0]  opCode, funct7;
    wire [2:0]  funct3;
    wire [11:0] funct12;
    

    assign opCode = inst[6:0];
    assign funct3 = inst[14:12];
    assign funct7 = inst[31:25];
    assign funct7 = inst[31:20];

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
                pcWr        <= 1'b1;
                pcNowWr     <= 1'b1;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b1;
                ramByte     <= 2'b10; //IF阶段按字读取指令
                irWr        <= 1'b1;
                regDSel     <= 2'b11;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b00;
                aluBSel     <= 2'b00;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
            end
            ID : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b11; //ID阶段不访存
                irWr        <= 1'b0;
                regDSel     <= 2'b11;
                immSel      <= IMM_N; //为啥选了个B？
                regWr       <= 1'b0;
                aluASel     <= 2'b01;
                aluBSel     <= 2'b10;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        aluRI       <= 1'b0;
                        func3       <= funct3;
                        func7       <= funct7;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b1;
                        func3       <= funct3;
                        func7       <= funct7;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_B : begin
                        pcWr        <= (funct3 == 3'b000)? flagZ : ((funct3 == 3'b001)? ~flagZ : 1'b0); //beq则结果为0时改写，bne则结果不为0时改写
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0100000; //branch指令需要将两个数相减判断结果是否为0
                    end
                    OP_JAL : begin //JAL按照ppt的架构需要在EXE周期同时写入寄存器和pc
                        pcWr        <= 1'b1; //写PC
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01; //选择ALU的运算结果
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b10; //JAL要将pc+4写入rd
                        immSel      <= IMM_J;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b01; // not PC, but PC_NOW
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_JALR : begin //JALR EXE周期只做ALU运算
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10; //rs1
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    //LUI直接进入WB周期
                    /*OP_LUI : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 1'b0;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11; //不选择
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end*/
                    OP_AUIPC : begin //AUIPC EXE周期计算pc+imm
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b01; //选择pc_now
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'bXX;
                        immSel      <= 3'bXXX;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        aluRI       <= 1'bX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'bXX;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'bXX;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'bX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                    end
                endcase
            end
            WB : begin
                case (opCode)
                    OP_I, OP_R : begin //OP_I, OP_R 将regC写回rd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b01; //选择regC写回rd
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_L : begin //OP_L类型将DR写回rd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 2'b00; //写回ram中的数据
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'b10; //写回pc+4
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'b11; //rd<-imm
                        immSel      <= IMM_U;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
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
                        regDSel     <= 2'b01; //rd<-C（ pc + imm）
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_SYS : begin
                        case (funct3)
                            3'b00 : begin//mret指令
                                pcWr        <= 1'b1;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b11;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= func3[1:0];
                                irWr        <= 1'b0;
                                regDSel     <= 2'b01; //rd<-C（ pc + imm）
                                immSel      <= IMM_N;
                                regWr       <= 1'b0; //mret 不用写寄存器
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0//未发生异常
                                csrRd       <= 1'b0;//不需要读
                                csrWrOp     <= 2'b00;//不需要写
                            end
                            default: begin //csr指令
                                pcWr        <= 1'b0;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b01;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= func3[1:0];
                                irWr        <= 1'b0;
                                regDSel     <= 2'b01; //rd<-C（ pc + imm）
                                immSel      <= IMM_N;
                                regWr       <= 1'b0; //mret 不用写寄存器
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0//未发生异常
                                csrRd       <= 1'b1;//需要读
                                csrWrOp     <= funct3[1:0];//需要写
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
                        regDSel     <= 2'b11;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        aluRI       <= 1'b0;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                    end
                endcase
            end
            EXC : begin //此处进行异常处理
                pcWr        <= 1'b1; //修改PC值（跳转到mtevc对应的地址）
                pcNowWr     <= 1'b0; //不修改pcNow?用来存进mepc里？
                pcSel       <= 2'b10;//对应的异常处理地址
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= func3[1:0];//这个东西在不用的时候默认是多少？
                irWr        <= 1'b0;
                regDSel     <= 2'b11; //这个时候不用写入寄存器
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b11;
                aluBSel     <= 2'b11;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b1//发生异常
                csrRd       <= 1'b0;//不需要读
                csrWrOp     <= 2'b00;//不需要写
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
                regDSel     <= 2'b11;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'bXX;
                aluBSel     <= 2'bXX;
                aluRI       <= 1'bX;
                func3       <= 3'bXXX;
                func7       <= 7'bXXXXXXX;
                csrRd       <= 1'b0;//不需要读
                csrWrOp     <= 2'b00;//不需要写
            end
        endcase
    end

    /*always @(*) begin
    // Next Stage Gen.
        case (stage)
            IDLE :
                stageNext = IF;
            IF :
                stageNext = ID;
            ID  :
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
                    default     : stageNext = ERR;
                endcase
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
                case (opCode)
                    OP_L : stageNext = WB;
                    OP_S : stageNext = IF;
                    default: stageNext = ERR;
                endcase
            end
            WB :
                stageNext = IF;
            default:
                stageNext = ERR;
        endcase
    end*/

    always @(*) begin
    // Next Stage Gen.
    mcauseIn = 32h'ffffffff
        case (stage)
            IDLE :
                stageNext = IF;
            IF :
                case ({addrFault, addrMisal})
                    2'b00       : stageNext = ID;
                    2'b01       : stageNext = EXC; mcauseIn = 32'h00000000; //instruction address misaligned
                    2'b10       : stageNext = EXC; mcauseIn = 32'h00000001; //instruction address fault
                    default: stageNext = ERR;
                endcase 
            ID  :
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
                    OP_SYS      : 
                        case (funct3)
                            3'b000 : 
                                case (funct12)
                                    12'b000000000000 : stageNext = EXC; mcauseIn = 32'h00000008; //environment call from U-mode
                                    12'b000000000001 : stageNext = EXC; mcauseIn = 32'h00000003; //breakpoint
                                    12'b001100000010 : stageNext = WB; //mret
                                    default: stageNext = ERR; //其他情况则为未定义指令
                                endcase
                            default: stageNext = WB; //csr指令
                        endcase
                    //OP_ECALL    : stageNext = EXC; mcauseIn = 32'h00000008; //environment call from U-mode
                    //OP_EBREAK   : stageNext = EXC; mcauseIn = 32'h00000003; //breakpoint
                    default     : stageNext = EXC; mcauseIn = 32'h00000002; //illegal instruction
                endcase
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
                    {2'b01, OP_L}       : begin stageNext = EXC; mcauseIn = 32'h00000004;end //load address misaligned
                    {2'b01, OP_S}       : stageNext = EXC; mcauseIn = 32'h00000006; //store address misaligned
                    {2'b10, OP_L}       : stageNext = EXC; mcauseIn = 32'h00000005; //load address fault
                    {2'b10, OP_S}       : stageNext = EXC; mcauseIn = 32'h00000007; //store address fault
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
