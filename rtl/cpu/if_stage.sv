//IF stage 
//last edited - 07/22

module if_stage(
//BASIC
input logic clk,
input logic rst_n,

//HAZARD INPUTS
input logic stall_if,
input logic flush_if,
input logic [1:0] pc_sel,
input logic [31:0]branch_target,
input logic [31:0]exception_target,

//AXI-SRAM MATCH
output logic [31:0]instr_araddr,
output logic instr_arvalid,
input logic instr_arready,
input logic [31:0]instr_rdata,
input logic instr_rvalid,
output logic instr_rready,

//OUTPUTS TO ID
output logic [31:0]if_id_pc,
output logic [31:0]if_id_instr,
output logic if_id_valid
);

logic [31:0] pc_reg;
logic [31:0] next_pc;

always_ff @(posedge clk) begin
if (!rst_n)
pc_reg<=32'h80000000;
else if (stall_if == 1)
pc_reg<=pc_reg;
else 
pc_reg <= next_pc;
end

always_comb begin
case (pc_sel)
2'b00: next_pc = pc_reg + 32'd4;
2'b01: next_pc = branch_target;
2'b11: next_pc = exception_target;
default: next_pc=pc_reg + 32'd4;
endcase
end

assign instr_araddr = pc_reg;
assign instr_arvalid = !stall_if;
assign instr_rready = 1'b1;

always_ff @(posedge clk) begin

if(!rst_n)begin
if_id_valid<=0;
if_id_pc<=0;
if_id_instr<=0;
end

else if(flush_if==1)
if_id_valid<=0;

else if (stall_if==1)begin
if_id_pc<=if_id_pc;
if_id_instr<=if_id_instr;
if_id_valid<=if_id_valid;
end

else begin
if_id_pc<=next_pc;
if_id_instr<=instr_rdata;
if_id_valid<=instr_rvalid;
end
end
endmodule