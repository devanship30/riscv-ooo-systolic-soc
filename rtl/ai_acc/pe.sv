module pe (
    input clk,
    input rst_n,
    input load_en,
    input signed [7:0] in_left,
    input signed [31:0] in_top,
    output logic signed [7:0] out_right,
    output logic signed [31:0] out_bottom
);

    logic signed [7:0] weight_reg;

    always_ff @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            out_right <= 0;
            out_bottom <= 0;
            weight_reg <= 0;
        end else if (load_en) begin
            weight_reg <= in_left;
            out_right <= in_left;
            out_bottom <= 0;
        end else begin
            out_right <= in_left;
            out_bottom <= in_top + (in_left * weight_reg);
        end

endmodule
