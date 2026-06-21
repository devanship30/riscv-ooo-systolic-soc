module tb_passthrough();

    logic clk;
    logic rst_n;
    logic [7:0] i_8bit;
    logic [7:0] o_8bit;

    passthrough uut(.clk(clk), .rst_n(rst_n), .i_8bit(i_8bit), .o_8bit(o_8bit));

    always #20 clk <= ~clk;

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, tb_passthrough);

        rst_n = 0;
        clk = 0;
        i_8bit = 8'b0;

        #10 rst_n = 1;
        #20 i_8bit = 4;
        #40 i_8bit = 0;
        #20 rst_n = 0;
        #40 rst_n = 1;
        #20 i_8bit = 1;
        #20 $finish;
    end

endmodule
