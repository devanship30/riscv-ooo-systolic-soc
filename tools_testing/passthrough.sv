module passthrough (clk, rst_n, i_8bit, o_8bit);

    input clk;
    input rst_n;
    input [7:0] i_8bit;
    output logic [7:0] o_8bit;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n)
            o_8bit <= 8'b0;
        else
            o_8bit <= i_8bit;

endmodule
