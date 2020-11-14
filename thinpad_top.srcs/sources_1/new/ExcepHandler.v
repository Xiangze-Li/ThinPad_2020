`default_nettype none

module ExcepHandler
(
    input  wire         clk,
    inout  wire         rst,

    input  wire         excepFlag,
    input  wire [31:0]  mcauseIn,

    input  wire         csrRd,
    input  wire         csrWr,
    input  wire [11:0]  csrAddr,
    input  wire [31:0]  csrDataIn,
    output wire [31:0]  csrDataOut,

    output wire         mode,
    output wire [31:0]  handlerAddr,
);
    localparam CSR_SIZE = 5;
    reg [31:0] CSRs [CSR_SIZE-1:0];

    reg [31:0] csrOutBuff;
    assign csrDataOut = csrOutBuff;

    integer i;
    always @(posedge clk, posedge rst) begin
        if (rst) begin
            for (i=0; i<CSR_SIZE; i=i+1) begin
                CSRs[i] = 32'b0;
            end
        end
    end


endmodule
