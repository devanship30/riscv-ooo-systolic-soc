//Instruction Decode Stage
//last edited - 07/22


module decode_stage (
input logic clk,
input logic rst_n,

//Inputs to ID from IF
input logic [31:0] if_id_instr, //fetched instruction
input logic [31:0] if_id_pc,   //PC of instruction
input logic if_id_valid,      //is instruction valid or just a bubble?

//Hazard controls
input logic stall_id, //freeze this stage
input logic flush_id, //insert bubble

//Since ID has register, WB write in ID
input logic [4:0] wb_rd_addr, //which register do WB wanna write
input logic [31:0] wb_rd_data, //what value WB is writing
input logic wb_wen, //is WB actually writing?

//Outputs to EX stage from ID
output logic [4:0] id_ex_rs1_addr, //id to ex- RS1 address
output logic [4:0] id_ex_rs2_addr, //id to ex - RS2 address
output logic [4:0] id_ex_rd_addr,  //id to ex - destination reg addr
output logic [31:0]id_ex_rs1_data, //id to ex - rs1 value
output logic [31:0]id_ex_rs2_data, //id to ex - rs2 value
output logic [31:0]id_ex_imm,      //id to ex - signed extended immediate
output logic [31:0]id_ex_pc,       //id to ex - program counter forward
output logic [4:0] id_ex_alu_op,   //id to ex - which ALU operation
output logic       id_ex_alu_src,  //When 0 -> use rs2, when 1->use imm
output logic       id_ex_mem_read, //is this a LOAD?
output logic       id_ex_mem_write,//is this a STORE?
output logic       id_ex_reg_wen,  //does this write a register?
output logic [1:0] id_ex_wb_src,   //writeback source (ALU/MEM/PC+4)
output logic       id_ex_is_branch,//is this a branch?
output logic       id_ex_valid     //is this a Valid instruction
); 


logic [6:0] opcode;
logic [4:0] rd;
logic [2:0] funct3; 
logic [4:0] rs1;
logic [4:0] rs2;
logic [6:0] funct7;

assign opcode = if_id_instr [6:0]; 
assign rd     = if_id_instr [11:7];
assign funct3 = if_id_instr [14:12];
assign rs1    = if_id_instr [19:15];
assign rs2    = if_id_instr [24:20];
assign funct7 = if_id_instr [31:25];

logic [31:0] rs1_data;
logic [31:0] rs2_data;

//REGISTER FILE INSTANTIATION
reg_file u_reg_file(
.clk(clk),
.rst_n(rst_n),
.rs1_addr(rs1),
.rs2_addr(rs2),
.rd_addr(wb_rd_addr),
.rd_data(wb_rd_data),
.wen(wb_wen),
.rs1_data(rs1_data),
.rs2_data(rs2_data)
);


//DECLARING CONTROL SIGNALS
logic [4:0] dec_alu_op;
logic       dec_alu_src; //which second operand does ALU use?
logic       dec_mem_read; //should we read memory? (1=YES-> Load instr)
logic       dec_mem_write;//should we write to mem? (1=YES->Store instr)
logic       dec_reg_wen; //write result to register? (1=YES, write to rd)
logic [1:0] dec_wb_src;  //where final result come from? (2'b00->ALU....)
logic       dec_is_branch;//is this branch instr?(1=YES->BEQ,BNE...)

always_comb begin
dec_alu_op    = 5'd0;
dec_alu_src   = 0;
dec_mem_read  = 0;
dec_mem_write = 0;
dec_reg_wen   = 0;
dec_wb_src    = 2'b00;
dec_is_branch = 0;

case(opcode)
7'b0110011: begin
dec_alu_src=0; dec_reg_wen=1; dec_mem_read=0; dec_mem_write=0;
end
7'b0010011: begin
dec_alu_src=1; dec_reg_wen=1; dec_mem_read=0; dec_mem_write=0;
end
7'b0000011: begin 
dec_alu_src=1; dec_reg_wen=1; dec_mem_read=1; dec_mem_write=0;
end
7'b0100011: begin 
dec_alu_src=1; dec_reg_wen=0; dec_mem_read=0; dec_mem_write=1;
end
7'b1100011: begin
dec_is_branch=1; dec_reg_wen=0;
end 
endcase
end

always_ff @(posedge clk) begin

if(!rst_n)begin
id_ex_alu_op<=0;
id_ex_alu_src<=0;
id_ex_mem_write<=0;
id_ex_mem_read<=0;
id_ex_reg_wen<=0;
id_ex_wb_src<=0;
id_ex_is_branch<=0;
id_ex_valid<=0;
id_ex_rs1_addr<=0;
id_ex_rs2_addr<=0;
id_ex_rd_addr<=0;
id_ex_pc<=0;
end

else if(flush_id==1)
id_ex_valid<=0;

else if (stall_id==1)begin

end

else begin
id_ex_rs1_addr <=          rs1;
id_ex_rs2_addr <=          rs2;
id_ex_rd_addr  <=           rd;
id_ex_rs1_data <=     rs1_data;
id_ex_rs2_data <=     rs2_data;
id_ex_imm      <=        32'd0;
id_ex_pc       <=     if_id_pc;
id_ex_alu_op   <=   dec_alu_op;
id_ex_alu_src  <=  dec_alu_src;
id_ex_mem_read <= dec_mem_read;
id_ex_mem_write<=dec_mem_write;
id_ex_reg_wen  <=  dec_reg_wen;
id_ex_wb_src   <=   dec_wb_src;
id_ex_is_branch<=dec_is_branch;
id_ex_valid    <=  if_id_valid;
end
end
endmodule