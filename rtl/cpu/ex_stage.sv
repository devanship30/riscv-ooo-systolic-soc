//Execute stage
//last edited - 07/23

module execute_stage(

//BASIC
input logic clk,
input logic rst_n,

//Inputs to EX
input logic [4:0] id_ex_rs1_addr, //id to ex- RS1 address
input logic [4:0] id_ex_rs2_addr, //id to ex - RS2 address
input logic [4:0] id_ex_rd_addr,  //id to ex - destination reg addr
input logic [31:0]id_ex_rs1_data, //id to ex - rs1 value
input logic [31:0]id_ex_rs2_data, //id to ex - rs2 value
input logic [31:0]id_ex_imm,      //id to ex - signed extended immediate
input logic [31:0]id_ex_pc,       //id to ex - program counter forward
input logic [4:0] id_ex_alu_op,   //id to ex - which ALU operation
input logic       id_ex_alu_src,  //When 0 -> use rs2, when 1->use imm
input logic       id_ex_mem_read, //is this a LOAD?
input logic       id_ex_mem_write,//is this a STORE?
input logic       id_ex_reg_wen,  //does this write a register?
input logic [1:0] id_ex_wb_src,   //writeback source (ALU/MEM/PC+4)
input logic       id_ex_is_branch,//is this a branch?
input logic       id_ex_valid,


//INPUTS FROM HAZARD UNIT
input logic [1:0] fwd_a_sel, //operand A forwarding
input logic [1:0] fwd_b_sel,//operand B forwarding

//FORWARDING DATA INPUTS
input logic [31:0] ex_mem_alu_result,
input logic [31:0] mem_wb_result,

//OUTPUTS TO MEM STAGE from EX stage
output logic [4:0] ex_mem_rd_addr,
output logic [31:0] ex_mem_alu_result_out,
output logic [31:0] ex_mem_rs2_data,
output logic        ex_mem_mem_read,
output logic        ex_mem_mem_write,
output logic        ex_mem_reg_wen,
output logic [1:0]  ex_mem_wb_src,
output logic        ex_mem_valid,
output logic [31:0] ex_mem_pc_plus4,
output logic        ex_mem_is_branch,

//BRANCH OUTPUTS TO IF
output logic branch_taken,
output logic [31:0] branch_target
);

logic [31:0] operand_a_rs1;
logic [31:0] operand_b_rs2;
logic [31:0] operand_b;
//since operand B's alu_src picks one between rs2 and immediate value 
assign operand_b=id_ex_alu_src ? id_ex_imm : operand_b_rs2;

always_comb begin
case(fwd_a_sel)
2'b00:operand_a_rs1 = id_ex_rs1_data;
2'b01:operand_a_rs1 = ex_mem_alu_result;
2'b10:operand_a_rs1 = mem_wb_result;
default: operand_a_rs1=id_ex_rs1_data;
endcase

case(fwd_b_sel)
2'b00:operand_b_rs2 = id_ex_rs2_data;
2'b01:operand_b_rs2 = ex_mem_alu_result;
2'b10:operand_b_rs2 = mem_wb_result;
default: operand_b_rs2=id_ex_rs2_data;
endcase
end

logic [31:0] alu_result;
logic        alu_zero;

alu u_alu (
.alu_op(id_ex_alu_op),
.operand_a(operand_a_rs1),
.operand_b(operand_b),
.pc(id_ex_pc),
.result(alu_result),
.zero(alu_zero)
);

//BRANCH LOGIC
assign branch_target= id_ex_pc + id_ex_imm;
assign branch_taken = id_ex_is_branch & alu_zero & id_ex_valid;


//EX-MEM PIPELINE REGISTER
always_ff @(posedge clk) begin

if(!rst_n) begin
ex_mem_rd_addr<=0;
ex_mem_alu_result_out<=0;
ex_mem_rs2_data<=0;
ex_mem_mem_read<=0;
ex_mem_mem_write<=0;
ex_mem_reg_wen<=0;
ex_mem_wb_src<=0;
ex_mem_valid<=0;
ex_mem_pc_plus4<=0;
ex_mem_is_branch<=0;
end
else begin
ex_mem_rd_addr<= id_ex_rd_addr;
ex_mem_alu_result_out<= alu_result;
ex_mem_rs2_data<= operand_b_rs2;
ex_mem_mem_read<= id_ex_mem_read;
ex_mem_mem_write<= id_ex_mem_write;
ex_mem_reg_wen<= id_ex_reg_wen;
ex_mem_wb_src<= id_ex_wb_src;
ex_mem_valid<= id_ex_valid;
ex_mem_pc_plus4<= id_ex_pc + 32'd4;
ex_mem_is_branch<= branch_taken;
end
end

















