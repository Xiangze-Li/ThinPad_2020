`timescale 1ns / 1ps

module ClkGen(
    input  wire clk_50M,
    input  wire reset_btn,

    output wire clk_10M,
    output wire clk_15M,
    output wire clk_20M,
    output wire clk_25M,
    output reg  rst_10M,
    output reg  rst_15M,
    output reg  rst_20M,
    output reg  rst_25M
);

    wire locked;
    pll_example clk_gen(
        .clk_in1(clk_50M),
        .reset(reset_btn),

        .clk_out1(clk_10M),
        .clk_out2(clk_15M),
        .clk_out3(clk_20M),
        .clk_out4(clk_25M),
        .locked(locked)
    );

    always @(posedge clk_10M, negedge locked) begin
        if (~locked)
            rst_10M <= 1'b1;
        else
            rst_10M <= 1'b0;
    end

    always @(posedge clk_15M, negedge locked) begin
        if (~locked)
            rst_15M <= 1'b1;
        else
            rst_15M <= 1'b0;
    end

    always @(posedge clk_20M, negedge locked) begin
        if (~locked)
            rst_20M <= 1'b1;
        else
            rst_20M <= 1'b0;
    end

    always @(posedge clk_25M, negedge locked) begin
        if (~locked)
            rst_25M <= 1'b1;
        else
            rst_25M <= 1'b0;
    end

endmodule
