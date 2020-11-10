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

    reg[15:0] disp;
    assign leds = disp; //��leds��ʾ��������

    wire clk, rst;
    assign clk = clk_11M0592;
    //assign clk = clock_btn;
    assign rst = reset_btn;

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
        ERR = 3'b111;

    reg[31:0] pc, pcNow;

    wire regWr;
    wire pcWr, pcNowWr, pcSel;
    wire ramSel, ramWr, ramRd, ramDone;  // ramSel: address (aluout reg or pc)
    wire instructionWr;
    wire aluFlagZero, aluRorI;

    wire [1:0] aluASel, aluBSel, regDSel;  // ALU opr A, ALU opr B, register data
    wire [1:0] ramByte;  // number of bytes for ram to read

    wire [2:0] immSel, aluFunc3;

    wire [4:0] rs1, rs2, rd;

    wire [6:0] aluFunc7;

    wire [31:0] immOut, ramDataOut;
    wire [31:0] rs1Data, rs2Data, aluRes;
    wire [31:0] pcSrc, ramAddr;  //ramAddr: origin address, undecoded

    reg  [31:0] regA, regB, regC;  // reg for ALU
    reg  [31:0] regInstruction, regRam;
    reg  [31:0] data2RF, oprandA, oprandB;

    assign rs1 = regInstruction[19:15];
    assign rs2 = regInstruction[24:20];
    assign rd  = regInstruction[11:07];

    assign pcSrc   = pcSel ? aluRes : regC;
    assign ramAddr = ramSel ? regC : pc;


    always @(*) begin
        case (regDSel)
            2'b00 : data2RF = regRam;
            2'b01 : data2RF = regC;
            2'b10 : data2RF = pc;
            2'b11 : data2RF = immOut; //Ϊ��LUIָ���11���ó���ѡ�����������������ɵ�����12λ�������
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

    ImmGen immGen(
        .inst(regInstruction),
        .immSel(immSel),

        .immOut(immOut)
    );

    Decoder decoder(
        .inst(regInstruction),
        .flagZ(aluFlagZero),
        .stage(stage),

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
        .aluRI(aluRorI),
        .func3(aluFunc3),
        .func7(aluFunc7),

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

    RamController ramController(
        .clk(clk),
        .rst(rst),

        .dataIn(regB),
        .dataOut(ramDataOut),
        .address(ramAddr),

        .ramWr(ramWr),
        .ramRd(ramRd),
        .ramByte(ramByte),
        .ramDone(ramDone),

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
        .uartWrN(uart_wrn)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            disp           <= disp;
            regA           <= 32'b0;
            regB           <= 32'b0;
            regC           <= 32'b0;
            regRam         <= 32'b0;
            pc             <= 32'h8000_0000;
            pcNow          <= 32'b0;
            regInstruction <= 32'b0;
            stage          <= IDLE;
        end
        else begin
            disp   <= disp;
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


            if (pcWr && !(stage == IF && ~ramDone)) pc <= pcSrc;

            if (pcNowWr) pcNow <= pc;

            if (instructionWr) regInstruction <= ramDataOut;
        end
    end
    /* ==  ==  ==  ==  ==  = Demo code begin ==  ==  ==  ==  ==  = */

    // // PLL��???ʾ??
    // wire locked, clk_10M, clk_20M;
    // pll_example clock_gen
    // (
    // // Clock in ports
    // .clk_in1(clk_50M),  // �ⲿʱ������
    // // Clock out ports
    // .clk_out1(clk_10M), // ʱ�����1��???����IP���ý���??����
    // .clk_out2(clk_20M), // ʱ�����2��???����IP���ý���??����
    // // Status and control signals
    // .reset(reset_btn), // PLL��λ����
    // .locked(locked)    // PLL����ָʾ���??"1"��ʾʱ���ȶ�??
    // // �󼶵�·��λ�ź�Ӧ���������ɣ�???��??
    // );

    // reg reset_of_clk10M;
    // // ��??????λ��ͬ���ͷţ���locked�ź�??Ϊ�󼶵�??��???λreset_of_clk10M
    // always@(posedge clk_10M or negedge locked) begin
    //     if (~locked) reset_of_clk10M <= 1'b1;
    //     else        reset_of_clk10M  <= 1'b0;
    // end

    // always@(posedge clk_10M or posedge reset_of_clk10M) begin
    //     if (reset_of_clk10M)begin
    //         // Your Code
    //     end
    //     else begin
    //         // Your Code
    //     end
    // end

endmodule
