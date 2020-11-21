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
    //ExceptionHandlerçčžĺşéĄš
    input wire          mode,
    //ramControlleräź ćĽçĺłäşĺ°ďż??éč?çäżĄďż??
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
    //ä¸ĺĺ¨é¨ćŻExcepHandlerçčžĺĽéĄš
    output reg          exceptFlag,
    output reg          retFlag,
    output reg [31:0]   mcauseIn, //ć šćŽĺźĺ¸¸ĺĺ çťĺş
    output reg [1:0]    csrWrOp,//ĺĺĽééĄš

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
        EXC = 3'b110, //exception ĺźĺ¸¸ĺ¤ççśďż˝??
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
        //ĺźĺ¸¸ä¸?­ćäť¤
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
        // ćŻä¸Şéść?ä¸şĺ˝ĺéśćŽľĺĺ¤ć§ĺśäżĄďż??!
            IF : begin
                pcWr        <= 1'b1;
                pcNowWr     <= 1'b1;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b1;
                ramByte     <= 2'b10; //IFéść?ćĺ­čŻťĺćäť¤
                irWr        <= 1'b1;
                regDSel     <= 3'b011;
                immSel      <= IMM_N;
                regWr       <= 1'b0;
                aluASel     <= 2'b00;
                aluBSel     <= 2'b00;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
            end
            ID : begin
                pcWr        <= 1'b0;
                pcNowWr     <= 1'b0;
                pcSel       <= 2'b01;
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b10; //IDéść?ä¸č?ďż??
                irWr        <= 1'b0;
                regDSel     <= 3'b011;
                immSel      <= IMM_B; //ä¸şĺĽéäşä¸ŞBďż??
                regWr       <= 1'b0;
                aluASel     <= 2'b01;
                aluBSel     <= 2'b10;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    OP_B : begin
                        pcWr        <= (funct3 == 3'b000)? flagZ : ((funct3 == 3'b001)? ~flagZ : 1'b0); //beqĺçťćä¸ş0ćśćšĺďźbneĺçťćä¸ďż??0ćśćšďż??
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
                        func7       <= 7'b0100000; //branchćäť¤ďż??čŚĺ°ä¸¤ä¸Şć°ç¸ĺĺ¤ć?ťććŻĺŚä¸ş0
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    OP_JAL : begin //JALćç§pptçćśćéčŚĺ¨EXEĺ¨ćĺćśĺĺĽĺŻĺ­ĺ¨ĺpc
                        pcWr        <= 1'b1; //ĺPC
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01; //éćŠALUçčżçŽçťďż??
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b010; //JALčŚĺ°pc+4ĺĺĽrd
                        immSel      <= IMM_J;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b01; //PC
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    OP_JALR : begin //JALR EXEĺ¨ćĺ?ALUčżçŽ
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    //LUIç´ćĽčżĺĽWBĺ¨ć
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
                        aluASel     <= 2'b11; //ä¸ďż˝?ďż˝ćŠ
                        aluBSel     <= 2'b10; //imm
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                    end*/
                    OP_AUIPC : begin //AUIPC EXEĺ¨ćčŽĄçŽpc+imm
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
                        aluASel     <= 2'b01; //éćŠpc_now
                        aluBSel     <= 2'b10; //imm
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'bX;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'bX;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'bXX;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'bX;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'bX;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'bXX;//˛ťĐčŇŞĐ´csr
                    end
                endcase
            end
            WB : begin
                case (opCode)
                    OP_I, OP_R : begin //OP_I, OP_R ĺ°regCĺĺrd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= 2'b11;
                        irWr        <= 1'b0;
                        regDSel     <= 3'b001; //éćŠregCĺĺrd
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    OP_L : begin //OP_Lçąťĺĺ°DRĺĺrd
                        pcWr        <= 1'b0;
                        pcNowWr     <= 1'b0;
                        pcSel       <= 2'b01;
                        ramSel      <= 1'b0;
                        ramWr       <= 1'b0;
                        ramRd       <= 1'b0;
                        ramByte     <= funct3[1:0];
                        irWr        <= 1'b0;
                        regDSel     <= 3'b000; //ĺĺramä¸?ć°ćŽ
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        regDSel     <= 3'b010; //ĺĺpc+4
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                        regDSel     <= 3'b001; //rd<-Cďż?? pc + immďż??
                        immSel      <= IMM_N;
                        regWr       <= 1'b1;
                        aluASel     <= 2'b11;
                        aluBSel     <= 2'b11;
                        aluRI       <= 1'b0;
                        func3       <= 3'b000;
                        func7       <= 7'b0000000;
                        exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                    end
                    OP_SYS : begin
                        case (funct3)
                            3'b000 : begin//mretćäť¤
                                pcWr        <= 1'b1;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b11;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= 2'b11;
                                irWr        <= 1'b0;
                                regDSel     <= 3'b001; //rd<-Cďż?? pc + immďż??
                                immSel      <= IMM_N;
                                regWr       <= 1'b0; //mret ÎŢĐčĐ´źÄ´ćĆ÷
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                aluRI       <= 1'b0;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                                retFlag     <= 1'b1;//mretŔ­¸ßˇľťŘĐĹşĹ
                                csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
                            end
                            default: begin //csrĎľÁĐÖ¸Áî
                                pcWr        <= 1'b0;
                                pcNowWr     <= 1'b0;
                                pcSel       <= 2'b01;
                                ramSel      <= 1'b0;
                                ramWr       <= 1'b0;
                                ramRd       <= 1'b0;
                                ramByte     <= 2'b11;
                                irWr        <= 1'b0;
                                regDSel     <= 3'b100; //rd<-Cďż?? pc + immďż??
                                immSel      <= IMM_N;
                                regWr       <= 1'b1; //mret ä¸ç¨ĺĺŻĺ­ĺ¨
                                aluASel     <= 2'b11;
                                aluBSel     <= 2'b11;
                                aluRI       <= 1'b0;
                                func3       <= 3'b000;
                                func7       <= 7'b0000000;
                                exceptFlag  <= 1'b0;//ŇěłŁĘšÄÜšŘąŐ
                                retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                                csrWrOp     <= funct3[1:0];//Đ´csr¸řfunct3ľÍÁ˝Îť
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
                        exceptFlag  <= 1'bX;//ŇěłŁĘšÄÜšŘąŐ
                        retFlag     <= 1'bX;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                        csrWrOp     <= 2'bXX;//˛ťĐčŇŞĐ´csr
                    end
                endcase
            end
            EXC : begin //ËůÓĐŇěłŁÖĐśĎ×´ĚŹ
                pcWr        <= 1'b1; //ĐŢ¸Äpcľ˝mtevc
                pcNowWr     <= 1'b0; //pcNow˛ťąä
                pcSel       <= 2'b10;//ŃĄÔńexceptionHandler
                ramSel      <= 1'b0;
                ramWr       <= 1'b0;
                ramRd       <= 1'b0;
                ramByte     <= 2'b11;//ÎŢĐčśÁĐ´ÄÚ´ć
                irWr        <= 1'b0;
                regDSel     <= 3'b001; //ÎŢĐčśÁĐ´źÄ´ćĆ÷
                immSel      <= IMM_N;
                regWr       <= 1'b0; //ÎŢĐčśÁĐ´źÄ´ćĆ÷
                aluASel     <= 2'b11;
                aluBSel     <= 2'b11;
                aluRI       <= 1'b0;
                func3       <= 3'b000;
                func7       <= 7'b0000000;
                exceptFlag  <= 1'b1;//ŇěłŁĘšÄÜ
                retFlag     <= 1'b0;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                csrWrOp     <= 2'b00;//˛ťĐčŇŞĐ´csr
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
                exceptFlag  <= 1'bX;//ŇěłŁĘšÄÜX
                retFlag     <= 1'bX;//ŇěłŁˇľťŘĘšÄÜÖťÔÚmretĘąÎŞ1
                csrWrOp     <= 2'bXX;//˛ťĐčŇŞĐ´csr
            end
        endcase
    end

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
                                    12'b000000000000 : begin
                                        stageNext = EXC;
                                        mcauseIn = 32'h00000008;
                                    end //environment call from U-mode
                                    12'b000000000001 : begin
                                        stageNext = EXC;
                                        mcauseIn = 32'h00000003;
                                    end //breakpoint
                                    12'b001100000010 : begin //mret
                                        case (mode)
                                            1'b1: stageNext = WB; //M-mode is legal
                                            1'b0: begin stageNext = EXC; mcauseIn = 32'h00000002;end //U-mode is illegal
                                            default: stageNext = ERR;
                                        endcase
                                    end
                                    default: stageNext = IF;
                                endcase
                            default: begin
                                case (mode)
                                    1'b1: stageNext = WB; //csrćäť¤
                                    1'b0: begin stageNext = EXC; mcauseIn = 32'h00000002;end
                                    default: stageNext = ERR;
                                endcase
                            end//stageNext = WB; //csrćäť¤
                        endcase
                    default     : begin
                        stageNext = EXC;
                        mcauseIn = 32'h00000002;
                    end //illegal instruction
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
