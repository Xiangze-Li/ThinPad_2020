`default_nettype none

module ALU
(
    input  wire                 ri,
    input  wire signed [31:0]   oprandA,
    input  wire signed [31:0]   oprandB,
    input  wire        [2:0]    funct3,
    input  wire        [6:0]    funct7,

    output reg  signed [31:0]   result,
    output wire                 flagZero
);

    assign flagZero = &(~result);

    wire [31:0] pcnt;

    // - NOTE: ALU Logics
    always @(*) begin
        if (ri) begin
            // I-type
            case (funct3)
                3'b000 :
                    result = oprandA + oprandB;
                3'b001 : begin
                    case (funct7)
                        7'b0000000 :
                            result = oprandA << oprandB[4:0];
                        7'b0110000 :
                            result = pcnt;
                        default :
                            result = 32'hF0F0_F0F0;
                    endcase
                end
                3'b101 :
                    result = (funct7[5] ? oprandA >>> oprandB[4:0] : oprandA >> oprandB[4:0]);
                3'b110 :
                    result = oprandA | oprandB;
                3'b111 :
                    result = oprandA & oprandB;
                default :
                    result = 32'hF0F0_F0F0;
            endcase
        end
        else begin
            // R-type
            case (funct3)
                3'b000 :
                    result = funct7[5] ? oprandA - oprandB : oprandA + oprandB;
                3'b100 :
                    result = (funct7[2] ?
                            { oprandB[15:0], oprandA[15:0] } :
                            oprandA ^ (funct7[5] ? ~oprandB : oprandB));
                3'b110 :
                    result = oprandA | oprandB;
                3'b111 :
                    result = oprandA & oprandB;
                default:
                    result = 32'hF0F0_F0F0;
            endcase
        end
    end

    PCNT pcnt_module(oprandA, pcnt);

endmodule  //ALU


module PCNT
(
    input  wire [31:0]  oprandA,
    output wire [31:0]  result
);

    reg [31:0] cntr = 32'b0;

    reg [3:0] part[7:0];
    integer i;

    always @(*) begin
        for (i = 0; i < 8; i = i+1) begin
            case(oprandA[i*4 +: 4])
                4'b0000 :
                    part[i] = 3'd0;
                4'b0001, 4'b0010, 4'b0100, 4'b1000 :
                    part[i] = 3'd1;
                4'b0011, 4'b0110, 4'b1100, 4'b0101, 4'b1010, 4'b1001 :
                    part[i] = 3'd2;
                4'b0111, 4'b1011, 4'b1101, 4'b1110 :
                    part[i] = 3'd3;
                4'b1111 :
                    part[i] = 3'd4;
            endcase
        end
    end

    wire [4:0] sum1[3:0];
    wire [5:0] sum2[1:0];
    wire [6:0] sum;

    assign sum1[0] = part[0] + part[1];
    assign sum1[1] = part[2] + part[3];
    assign sum1[2] = part[4] + part[5];
    assign sum1[3] = part[6] + part[7];

    assign sum2[0] = sum1[0] + sum1[1];
    assign sum2[1] = sum1[2] + sum1[3];

    assign sum = sum2[0] + sum2[1];

    assign result = { 25'b0, sum };

endmodule
