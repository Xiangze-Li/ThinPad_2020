`default_nettype none

module RamController
(
    input  wire         clk,
    input  wire         rst,

    input  wire [31:0]  address,
    input  wire [31:0]  dataIn,
    output wire [31:0]  dataOut,

    input  wire [1:0]   ramByte,
    input  wire         ramWr,
    input  wire         ramRd,
    output wire         ramDone,

    inout  wire [31:0]  baseIO,
    output wire [19:0]  baseAddr,
    output wire         baseCeN,
    output wire [3:0]   baseBeN,
    output wire         baseOeN,
    output wire         baseWeN,

    inout  wire [31:0]  extIO,
    output wire [19:0]  extAddr,
    output wire         extCeN,
    output wire [3:0]   extBeN,
    output wire         extOeN,
    output wire         extWeN,

    input  wire         uartDataready,
    input  wire         uartTbrE,
    input  wire         uartTsrE,
    output wire         uartRdN,
    output wire         uartWrN
);

    localparam [4:0]
        S_IDLE      = 5'b00000,
        // BaseRAM
        S_B_RD_1    = 5'b01001,
        S_B_RD_2    = 5'b01010,
        S_B_RD_3    = 5'b01011,
        S_B_WR_1    = 5'b01101,
        S_B_WR_2    = 5'b01110,
        S_B_WR_3    = 5'b01111,
        // ExtRAM
        S_E_RD_1    = 5'b10001,
        S_E_RD_2    = 5'b10010,
        S_E_RD_3    = 5'b10011,
        S_E_WR_1    = 5'b10101,
        S_E_WR_2    = 5'b10110,
        S_E_WR_3    = 5'b10111,
        // UART
        S_U_RD_1    = 5'b11001,
        S_U_RD_2    = 5'b11010,
        S_U_RD_3    = 5'b11011,
        S_U_WR_0    = 5'b11100,
        S_U_WR_1    = 5'b11101,
        S_U_WR_2    = 5'b11110,
        S_U_WR_3    = 5'b11111,
        //
        S_ERR       = 5'b00100;

    reg [4:0] state;

    reg baseCeN_R, baseOeN_R, baseWeN_R, baseZ;
    reg extCeN_R, extOeN_R, extWeN_R, extZ;
    reg uartRdN_R, uartWrN_R;
    reg [31:0] baseData;
    reg [31:0] extData;
    reg [31:0] outData;

    assign ramDone = (state[1:0] == 2'b11);

    reg [3:0]  ramBe;
    reg [31:0] outBeBuff;
    reg [31:0] inBeBuff;
    assign dataOut = outBeBuff;

    always @(*) begin
        // 处理位选
        // 与 Load/Store 的 funct3[1:0] 保持一致.
        case ({ ramByte, address[1:0] })
            4'b00_00 : begin
                outBeBuff = { {24{outData[7]}}, outData[7:0] };
                inBeBuff = { 24'h0000_00, dataIn[7:0] };
                ramBe = 4'b1110;
            end
            4'b00_01 : begin
                outBeBuff = { {24{outData[15]}}, outData[15:8] };
                inBeBuff = { 16'h0000, dataIn[7:0], 4'h0 };
                ramBe = 4'b1101;
            end
            4'b00_10 : begin
                outBeBuff = { {24{outData[23]}}, outData[23:16] };
                inBeBuff = { 4'h0, dataIn[7:0], 16'h0000 };
                ramBe = 4'b1011;
            end
            4'b00_11 : begin
                outBeBuff = { {24{outData[31]}}, outData[31:24] };
                inBeBuff = { dataIn[7:0], 24'h0000_00 };
                ramBe = 4'b0111;
            end
            4'b01_0X : begin
                outBeBuff = { {16{outData[15]}}, outData[15:0] };
                inBeBuff = { 16'h0000, dataIn[15:0] };
                ramBe = 4'b1100;
            end
            4'b01_1X : begin
                outBeBuff = { {16{outData[31]}}, outData[31:16] };
                inBeBuff = { dataIn[15:0], 16'h0000 };
                ramBe = 4'b0011;
            end
            4'b1X_XX : begin
                outBeBuff = outData;
                inBeBuff = dataIn;
                ramBe = 4'b0000;
            end
        endcase
    end

    // assign baseCeN  = 1'b0;
    // assign extCeN   = 1'b0;
    assign baseCeN  = baseCeN_R;
    assign extCeN   = extCeN_R;
    assign baseBeN  = ramBe;
    assign extBeN   = ramBe;
    assign baseOeN  = baseOeN_R;
    assign baseWeN  = baseWeN_R;
    assign extOeN   = extOeN_R;
    assign extWeN   = extWeN_R;
    assign baseAddr = address[21:2];
    assign extAddr  = address[21:2];
    assign baseIO   = baseZ ? 32'bZ : baseData;
    assign extIO    = extZ  ? 32'bZ : extData;
    assign uartWrN  = uartWrN_R;
    assign uartRdN  = uartRdN_R;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state     <= S_IDLE;
            baseZ     <= 1'b1;
            baseCeN_R <= 1'b1;
            baseOeN_R <= 1'b1;
            baseWeN_R <= 1'b1;
            extZ      <= 1'b1;
            extCeN_R  <= 1'b1;
            extOeN_R  <= 1'b1;
            extWeN_R  <= 1'b1;
            uartWrN_R <= 1'b1;
            uartRdN_R <= 1'b1;
            outData   <= 32'b0;
        end
        else begin
            case (state)
                S_IDLE   : begin
                    if (address[31:22] == 10'b1000_0000_00) begin
                        // 代码段
                        if (ramRd) begin
                            extZ        <= 1'b1;
                            state       <= S_E_RD_1;
                        end
                        else if (ramWr) begin
                            extZ        <= 1'b0;
                            extData     <= inBeBuff;
                            state       <= S_E_WR_1;
                        end
                    end
                    else if (address[31:22] == 10'b1000_0000_01) begin
                        // 数据段
                        if (ramRd) begin
                            baseZ       <= 1'b1;
                            state       <= S_B_RD_1;
                        end
                        else if (ramWr) begin
                            baseZ       <= 1'b0;
                            baseData    <= inBeBuff;
                            state       <= S_B_WR_1;
                        end
                    end
                    else if (address == 32'h1000_0000) begin
                        // UART 数据
                        if (ramRd) begin
                            baseZ       <= 1'b1;
                            state       <= S_U_RD_1;
                        end
                        else if (ramWr) begin
                            baseZ       <= 1'b0;
                            baseData    <= inBeBuff;
                            state       <= S_U_WR_0;
                        end
                    end
                    else if (address == 32'h1000_0005) begin
                        // UART 状态
                        if (ramRd) begin
                            outData     <= { 24'h0000_00, 2'b00, uartTbrE & uartTsrE, 4'b0000, uartDataready };
                            state       <= S_B_RD_3;
                        end
                    end
                end
                S_B_RD_1 : begin
                    baseCeN_R   <= 1'b0;
                    baseOeN_R   <= 1'b0;
                    state       <= S_B_RD_2;
                end
                S_B_RD_2 : begin
                    baseCeN_R   <= 1'b1;
                    baseOeN_R   <= 1'b1;
                    outData     <= baseIO;
                    state       <= S_B_RD_3;
                end
                S_B_RD_3 : begin
                    baseZ       <= 1'b1;
                    if (~ramRd)
                        state   <= S_IDLE;
                end
                S_B_WR_1 : begin
                    baseCeN_R   <= 1'b0;
                    baseWeN_R   <= 1'b0;
                    state       <= S_B_WR_2;
                end
                S_B_WR_2 : begin
                    baseCeN_R   <= 1'b1;
                    baseWeN_R   <= 1'b1;
                    state       <= S_B_WR_3;
                end
                S_B_WR_3 : begin
                    baseZ       <= 1'b1;
                    if (~ramWr)
                        state   <= S_IDLE;
                end
                S_E_RD_1 : begin
                    extCeN_R    <= 1'b0;
                    extOeN_R    <= 1'b0;
                    state       <= S_E_RD_2;
                end
                S_E_RD_2 : begin
                    extCeN_R    <= 1'b1;
                    extOeN_R    <= 1'b1;
                    outData     <= extIO;
                    state       <= S_E_RD_3;
                end
                S_E_RD_3 : begin
                    extZ        <= 1'b1;
                    if (~ramRd)
                        state   <= S_IDLE;
                end
                S_E_WR_1 : begin
                    extCeN_R    <= 1'b0;
                    extWeN_R    <= 1'b0;
                    state       <= S_E_WR_2;
                end
                S_E_WR_2 : begin
                    extCeN_R    <= 1'b1;
                    extWeN_R    <= 1'b1;
                    state       <= S_E_WR_3;
                end
                S_E_WR_3 : begin
                    baseZ       <= 1'b1;
                    if (~ramWr)
                        state   <= S_IDLE;
                end
                S_U_RD_1 : begin
                    uartRdN_R   <= 1'b0;
                    state       <= S_U_RD_2;
                end
                S_U_RD_2 : begin
                    state       <= S_U_RD_3;
                end
                S_U_RD_3 : begin
                    uartRdN_R   <= 1'b1;
                    outData     <= baseIO;
                    baseZ       <= 1'b1;
                    if (~ramRd)
                        state   <= S_IDLE;
                end
                S_U_WR_0 : begin
                    uartWrN_R   <= 1'b0;
                    state       <= S_U_WR_1;
                end
                S_U_WR_1 : begin
                    state       <= S_U_WR_2;
                end
                S_U_WR_2 : begin
                    state       <= S_U_WR_3;
                end
                S_U_WR_3 : begin
                    uartWrN_R   <= 1'b1;
                    baseZ       <= 1'b1;
                    if (~ramWr)
                        state   <= S_IDLE;
                end
                default  : begin

                end
            endcase
        end
    end


endmodule
