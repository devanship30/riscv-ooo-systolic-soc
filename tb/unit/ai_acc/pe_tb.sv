module pe_tb();

    logic clk;
    logic rst_n;
    logic load_en;
    logic [7:0] in_left;
    logic [31:0] in_top;
    logic [7:0] out_right;
    logic [31:0] out_bottom;

    pe uut(.clk(clk), .rst_n(rst_n), .load_en(load_en), .in_left(in_left), .in_top(in_top), .out_right(out_right), .out_bottom(out_bottom));

    always #10 clk <= ~clk;

    initial begin
        $dumpfile("sim_output/pe_dump.vcd");
        $dumpvars(0, pe_tb);

        clk = 0;
        rst_n = 0;
        load_en = 0;
        in_left = 0;
        in_top = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        @(posedge clk); #1;
        load_en = 1; 
        in_left = 3;

        @(posedge clk); #1;
        load_en = 0; 
        in_left = 2;

        @(posedge clk); #1;
        in_left = 4; 
        in_top = 6;

        @(posedge clk); #1;
        in_left = -1; 
        in_top = 0;

        @(posedge clk); #1;
        @(posedge clk); #1;
        $finish;
    end

endmodule
