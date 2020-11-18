`default_nettype none

module ExcepHandler
(
    input  wire         clk,
    inout  wire         rst,

    input  wire         excepFlag,
    input  wire         retFlag,
    input  wire [31:0]  mcauseIn,
    input  wire [31:0]  pcNowIn,

    input  wire [1:0]   csrWrOp,
    input  wire [11:0]  csrAddr,
    input  wire [31:0]  csrDataIn,
    output wire [31:0]  csrDataOut,

    output wire         mode,
    output wire [31:0]  handlerAddr,
    output wire [31:0]  epcOut
);
    localparam CSR_SIZE = 6;
    reg [31:0] CSRs [CSR_SIZE-1:0];

    /*
        CSR addr    true addr   name        part
        0x300       0           mstatus     [12:11] MPP
        0x305       1           mtvec       [31:2] BASE, [1:0] MODE
        0x340       2           mscratch    [31:0]
        0x341       3           mepc        [31:0]
        0x342       4           mcause      [31] Interrupt, [30:0] ExcepCode
    */

    reg [2:0] trueAddr;
    always @(csrAddr) begin
        case (csrAddr)
            12'h300 : trueAddr = 3'd0;
            12'h305 : trueAddr = 3'd1;
            12'h340 : trueAddr = 3'd2;
            12'h341 : trueAddr = 3'd3;
            12'h342 : trueAddr = 3'd4;
            default : trueAddr = 3'd5;
        endcase
    end

    wire [31:0] vectorAddr;
    assign vectorAddr = { 2'b00, CSRs[1][31:2]+(CSRs[4][29:0]<<2) };

    assign handlerAddr = (CSRs[1][1:0] == 2'b00 ? CSRs[1] : vectorAddr);
    assign epcOut = CSRs[3];
    assign csrDataOut = CSRs[trueAddr];

    parameter [1:0]
        MODE_U = 2'b00,
        MODE_M = 2'b11;
    reg [1:0] mode_R;
    assign mode = (mode_R == 2'b11);

    integer i;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            for (i=0; i<CSR_SIZE; i=i+1) begin
                CSRs[i] <= 32'b0;
            end
            mode_R <= MODE_M;
        end
        else if (excepFlag) begin
            CSRs[4]         <= mcauseIn;
            CSRs[3]         <= pcNowIn;
            CSRs[0][12:11]  <= 2'b00;
            mode_R          <= MODE_M;
        end
        else if (retFlag) begin
            mode_R          <= MODE_U;
        end
        else begin
            case (csrWrOp)
                2'b00 : begin end
                2'b01 : CSRs[trueAddr] <= csrDataIn;
                2'b10 : CSRs[trueAddr] <= CSRs[trueAddr] | csrDataIn;
                2'b11 : CSRs[trueAddr] <= CSRs[trueAddr] ^ csrDataIn;
            endcase
        end
    end


endmodule
