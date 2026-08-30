module pe_array #(parameter N = 8)(
    input clk,
    input rst_n,
    input load_en,
    input signed [7:0] in_left_matrix [0:N-1],
    output logic signed [31:0] out_bottom_matrix [0:N-1]    
);

    logic signed [7:0] h_wire [N][N+1];
    logic signed [31:0] v_wire [N+1][N];

    genvar i,j;
    generate
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                if (j == 0 & i != 0) begin
                    pe uut (.in_left(in_left_matrix [i]), .in_top(h_wire [i][j]), .out_right(v_wire [i][j+1]), .out_right(v_wire [i+1][j]));
                end else if (i == 0 && j != 0) begin
                    pe uut (.in_left(h_wire [i][j]), .in_top(0), .out_right(v_wire [i][j+1]), .out_right(v_wire [i+1][j]));
                end else if (i == 0 && j == 0) begin
                    pe uut (.in_left(in_left_matrix [i]), .in_top(0), .out_right(v_wire [i][j+1]), .out_right(v_wire [i+1][j]));
                end else begin
                    pe uut (.in_left(h_wire [i][j]), .in_top(h_wire [i][j]), .out_right(v_wire [i][j+1]), .out_right(v_wire [i+1][j]));
                end
            end
        end

endmodule
