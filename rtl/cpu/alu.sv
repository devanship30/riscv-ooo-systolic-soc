//=============================================================================
// alu.sv — Arithmetic Logic Unit (RV32I base operations)
// Spec: RISC-V Unprivileged ISA v20191213, Section 2.4
//
// Operations: ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU, LUI, AUIPC
// M-extension (MUL/DIV) handled separately in mul_div_unit.sv
//
// Note: alu_op_t enum defined in rv32_defines.svh
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] All ALU operations
//            [ ] AUIPC uses PC — ensure pc port is wired in ex_stage
//=============================================================================

`include "rv32_defines.svh"

module alu (
    input  alu_op_t     alu_op,
    input  logic [31:0] operand_a,    // rs1 (after forwarding)
    input  logic [31:0] operand_b,    // rs2 or immediate (after mux)
    input  logic [31:0] pc,           // current PC (needed for AUIPC)
    output logic [31:0] result,
    output logic        zero          // result == 0 (useful for branch compare)
);

    //=========================================================================
    // TODO: ALU operation mux
    // All operations are purely combinational — no registers here.
    //=========================================================================
    always_comb begin
        result = 32'd0; // default

        case (alu_op)
            ALU_ADD  : result = operand_a + operand_b;
            ALU_SUB  : result = operand_a - operand_b;
            ALU_AND  : result = operand_a & operand_b;
            ALU_OR   : result = operand_a | operand_b;
            ALU_XOR  : result = operand_a ^ operand_b;

            // Shift operations: shift amount is operand_b[4:0] per spec
            // Spec: Section 2.4.1 — "shift amount is in lower 5 bits of rs2/imm"
            ALU_SLL  : result = operand_a << operand_b[4:0];
            ALU_SRL  : result = operand_a >> operand_b[4:0];
            ALU_SRA  : result = $signed(operand_a) >>> operand_b[4:0];

            // Set Less Than (signed)
            // Spec: Section 2.4 — result is 1 if rs1 < rs2 signed, else 0
            ALU_SLT  : result = ($signed(operand_a) < $signed(operand_b)) ? 32'd1 : 32'd0;
            ALU_SLTU : result = (operand_a < operand_b) ? 32'd1 : 32'd0;

            // LUI: rd = {imm[31:12], 12'b0}
            // operand_b already holds the U-immediate (upper 20 bits, lower 12 = 0)
            ALU_LUI  : result = operand_b;

            // AUIPC: rd = PC + {imm[31:12], 12'b0}
            ALU_AUIPC: result = pc + operand_b;

            // M-extension ops are routed here but computed in mul_div_unit
            // Returning 0 for these prevents latch; ex_stage mux overrides
            ALU_MUL,
            ALU_MULH,
            ALU_MULHSU,
            ALU_MULHU,
            ALU_DIV,
            ALU_DIVU,
            ALU_REM,
            ALU_REMU : result = 32'd0; // overridden by mul_div_unit result

            ALU_NOP  : result = 32'd0;

            default  : result = 32'd0;
        endcase
    end

    assign zero = (result == 32'd0);

endmodule
