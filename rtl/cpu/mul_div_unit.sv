//=============================================================================
// mul_div_unit.sv — M-Extension Multiply/Divide Unit
// Spec: RISC-V Unprivileged ISA v20191213, Chapter 7 (M Standard Extension)
//
// Supported operations:
//   MUL    : rd = (rs1 × rs2)[31:0]        (signed × signed, lower 32 bits)
//   MULH   : rd = (rs1 × rs2)[63:32]       (signed × signed, upper 32 bits)
//   MULHU  : rd = (rs1 × rs2)[63:32]       (unsigned × unsigned, upper 32 bits)
//   MULHSU : rd = (rs1 × rs2)[63:32]       (signed × unsigned, upper 32 bits)
//   DIV    : rd = rs1 / rs2  (signed)
//   DIVU   : rd = rs1 / rs2  (unsigned)
//   REM    : rd = rs1 % rs2  (signed)
//   REMU   : rd = rs1 % rs2  (unsigned)
//
// Special cases per spec Section 7.2:
//   DIV/REM: division by zero → quotient = -1 (all 1s), remainder = dividend
//   DIV/REM: overflow (INT_MIN / -1) → quotient = INT_MIN, remainder = 0
//
// Latency model (Week 2 starting point):
//   MUL variants: 1-cycle (done asserted next cycle after start)
//   DIV/REM:      configurable LATENCY_DIV cycles (default 32)
//   This is NOT a production divider — replace with SRT or radix-4 later.
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] Multi-cycle divide FSM
//            [ ] All 8 operations
//            [ ] Special case handling (div-by-zero, overflow)
//=============================================================================

`include "rv32_defines.svh"

module mul_div_unit #(
    parameter LATENCY_DIV = 32   // cycles for divide (simplistic model)
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,          // pulse: 1 = begin operation
    input  alu_op_t     alu_op,
    input  logic [31:0] operand_a,      // rs1
    input  logic [31:0] operand_b,      // rs2
    output logic [31:0] result,
    output logic        done            // 1 = result valid this cycle
);

    //=========================================================================
    // MUL variants — 1-cycle (combinational with 1 registered stage)
    //=========================================================================
    logic [63:0] mul_ss;   // signed × signed
    logic [63:0] mul_uu;   // unsigned × unsigned
    logic [63:0] mul_su;   // signed × unsigned

    assign mul_ss = $signed(operand_a)   * $signed(operand_b);
    assign mul_uu = operand_a             * operand_b;
    assign mul_su = $signed(operand_a)   * $unsigned(operand_b);

    //=========================================================================
    // DIV/REM — simple counter-based model (replace with proper divider later)
    //=========================================================================
    logic [$clog2(LATENCY_DIV+1)-1:0] div_counter;
    logic        div_busy;
    logic [31:0] div_a_reg, div_b_reg;
    alu_op_t     div_op_reg;

    // Latch inputs on start
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_busy    <= 1'b0;
            div_counter <= '0;
            div_a_reg   <= 32'd0;
            div_b_reg   <= 32'd0;
            div_op_reg  <= ALU_NOP;
        end else if (start && (alu_op inside {ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU})) begin
            div_busy    <= 1'b1;
            div_counter <= LATENCY_DIV - 1;
            div_a_reg   <= operand_a;
            div_b_reg   <= operand_b;
            div_op_reg  <= alu_op;
        end else if (div_busy) begin
            if (div_counter == 0) begin
                div_busy <= 1'b0;
            end else begin
                div_counter <= div_counter - 1;
            end
        end
    end

    // Division result (behavioral — synthesis tool will map to IP or DSP)
    logic [31:0] div_result_comb;
    always_comb begin
        div_result_comb = 32'd0;
        case (div_op_reg)
            ALU_DIV: begin
                // Spec 7.2: division by zero → quotient = -1
                // Spec 7.2: INT_MIN / -1 → INT_MIN (overflow)
                if (div_b_reg == 32'd0) begin
                    div_result_comb = 32'hFFFF_FFFF; // -1
                end else if ((div_a_reg == 32'h8000_0000) && (div_b_reg == 32'hFFFF_FFFF)) begin
                    div_result_comb = 32'h8000_0000; // overflow
                end else begin
                    div_result_comb = $signed(div_a_reg) / $signed(div_b_reg);
                end
            end
            ALU_DIVU: begin
                div_result_comb = (div_b_reg == 32'd0) ? 32'hFFFF_FFFF :
                                   div_a_reg / div_b_reg;
            end
            ALU_REM: begin
                if (div_b_reg == 32'd0) begin
                    div_result_comb = div_a_reg; // remainder = dividend
                end else if ((div_a_reg == 32'h8000_0000) && (div_b_reg == 32'hFFFF_FFFF)) begin
                    div_result_comb = 32'd0; // overflow remainder = 0
                end else begin
                    div_result_comb = $signed(div_a_reg) % $signed(div_b_reg);
                end
            end
            ALU_REMU: begin
                div_result_comb = (div_b_reg == 32'd0) ? div_a_reg :
                                   div_a_reg % div_b_reg;
            end
            default: div_result_comb = 32'd0;
        endcase
    end

    //=========================================================================
    // Result and done mux
    //=========================================================================
    logic is_div_op;
    assign is_div_op = (alu_op inside {ALU_DIV, ALU_DIVU, ALU_REM, ALU_REMU});

    always_comb begin
        result = 32'd0;
        done   = 1'b0;

        case (alu_op)
            ALU_MUL   : begin result = mul_ss[31:0];  done = 1'b1; end
            ALU_MULH  : begin result = mul_ss[63:32]; done = 1'b1; end
            ALU_MULHU : begin result = mul_uu[63:32]; done = 1'b1; end
            ALU_MULHSU: begin result = mul_su[63:32]; done = 1'b1; end
            ALU_DIV,
            ALU_DIVU,
            ALU_REM,
            ALU_REMU  : begin
                result = div_result_comb;
                done   = (div_busy && div_counter == 0);
            end
            default: begin
                result = 32'd0;
                done   = 1'b0;
            end
        endcase
    end

endmodule
