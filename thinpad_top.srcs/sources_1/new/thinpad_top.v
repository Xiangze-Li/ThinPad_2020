`default_nettype none

module thinpad_top
(
    input wire clk_50M,              //50MHz ʱ������
    input wire clk_11M0592,          //11.0592MHz ʱ�����루???�ã��ɲ���??
    input wire clock_btn,            //BTN5�ֶ�ʱ�Ӱ�ť���أ���������??������ʱ??1
    input wire reset_btn,            //BTN6�ֶ���λ��ť���أ���������??������ʱ??1
    input wire[3:0] touch_btn,       //BTN1~BTN4����??���أ�����ʱΪ1
    input wire[31:0] dip_sw,         //32λ���뿪�أ�������ON��ʱ??1
    output wire[15:0] leds,          //16λLED�����ʱ1����
    output wire[7:0] dpy0,           //����ܵ�λ�źţ�����С���㣬���1����
    output wire[7:0] dpy1,           //����ܸ�λ�źţ�����С���㣬���1����
    output wire uart_rdn,            //�������źţ�����??
    output wire uart_wrn,            //д�����źţ�����??
    input wire uart_dataready,       //��������׼???��
    input wire uart_tbre,            //������??��־
    input wire uart_tsre,            //���ݷ�����ϱ�??
    inout wire[31:0] base_ram_data,  //BaseRAM���ݣ���8λ��CPLD���ڿ�������??
    output wire[19:0] base_ram_addr, //BaseRAM��ַ
    output wire[3:0] base_ram_be_n,  //BaseRAM�ֽ�ʹ�ܣ�����Ч��???����ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire base_ram_ce_n,       //BaseRAMƬѡ������??
    output wire base_ram_oe_n,       //BaseRAM��ʹ�ܣ�����??
    output wire base_ram_we_n,       //BaseRAMдʹ�ܣ�����??
    inout wire[31:0] ext_ram_data,   //ExtRAM����
    output wire[19:0] ext_ram_addr,  //ExtRAM��ַ
    output wire[3:0] ext_ram_be_n,   //ExtRAM�ֽ�ʹ�ܣ�����Ч��???����ʹ���ֽ�ʹ�ܣ��뱣��Ϊ0
    output wire ext_ram_ce_n,        //ExtRAMƬѡ������??
    output wire ext_ram_oe_n,        //ExtRAM��ʹ�ܣ�����??
    output wire ext_ram_we_n,        //ExtRAMдʹ�ܣ�����??
    output wire txd,                 //ֱ�����ڷ���???
    input wire rxd,                  //ֱ�����ڽ���??
    output wire [22:0]flash_a,       //Flash��ַ��a0����8bitģʽ��Ч??16bitģʽ����??
    inout wire [15:0]flash_d,        //Flash����
    output wire flash_rp_n,          //Flash��λ�źţ�����Ч
    output wire flash_vpen,          //Flashд�����źţ��͵�ƽʱ���ܲ�������??
    output wire flash_ce_n,          //FlashƬѡ�źţ�����??
    output wire flash_oe_n,          //Flash��ʹ���źţ�����??
    output wire flash_we_n,          //Flashдʹ���źţ�����??
    output wire flash_byte_n,        //Flash 8bitģʽѡ�񣬵���Ч����ʹ��flash??16λģʽʱ��???Ϊ1
    output wire sl811_a0,
    output wire sl811_wr_n,
    output wire sl811_rd_n,
    output wire sl811_cs_n,
    output wire sl811_rst_n,
    output wire sl811_dack_n,
    input wire sl811_intrq,
    input wire sl811_drq_n,
    output wire dm9k_cmd,
    inout wire[15:0] dm9k_sd,
    output wire dm9k_iow_n,
    output wire dm9k_ior_n,
    output wire dm9k_cs_n,
    output wire dm9k_pwrst_n,
    input wire dm9k_int,
    output wire[2:0] video_red,      //��ɫ����??3??
    output wire[2:0] video_green,    //��ɫ����??3??
    output wire[1:0] video_blue,     //��ɫ����??2??
    output wire video_hsync,         //��ͬ����ˮƽͬ???���ź�
    output wire video_vsync,         //��ͬ������ֱͬ???���ź�
    output wire video_clk,           //����ʱ�����
    output wire video_de
);           //����??��Ч�źţ���������������

    assign leds = 16'b0; //��leds��ʾ��������

    wire clk, rst;
    wire clk_10M, clk_15M, clk_20M, clk_25M;
    wire rst_10M, rst_15M, rst_20M, rst_25M;

    // NOTE: ѡ��ʱ����Դ
    assign clk = clk_10M;
    assign rst = rst_10M;

    // stages
    reg  [2:0] stage;
    wire [2:0] stageNext;
    parameter [2:0]
        IDLE = 3'b000,
        IF = 3'b001,
        ID = 3'b010,
        EXE = 3'b011,
        MEM = 3'b100,
        WB = 3'b101,
        EXP = 3'b110,
        ERR = 3'b111;

    reg[31:0] pc, pcNow;

    wire regWr;
    wire pcWr, pcNowWr;
    wire ramSel, ramWr, ramRd, ramDone;  // ramSel: address (aluout reg or pc)
    wire instructionWr;
    wire aluFlagZero, aluRorI;
    // exception
    wire exceptionFlag, excepRetFlag;
    wire addrMisal, addrFault, pageFault;
    wire cpuMode;
    wire [1:0] csrWrOp;
    wire [11:0] csrAddr;
    wire [31:0] decodeMcause;
    wire [31:0] csrDataOut;
    wire [31:0] excepHandleAddr, epcOut;
    reg  [31:0] mcauseReg;
    wire [21:0] ppn;


    wire [1:0] aluASel, aluBSel;  // ALU opr A, ALU opr B
    wire [1:0] pcSel;
    wire [1:0] ramByte;  // number of bytes for ram to read

    wire [2:0] immSel, aluFunc3, regDSel;  //immediate, funct3, register data

    wire [4:0] rs1, rs2, rd;

    wire [6:0] aluFunc7;

    wire [31:0] immOut, ramDataOut;
    wire [31:0] rs1Data, rs2Data, aluRes;
    wire [31:0] ramAddr;  //origin address, undecoded

    reg  [31:0] pcSrc;
    reg  [31:0] regA, regB, regC;  // reg for ALU
    reg  [31:0] regInstruction, regRam;
    reg  [31:0] data2RF, oprandA, oprandB;

    // NOTE: ������ Controller
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            regA           <= 32'b0;
            regB           <= 32'b0;
            regC           <= 32'b0;
            regRam         <= 32'b0;
            pc             <= 32'h8000_0000;
            pcNow          <= 32'b0;
            regInstruction <= 32'b0;
            mcauseReg      <= 32'hFFFFFFFF;
            stage          <= IDLE;
        end
        else begin
            regA   <= rs1Data;
            regB   <= rs2Data;
            regC   <= aluRes;
            regRam <= ramDataOut;

            if ((stage == IF) || (stage == MEM)) begin
                if(ramDone) begin
                    stage <= stageNext;
                end
            end
            else begin
                stage <= stageNext;
            end

            if (pcWr && !(stage == IF && ~ramDone))
                pc <= pcSrc;

            if (pcNowWr)
                pcNow <= pc;

            if (instructionWr)
                regInstruction <= ramDataOut;

            // if (exceptionFlag)
                mcauseReg <= decodeMcause;
        end
    end

    // NOTE: MUX
    assign csrAddr = regInstruction[31:20];

    assign rs1 = regInstruction[19:15];
    assign rs2 = regInstruction[24:20];
    assign rd  = regInstruction[11:07];

    assign ramAddr = ramSel ? regC : pc;

    always @(*) begin
        case (pcSel)
            2'b00: pcSrc = regC;
            2'b01: pcSrc = aluRes;
            2'b10: pcSrc = excepHandleAddr;
            2'b11: pcSrc = epcOut;
        endcase

        case (regDSel)
            3'b000 : data2RF = regRam;
            3'b001 : data2RF = regC;
            3'b010 : data2RF = pc;
            3'b011 : data2RF = immOut; //Ϊ��LUIָ���11���ó���ѡ�����������������ɵ�����12λ�������
            3'b100 : data2RF = csrDataOut;  //exception
            default: data2RF = 0;
        endcase

        case (aluASel)
            2'b00 : oprandA = pc;
            2'b01 : oprandA = pcNow;
            2'b10 : oprandA = regA;
            2'b11 : oprandA = 32'b0;
        endcase

        case (aluBSel)
            2'b00 : oprandB = 32'h4;
            2'b01 : oprandB = regB;
            2'b10 : oprandB = immOut;
            2'b11 : oprandB = 32'b0;
        endcase
    end

    // NOTE: �������
    RegFile regFile(
        .clk(clk),
        .rst(rst),

        .regWr(regWr),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .inData(data2RF),

        .rs1Data(rs1Data),
        .rs2Data(rs2Data)
    );

    ExcepHandler exceptHandler(
        .clk(clk),
        .rst(rst),

        .excepFlag(exceptionFlag),
        .retFlag(excepRetFlag),
        .mcauseIn(mcauseReg),
        .pcNowIn(pcNow),

        .csrWrOp(csrWrOp),
        .csrAddr(csrAddr),
        .csrDataIn(regA),
        .csrDataOut(csrDataOut),

        .mode(cpuMode),
        .handlerAddr(excepHandleAddr),
        .epcOut(epcOut),
        .ppn(ppn)
    );

    ImmGen immGen(
        .inst(regInstruction),
        .immSel(immSel),

        .immOut(immOut)
    );

    Decoder decoder(
        .inst(regInstruction),
        .flagZ(aluFlagZero),
        .stage(stage),

        .mode(cpuMode),
        .addrMisal(addrMisal),
        .addrFault(addrFault),
        .pgFault(pageFault),

        .pcWr(pcWr),
        .pcNowWr(pcNowWr),
        .pcSel(pcSel),
        .ramSel(ramSel),
        .ramWr(ramWr),
        .ramRd(ramRd),
        .ramByte(ramByte),
        .irWr(instructionWr),
        .regDSel(regDSel),
        .immSel(immSel),
        .regWr(regWr),
        .aluASel(aluASel),
        .aluBSel(aluBSel),
        .func3(aluFunc3),
        .func7(aluFunc7),
        .aluRI(aluRorI),

        .exceptFlag(exceptionFlag),
        .retFlag(excepRetFlag),
        .mcauseIn(decodeMcause),
        .csrWrOp(csrWrOp),

        .stageNext(stageNext)
    );

    ALU alu(
        .ri(aluRorI),
        .funct3(aluFunc3),
        .funct7(aluFunc7),
        .oprandA(oprandA),
        .oprandB(oprandB),

        .result(aluRes),
        .flagZero(aluFlagZero)
    );

    MMU mmu(
        .clk(clk),
        .rst(rst),

        .dataIn(regB),
        .dataOut(ramDataOut),
        .virtualAddr(ramAddr),

        .writeEn(ramWr),
        .readEn(ramRd),
        .ramByte(ramByte),
        .done(ramDone),

        .mode(cpuMode),
        .ppn(ppn),

        .baseIO(base_ram_data),
        .baseAddr(base_ram_addr),
        .baseCeN(base_ram_ce_n),
        .baseBeN(base_ram_be_n),
        .baseOeN(base_ram_oe_n),
        .baseWeN(base_ram_we_n),

        .extIO(ext_ram_data),
        .extAddr(ext_ram_addr),
        .extCeN(ext_ram_ce_n),
        .extBeN(ext_ram_be_n),
        .extOeN(ext_ram_oe_n),
        .extWeN(ext_ram_we_n),

        .uartDataready(uart_dataready),
        .uartTbrE(uart_tbre),
        .uartTsrE(uart_tsre),
        .uartRdN(uart_rdn),
        .uartWrN(uart_wrn),

        .addrMisal(addrMisal),
        .addrFault(addrFault),
        .pageFault(pageFault)
    );

    ClkGen clkgen(
        clk_50M,
        reset_btn,
        clk_10M,
        clk_15M,
        clk_20M,
        clk_25M,
        rst_10M,
        rst_15M,
        rst_20M,
        rst_25M
    );

endmodule
