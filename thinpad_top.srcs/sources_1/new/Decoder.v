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
    //ExceptionHandler鐨勮緭鍑洪」
    input wire          mode, //鐢ㄦ潵鏍囪?褰撳墠鏈哄櫒鎬侊紵
    //ramController浼犳潵鐨勫叧浜庡湴锟??閿欒?鐨勪俊锟??
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
    //涓嬪垪鍏ㄩ儴鏄疎xcepHandler鐨勮緭鍏ラ」
    output reg          exceptFlag,
    output reg          retFlag,
    output reg [31:0]   mcauseIn, //鏍规嵁寮傚父鍘熷洜缁欏嚭
    output reg [1:0]    csrWrOp,//鍐欏叆閫夐」

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
        EXC = 3'b110, //exception 寮傚父澶勭悊鐘讹拷??
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
        OP_LUI      = 7'b0110111,
        //寮傚父涓?柇鎸囦护
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
        // 姣忎釜闃舵?涓哄綋鍓嶉樁娈靛噯澶囨帶鍒朵俊锟??!
            IF : begin
                pcWr        <= 1'b1;
                pcNowWr     <= 1'b1;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b1;
                ramByte     <= 2'b10; //IF闃舵?鎸夊瓧璇诲彇鎸囦护
                irWr        <= 1'b1;
                regDSel     <= 3'b011;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b00;
                aluBSel     <= 2'b00;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;//异常使能关闭
                retFlag     <= 1'b0;//异常返回使能只在mret时为1
                csrWrOp     <= 2'b00;//不需要写csr
            end
            ID : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b10; //ID闃舵?涓嶈?锟??
                irWr        <= 1'b0;
                regDSel     <= 3'b011;
                immSel      <= IMM_N; //涓哄暐閫変簡涓狟锟??
                regWr       <= 1'b0;
                aluASel     <= 2'b01;
                aluBSel     <= 2'b10;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;//异常使能关闭
                retFlag     <= 1'b0;//异常返回使能只在mret时为1
                csrWrOp     <= 2'b00;//不需要写csr
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        func3       <= funct3;
                        func7       <= funct7;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_I : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        func3       <= funct3;
                        func7       <= funct7;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_S : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_B : begin
                        pcWr        <= (funct3 == 3'b000)? flagZ : ((funct3 == 3'b001)? ~flagZ : 1'b0); //beq鍒欑粨鏋滀负0鏃舵敼鍐欙紝bne鍒欑粨鏋滀笉锟??0鏃舵敼锟??
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b01;
                        func3       <= 3'b000;
                        func7       <= 7'b0100000; //branch鎸囦护锟??瑕佸皢涓や釜鏁扮浉鍑忓垽鏂?粨鏋滄槸鍚︿负0
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_JAL : begin //JAL鎸夌収ppt鐨勬灦鏋勯渶瑕佸湪EXE鍛ㄦ湡鍚屾椂鍐欏叆瀵勫瓨鍣ㄥ拰pc
                        pcWr        <= 1'b1; //鍐橮C
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01; //閫夋嫨ALU鐨勮繍绠楃粨锟??
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b010; //JAL瑕佸皢pc+4鍐欏叆rd
                        immSel      <= IMM_J;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b00; //PC
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    OP_JALR : begin //JALR EXE鍛ㄦ湡鍙?仛ALU杩愮畻
                        pcWr        <= 1'b0; 
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10; //rs1
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    //LUI鐩存帴杩涘叆WB鍛ㄦ湡
                    /*OP_LUI : begin
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
                        aluASel     <= 2'b11; //涓嶏拷?锟芥嫨
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end*/
                    OP_AUIPC : begin //AUIPC EXE鍛ㄦ湡璁＄畻pc+imm
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b00;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_U;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b01; //閫夋嫨pc_now
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//异常使能关闭
                        retFlag     <= 1'b0;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'b00;//不需要写csr
                    end
                    default : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'bXX;
                        ramSel      <= 1'bX;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'bXXX;
                        immSel      <= 3'bXXX;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                        exceptFlag  <= 1'bX;//异常使能关闭
                        retFlag     <= 1'bX;//异常返回使能只在mret时为1
                        csrWrOp     <= 2'bXX;//不需要写csr
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_S;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_L : begin
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b1;
                        ramWr       <= 1'b1;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_I;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b10;
                        aluBSel     <= 2'b10;
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                    end
                endcase
            end
            WB : begin
                case (opCode)
                    OP_I, OP_R : begin //OP_I, OP_R 灏唕egC鍐欏洖rd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b001; //閫夋嫨regC鍐欏洖rd
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_L : begin //OP_L绫诲瀷灏咲R鍐欏洖rd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b000; //鍐欏洖ram涓?殑鏁版嵁
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b010; //鍐欏洖pc+4
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011; //rd<-imm
                        immSel      <= IMM_U;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b001; //rd<-C锟?? pc + imm锟??
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end
                    OP_SYS : begin
                        case (funct3)
                            3'b00 : begin//mret鎸囦护
                                pcWr        <= 1'b1;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b11;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= func3[1:0];
                                irWr        <= 1'b0;
                                regDSel     <= 3'b001; //rd<-C锟?? pc + imm锟??
                                immSel      <= IMM_N;
                                regWr       <= 1'b0; //mret 涓嶇敤鍐欏瘎瀛樺櫒
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;//鏈?彂鐢熷紓锟??
                                csrWrOp     <= 2'b00;//涓嶉渶瑕佸啓
                            end
                            default: begin //csr鎸囦护
                                pcWr        <= 1'b0;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b01;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= func3[1:0];
                                irWr        <= 1'b0;
                                regDSel     <= 3'b001; //rd<-C锟?? pc + imm锟??
                                immSel      <= IMM_N;
                                regWr       <= 1'b0; //mret 涓嶇敤鍐欏瘎瀛樺櫒
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;//鏈?彂鐢熷紓锟??
                                csrWrOp     <= funct3[1:0];//锟??瑕佸啓
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
                        ramByte     <= func3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b011;
                        immSel      <= IMM_N;
                        regWr       <= 1'b0;
                        aluASel     <= 2'bXX;
                        aluBSel     <= 2'bXX;
                        func3       <= 3'bXXX;
                        func7       <= 7'bXXXXXXX;
                    end
                endcase
            end
            EXC : begin //所有异常中断状态
                pcWr        <= 1'b1; //修改pc到mtevc
                pcNowWr     <= 1'b0; //pcNow不变
                pcSel       <= 2'b10;//选择exceptionHandler
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= func3[1:0];//无需读写内存
                irWr        <= 1'b0;
                regDSel     <= 3'b001; //无需读写寄存器
                immSel      <= IMM_N;
                regWr       <= 1'b0; //无需读写寄存器
                aluASel     <= 2'b11;
                aluBSel     <= 2'b11;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b1;//异常使能
                retFlag     <= 1'b0;//异常返回使能只在mret时为1
                csrWrOp     <= 2'b00;//不需要写csr
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
                exceptFlag  <= 1'bX;//异常使能X
                retFlag     <= 1'bX;//异常返回使能只在mret时为1
                csrWrOp     <= 2'bXX;//不需要写csr
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
    mcauseIn = 32'hffffffff;
        case (stage)
            IDLE :
                stageNext = IF;
            IF :
                case ({addrFault, addrMisal})
                    2'b00       : stageNext = ID;
                    2'b01       : begin stageNext = EXC; mcauseIn = 32'h00000000;end //instruction address misaligned
                    2'b10       : begin stageNext = EXC; mcauseIn = 32'h00000001;end //instruction address fault
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
                                    12'b000000000000 : begin stageNext = EXC; mcauseIn = 32'h00000008;end //environment call from U-mode
                                    12'b000000000001 : begin stageNext = EXC; mcauseIn = 32'h00000003;end //breakpoint
                                    12'b001100000010 : stageNext = WB; //mret
                                    default: stageNext = ERR; //鍏朵粬鎯呭喌鍒欎负鏈?畾涔夋寚锟??
                                endcase
                            default: stageNext = WB; //csr鎸囦护
                        endcase
                    //OP_ECALL    : stageNext = EXC; mcauseIn = 32'h00000008; //environment call from U-mode
                    //OP_EBREAK   : stageNext = EXC; mcauseIn = 32'h00000003; //breakpoint
                    default     : begin stageNext = EXC; mcauseIn = 32'h00000002;end //illegal instruction
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
                    {2'b01, OP_S}       : begin stageNext = EXC; mcauseIn = 32'h00000006;end //store address misaligned
                    {2'b10, OP_L}       : begin stageNext = EXC; mcauseIn = 32'h00000005;end //load address fault
                    {2'b10, OP_S}       : begin stageNext = EXC; mcauseIn = 32'h00000007;end //store address fault
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
