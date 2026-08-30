//ALU file updated
//last edited - 07/21

typedef enum logic [4:0] {
ALU_ADD = 5'd0,
ALU_SUB = 5'd1,
ALU_AND = 5'd2,
ALU_OR = 5'd3,
ALU_XOR = 5'd4
} alu_op_t ;


module alu_top (
input  logic [31:0] operand_a,
input  logic [31:0] operand_b,
input  alu_op_t alu_op,
output  logic [31:0] result,
output logic zero
);

always_comb begin
case (alu_op)
ALU_ADD: result = operand_a + operand_b;
ALU_SUB: result = operand_a - operand_b;
ALU_AND: result = operand_a & operand_b;
ALU_OR:  result = operand_a | operand_b;
ALU_XOR: result = operand_a ^ operand_b;
default: result = 32'd0;
endcase
end
assign zero = (result==32'd0);
endmodule