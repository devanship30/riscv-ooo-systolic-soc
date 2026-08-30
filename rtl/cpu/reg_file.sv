//CPU-register-File
//Last edited - 07/21

module reg_file (
input logic clk,
input logic rst_n,
input logic [4:0] rs1_addr,
output logic [31:0] rs1_data,
input logic [4:0] rs2_addr,
output logic [31:0] rs2_data,
input logic [4:0] rd_addr,
input logic [31:0] rd_data,
input logic wen);

logic [31:0] regs[31:0];

always_ff @(posedge clk) begin
if (!rst_n) begin
for (int a = 0; a<32; a++) begin
regs[a] <=32'b0;
end
end
else if (wen==1 && rd_addr!=5'b0) begin
regs[rd_addr]<=rd_data;
end
end

assign rs1_data=regs[rs1_addr];
assign rs2_data=regs[rs2_addr];

endmodule