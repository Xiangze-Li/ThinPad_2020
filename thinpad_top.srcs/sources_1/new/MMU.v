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
        S_IDLE              = 4'b0000,
        S_FETCH_PTE_BEGIN   = 4'b0001,
        S_FETCH_PTE_DONE    = 4'b0010,
        S_RAM_BEGIN         = 4'b1000,
        S_RAM_DONE          = 4'b1001,
        S_DONE              = 4'b1110,
        S_EXCP              = 4'b1111;

    reg [3:0] state;

    wire ramDone;
    reg ramWr, ramRd;
    reg [31:0] ramAddr;
    reg [31:0] ramOutReg;
    wire ramAddrFalut, ramAddrMisal;

    wire userAddrFalut;  // don't check if in user mode

    // translation vars. refer to priviledged doc p75
    reg transI;
    wire [33:0] transPTEAddr;
    wire [33:0] physicalAddr;


    assign done = (state == S_EXCP) || (state == S_DONE);
    assign addrFault = pageFault ? 1'b0 : ramAddrFalut;
    assign addrMisal = (pageFault || addrFault) ? 1'b0 : ramAddrMisal;
    assign userAddrFalut = !(
    (32'h00000000 < virtualAddr && virtualAddr < 32'h002FFFFF && !writeEn) ||
    (32'h7FC10000 < virtualAddr && virtualAddr < 32'h7FFFFFFF) ||
    (32'h80000000 < virtualAddr && virtualAddr < 32'h80000FFF && !writeEn) ||
    (32'h80100000 < virtualAddr && virtualAddr < 32'h80100FFF && !writeEn)
    );
    assign transPTEAddr = {ppn, (transI ? virtualAddr[31:22] : virtualAddr[21:12]), 2'b0};
    assign physicalAddr = {ramOutReg[31:20], (transI ? virtualAddr[21:12] : ramOutReg[19:10]), virtualAddr[11:0]};


    RamController ramController(
        .clk(clk),
        .rst(rst),

        .dataIn(dataIn),
        .dataOut(dataOut),
        .address(ramAddr),

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

        .addrMisal(ramAddrMisal),
        .addrFault(ramAddrFalut)
    );


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            pageFault <= 1'b0;
            ramWr <= 1'b0;
            ramRd <= 1'b0;
            transI <= 1'b1;
            ramAddr <= 32'b0;
            ramOutReg <= 32'b0;
        end
        else begin
            case (state)
                S_IDLE: begin
                    if (writeEn || readEn) begin
                        if (mode) begin  // machine mode
                            state <= S_RAM_BEGIN;
                        end
                        else begin  // user mode
                            if (userAddrFalut) begin
                                pageFault <= 1'b1;
                                state <= S_EXCP;
                            end
                            else begin
                                state <= S_FETCH_PTE_BEGIN;
                                transI <= 1'b1;
                            end
                        end
                    end
                end
                S_FETCH_PTE_BEGIN: begin
                    ramAddr <= transPTEAddr;
                    ramRd   <= 1'b1;
                    state   <= S_FETCH_PTE_DONE;
                end
                S_FETCH_PTE_DONE: begin
                    if (ramDone) begin
                        if (ramAddrMisal || ramAddrFalut) begin
                            state <= S_EXCP;
                        end
                        else begin
                            ramRd <= 1'b0;
                            if (dataOut[3] || dataOut[1]) begin  // leaf found
                                ramOutReg <= dataOut;
                                state <= S_RAM_BEGIN;
                            end
                            else begin  // pointer to next
                                if (!transI) begin  // i == 0. page fault
                                    pageFault <= 1'b1;
                                    state <= S_EXCP;
                                end
                                else begin  // i == 1, fetch pte
                                    transI <= 1'b0;
                                    state <= S_FETCH_PTE_BEGIN;
                                end
                            end
                        end
                    end
                end
                S_RAM_BEGIN: begin
                    ramAddr <= mode ? virtualAddr : ramOutReg;
                    ramRd   <= readEn;
                    ramWr   <= writeEn;
                    state   <= S_RAM_DONE;
                end
                S_RAM_DONE: begin
                    if (ramDone) begin
                        if (ramAddrMisal || ramAddrFalut) begin
                            state <= S_EXCP;
                        end
                        else begin
                            ramRd <= 1'b0;
                            ramWr <= 1'b0;
                            state <= S_DONE;
                        end
                    end
                end
                S_DONE: begin
                    if (!writeEn && !readEn) begin
                        state <= S_IDLE;
                        pageFault <= 1'b0;
                    end
                end
                S_EXCP: begin
                    if (!writeEn && !readEn) begin
                        ramRd <= 1'b0;
                        ramWr <= 1'b0;
                        state <= S_IDLE;
                        pageFault <= 1'b0;
                    end
                end
                default: begin
                end
            endcase
        end
    end
endmodule
