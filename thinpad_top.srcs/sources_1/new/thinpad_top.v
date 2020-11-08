`default_nettype none

module thinpad_top
(
    input wire clk_50M,              //50MHz 时钟输入
    input wire clk_11M0592,          //11.0592MHz 时钟输入（�?�用，可不用�?
    input wire clock_btn,            //BTN5手动时钟按钮开关，带消抖电�?，按下时�?1
    input wire reset_btn,            //BTN6手动复位按钮开关，带消抖电�?，按下时�?1
    input wire[3:0] touch_btn,       //BTN1~BTN4，按�?开关，按下时为1
    input wire[31:0] dip_sw,         //32位拨码开关，拨到“ON”时�?1
    output wire[15:0] leds,          //16位LED，输出时1点亮
    output wire[7:0] dpy0,           //数码管低位信号，包括小数点，输出1点亮
    output wire[7:0] dpy1,           //数码管高位信号，包括小数点，输出1点亮
    output wire uart_rdn,            //读串口信号，低有�?
    output wire uart_wrn,            //写串口信号，低有�?
    input wire uart_dataready,       //串口数据准�?�好
    input wire uart_tbre,            //发送数�?标志
    input wire uart_tsre,            //数据发送完毕标�?
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共�?
    output wire[19:0] base_ram_addr, //BaseRAM地址
    output wire[3:0] base_ram_be_n,  //BaseRAM字节使能，低有效。�?�果不使用字节使能，请保持为0
    output wire base_ram_ce_n,       //BaseRAM片选，低有�?
    output wire base_ram_oe_n,       //BaseRAM读使能，低有�?
    output wire base_ram_we_n,       //BaseRAM写使能，低有�?
    inout wire[31:0] ext_ram_data,   //ExtRAM数据
    output wire[19:0] ext_ram_addr,  //ExtRAM地址
    output wire[3:0] ext_ram_be_n,   //ExtRAM字节使能，低有效。�?�果不使用字节使能，请保持为0
    output wire ext_ram_ce_n,        //ExtRAM片选，低有�?
    output wire ext_ram_oe_n,        //ExtRAM读使能，低有�?
    output wire ext_ram_we_n,        //ExtRAM写使能，低有�?
    output wire txd,                 //直连串口发送�??
    input wire rxd,                  //直连串口接收�?
    output wire [22:0]flash_a,       //Flash地址，a0仅在8bit模式有效�?16bit模式无意�?
    inout wire [15:0]flash_d,        //Flash数据
    output wire flash_rp_n,          //Flash复位信号，低有效
    output wire flash_vpen,          //Flash写保护信号，低电平时不能擦除、烧�?
    output wire flash_ce_n,          //Flash片选信号，低有�?
    output wire flash_oe_n,          //Flash读使能信号，低有�?
    output wire flash_we_n,          //Flash写使能信号，低有�?
    output wire flash_byte_n,        //Flash 8bit模式选择，低有效。在使用flash�?16位模式时请�?�为1
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
    output wire[2:0] video_red,      //红色像素�?3�?
    output wire[2:0] video_green,    //绿色像素�?3�?
    output wire[1:0] video_blue,     //蓝色像素�?2�?
    output wire video_hsync,         //行同步（水平同�?�）信号
    output wire video_vsync,         //场同步（垂直同�?�）信号
    output wire video_clk,           //像素时钟输出
    output wire video_de
);           //行数�?有效信号，用于区分消隐区

    wire clk, rst;
    assign clk = clk_50M;
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
    wire aluFlagZero;

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
            2'b11 : data2RF = 32'b0;
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
        .func3(aluFunc3),
        .func7(aluFunc7),

        .stageNext(stageNext)
    );

    ALU alu(
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
            regA           <= 32'b0;
            regB           <= 32'b0;
            regC           <= 32'b0;
            regRam         <= 32'b0;
            pc             <= 32'b0;
            pcNow          <= 32'b0;
            regInstruction <= 32'b0;
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


            if (pcWr) pc <= pcSrc;

            if (pcNowWr) pcNow <= pc;

            if (instructionWr) regInstruction <= ramDataOut;
        end
    end
    /* ==  ==  ==  ==  ==  = Demo code begin ==  ==  ==  ==  ==  = */

    // // PLL分�?�示�?
    // wire locked, clk_10M, clk_20M;
    // pll_example clock_gen
    // (
    // // Clock in ports
    // .clk_in1(clk_50M),  // 外部时钟输入
    // // Clock out ports
    // .clk_out1(clk_10M), // 时钟输出1，�?�率在IP配置界面�?设置
    // .clk_out2(clk_20M), // 时钟输出2，�?�率在IP配置界面�?设置
    // // Status and control signals
    // .reset(reset_btn), // PLL复位输入
    // .locked(locked)    // PLL锁定指示输出�?"1"表示时钟稳定�?
    // // 后级电路复位信号应当由它生成（�?�下�?
    // );

    // reg reset_of_clk10M;
    // // 异�?��?�位，同步释放，将locked信号�?为后级电�?的�?�位reset_of_clk10M
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
