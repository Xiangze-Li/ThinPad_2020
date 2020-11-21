`timescale 1ns / 1ps
`default_nettype none

module MMU(
    input  wire        clk,
    input  wire        rst,

    input  wire [31:0] dataIn,
    input  wire [31:0] virtualAddr,
    output wire [31:0] dataOut,

    input  wire [1:0]  ramByte,
    input  wire        writeEn,
    input  wire        readEn,
    output wire        done,
    output wire        addrMisal,
    output wire        addrFault,
    output reg         pageFault,

    input  wire        mode,  // 0 for user 1 for machine
    input  wire [21:0] ppn,

    // port only for ramController
    inout  wire [31:0] baseIO,
    output wire [19:0] baseAddr,
    output wire        baseCeN,
    output wire [3:0]  baseBeN,
    output wire        baseOeN,
    output wire        baseWeN,

    inout  wire [31:0] extIO,
    output wire [19:0] extAddr,
    output wire        extCeN,
    output wire [3:0]  extBeN,
    output wire        extOeN,
    output wire        extWeN,

    input  wire        uartDataready,
    input  wire        uartTbrE,
    input  wire        uartTsrE,
    output wire        uartRdN,
    output wire        uartWrN
);

    localparam [3:0]
        S_IDLE          = 4'b0000,
        S_RAM_BEGAIN    = 4'b1000,
        S_EXCP          = 4'b1111;

    reg [3:0] state;

    wire ramDone;
    reg ramWr, ramRd;
    reg [31:0] physicalAddr;


    RamController ramController(
        .clk(clk),
        .rst(rst),

        .dataIn(dataIn),
        .dataOut(dataOut),
        .address(physicalAddr),

        .ramWr(ramWr),
        .ramRd(ramRd),
        .ramByte(ramByte),
        .ramDone(ramDone),

        .baseIO(baseIO),
        .baseAddr(baseAddr),
        .baseCeN(baseCeN),
        .baseBeN(baseBeN),
        .baseOeN(baseOeN),
        .baseWeN(baseWeN),

        .extIO(extIO),
        .extAddr(extAddr),
        .extCeN(extCeN),
        .extBeN(extBeN),
        .extOeN(extOeN),
        .extWeN(extWeN),

        .uartDataready(uartDataready),
        .uartTbrE(uartTbrE),
        .uartTsrE(uartTsrE),
        .uartRdN(uartRdN),
        .uartWrN(uartWrN),

        .addrMisal(addrMisal),
        .addrFault(addrFault)
    );


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            pageFault <= 1'b0;
            ramWr <= 1'b0;
            ramRd <= 1'b0;
            physicalAddr <= 32'b0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (mode) begin  // machine mode
                        physicalAddr <= virtualAddr;
                        state <= S_RAM_BEGAIN;
                    end
                    else begin
//                        if (
                    end
                end
            endcase
        end
    end
endmodule
