`timescale 1ns/1ps

module top_tb();

    initial begin
        $dumpfile("top_tb.vcd");
        $dumpvars(0,D1);
    end

    reg ck = 1'b0;          


    always begin
        #31 ck = ~ck;     
    end

    divider D1(
        .clk(ck),
        .out());
    defparam D1.divide_num=3;// N : Div parameter N+1 Divide
    initial begin
        #1000 $finish;

    end

endmodule