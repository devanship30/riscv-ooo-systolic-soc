//=============================================================================
// ex_stage.sv — Execute Stage
// Spec: RISC-V Unprivileged ISA v20191213
//       Section 2.4 (Integer Computational Instructions)
//       Section 2.5 (Control Transfer Instructions)
//
// Responsibilities:
//   1. Select forwarded operands (EX→EX, MEM→EX forwarding)
//   2. Run ALU / MUL/DIV unit
//   3. Evaluate branch condition (BEQ/BNE/BLT/BGE/BLTU/BGEU)
//   4. Compute branch and JAL/JALR target addresses
//   5. Read/write CSR registers
//   6. Output EX/MEM pipeline register
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] ALU operation logic
//            [ ] Branch condition evaluation
//            [ ] Forwarding mux wiring
//            [ ] MUL/DIV unit instantiation
//            [ ] CSR R/W path
//=============================================================================

`include "rv32_defines.svh"

module ex_stage (
    input  logic        clk,
    input  logic        rst_n,

    //-------------------------------------------------------------------------
    // ID/EX pipeline register inputs
    //-------------------------------------------------------------------------
    input  logic [4:0]  id_ex_rs1_addr,
    input  logic [4:0]  id_ex_rs2_addr,
    input  logic [4:0]  id_ex_rd_addr,
    input  logic [31:0] id_ex_rs1_data,
    input  logic [31:0] id_ex_rs2_data,
    input  logic [31:0] id_ex_imm,
    input  logic [31:0] id_ex_pc,
    input  alu_op_t     id_ex_alu_op,
    input  logic        id_ex_alu_src,
    input  logic        id_ex_mem_read,
    input  logic        id_ex_mem_write,
    input  logic [2:0]  id_ex_mem_funct3,
    input  wb_src_t     id_ex_wb_src,
    input  logic        id_ex_reg_wen,
    input  logic        id_ex_is_branch,
    input  logic        id_ex_is_jal,
    input  logic        id_ex_is_jalr,
    input  logic [2:0]  id_ex_branch_funct3,
    input  logic        id_ex_is_csr,
    input  logic [11:0] id_ex_csr_addr,
    input  logic [2:0]  id_ex_csr_funct3,
    input  logic        id_ex_is_ecall,
    input  logic        id_ex_is_ebreak,
    input  logic        id_ex_illegal_instr,
    input  logic        id_ex_valid,

    //-------------------------------------------------------------------------
    // Forwarding inputs — from EX/MEM and MEM/WB pipeline registers
    // Spec: Patterson & Hennessy "Computer Organization and Design" Fig. 4.54
    //   but implementation anchored to hazard_unit.sv forwarding selects
    //-------------------------------------------------------------------------
    input  fwd_sel_t    fwd_a_sel,          // forwarding select for operand A (rs1)
    input  fwd_sel_t    fwd_b_sel,          // forwarding select for operand B (rs2)
    input  logic [31:0] ex_mem_alu_result,  // EX/MEM forwarding value
    input  logic [31:0] mem_wb_result,      // MEM/WB forwarding value

    //-------------------------------------------------------------------------
    // CSR register file interface
    //-------------------------------------------------------------------------
    output logic [11:0] csr_rd_addr,
    input  logic [31:0] csr_rd_data,
    output logic [11:0] csr_wr_addr,
    output logic [31:0] csr_wr_data,
    output logic        csr_wen,

    //-------------------------------------------------------------------------
    // Branch / jump outputs → IF stage next-PC mux
    //-------------------------------------------------------------------------
    output logic        branch_taken,       // 1 = branch condition true
    output logic [31:0] branch_target,      // PC + imm_b
    output logic [31:0] jalr_target,        // (rs1 + imm_i) & ~1

    //-------------------------------------------------------------------------
    // Exception output → hazard unit
    //-------------------------------------------------------------------------
    output logic        ex_exception,
    output logic [31:0] ex_cause,
    output logic [31:0] ex_mepc,

    //-------------------------------------------------------------------------
    // EX/MEM pipeline register outputs
    //-------------------------------------------------------------------------
    output logic [4:0]  ex_mem_rd_addr,
    output logic [31:0] ex_mem_alu_result_out,  // also fed back as ex_mem_alu_result
    output logic [31:0] ex_mem_rs2_data,        // forwarded rs2 data for stores
    output logic        ex_mem_mem_read,
    output logic        ex_mem_mem_write,
    output logic [2:0]  ex_mem_mem_funct3,
    output wb_src_t     ex_mem_wb_src,
    output logic        ex_mem_reg_wen,
    output logic [31:0] ex_mem_pc_plus4,
    output logic        ex_mem_valid
);

    //=========================================================================
    // Forwarded operands
    //=========================================================================
    logic [31:0] operand_a;     // rs1 after forwarding
    logic [31:0] operand_b_rs2; // rs2 after forwarding (pre-imm mux)
    logic [31:0] operand_b;     // final ALU operand B (rs2 or imm)

    //=========================================================================
    // TODO: Forwarding muxes for operand A (rs1)
    // Spec: Forwarding priority — EX/MEM result takes priority over MEM/WB
    //   when both are valid for the same register (hazard_unit ensures this)
    //=========================================================================
    always_comb begin
        case (fwd_a_sel)
            FWD_NONE:   operand_a = id_ex_rs1_data;
            FWD_EX_MEM: operand_a = ex_mem_alu_result;
            FWD_MEM_WB: operand_a = mem_wb_result;
            default:    operand_a = id_ex_rs1_data;
        endcase
    end

    //=========================================================================
    // TODO: Forwarding mux for operand B (rs2)
    //=========================================================================
    always_comb begin
        case (fwd_b_sel)
            FWD_NONE:   operand_b_rs2 = id_ex_rs2_data;
            FWD_EX_MEM: operand_b_rs2 = ex_mem_alu_result;
            FWD_MEM_WB: operand_b_rs2 = mem_wb_result;
            default:    operand_b_rs2 = id_ex_rs2_data;
        endcase
    end

    // ALU source mux: 0 = rs2, 1 = immediate
    assign operand_b = id_ex_alu_src ? id_ex_imm : operand_b_rs2;

    //=========================================================================
    // ALU instantiation
    //=========================================================================
    logic [31:0] alu_result;
    logic        alu_zero;  // for branch comparator cross-check

    alu u_alu (
        .alu_op     (id_ex_alu_op),
        .operand_a  (operand_a),
        .operand_b  (operand_b),
        .pc         (id_ex_pc),
        .result     (alu_result),
        .zero       (alu_zero)
    );

    //=========================================================================
    // MUL/DIV unit instantiation (M-extension)
    // Multi-cycle — mul_div_done signals completion
    //=========================================================================
    logic [31:0] mul_div_result;
    logic        mul_div_done;
    logic        is_mul_div;

    assign is_mul_div = (id_ex_alu_op inside {ALU_MUL, ALU_MULH, ALU_MULHSU,
                                               ALU_MULHU, ALU_DIV, ALU_DIVU,
                                               ALU_REM, ALU_REMU});

    mul_div_unit u_mul_div (
        .clk        (clk),
        .rst_n      (rst_n),
        .start      (is_mul_div & id_ex_valid),
        .alu_op     (id_ex_alu_op),
        .operand_a  (operand_a),
        .operand_b  (operand_b_rs2),
        .result     (mul_div_result),
        .done       (mul_div_done)
    );

    // Result mux: MUL/DIV overrides ALU result
    logic [31:0] ex_result;
    assign ex_result = is_mul_div ? mul_div_result : alu_result;

    //=========================================================================
    // TODO: Branch comparator
    // Spec: RV32I Section 2.5.2 — Conditional Branches
    // Computes branch_taken based on funct3 and operand_a/b
    //
    // BEQ:  branch_taken = (operand_a == operand_b_rs2)
    // BNE:  branch_taken = (operand_a != operand_b_rs2)
    // BLT:  branch_taken = ($signed(operand_a) < $signed(operand_b_rs2))
    // BGE:  branch_taken = ($signed(operand_a) >= $signed(operand_b_rs2))
    // BLTU: branch_taken = (operand_a < operand_b_rs2)
    // BGEU: branch_taken = (operand_a >= operand_b_rs2)
    //=========================================================================
    always_comb begin
        branch_taken = 1'b0;
        if (id_ex_is_branch && id_ex_valid) begin
            case (id_ex_branch_funct3)
                `F3_BEQ  : branch_taken = (operand_a == operand_b_rs2);
                `F3_BNE  : branch_taken = (operand_a != operand_b_rs2);
                `F3_BLT  : branch_taken = ($signed(operand_a) < $signed(operand_b_rs2));
                `F3_BGE  : branch_taken = ($signed(operand_a) >= $signed(operand_b_rs2));
                `F3_BLTU : branch_taken = (operand_a < operand_b_rs2);
                `F3_BGEU : branch_taken = (operand_a >= operand_b_rs2);
                default  : branch_taken = 1'b0;
            endcase
        end
    end

    //=========================================================================
    // Branch and jump target computation
    //=========================================================================
    // Branch target = PC + sign-extended B-imm (already computed in ID as imm)
    assign branch_target = id_ex_pc + id_ex_imm;
    // JALR target = (rs1 + imm_i) with bit[0] cleared per spec Section 2.5.1
    assign jalr_target   = (operand_a + id_ex_imm) & ~32'd1;

    //=========================================================================
    // TODO: CSR read/write path
    // Spec: Privileged Arch Section 2.2 — CSR Instructions
    //
    // CSRRW:  old CSR value → rd; rs1 → CSR
    // CSRRS:  old CSR value → rd; CSR |= rs1
    // CSRRC:  old CSR value → rd; CSR &= ~rs1
    // CSRRWI: old CSR value → rd; zimm → CSR
    // CSRRSI: old CSR value → rd; CSR |= zimm
    // CSRRCI: old CSR value → rd; CSR &= ~zimm
    //=========================================================================
    logic [31:0] csr_zimm;
    assign csr_zimm = {27'b0, id_ex_rs1_addr}; // zimm uses rs1 field as 5-bit immediate

    assign csr_rd_addr = id_ex_csr_addr;
    assign csr_wr_addr = id_ex_csr_addr;
    assign csr_wen     = id_ex_is_csr & id_ex_valid;

    always_comb begin
        csr_wr_data = 32'd0; // TODO
        // case (id_ex_csr_funct3)
        //     `F3_CSRRW  : csr_wr_data = operand_a;
        //     `F3_CSRRS  : csr_wr_data = csr_rd_data | operand_a;
        //     `F3_CSRRC  : csr_wr_data = csr_rd_data & ~operand_a;
        //     `F3_CSRRWI : csr_wr_data = csr_zimm;
        //     `F3_CSRRSI : csr_wr_data = csr_rd_data | csr_zimm;
        //     `F3_CSRRCI : csr_wr_data = csr_rd_data & ~csr_zimm;
        //     default    : csr_wr_data = 32'd0;
        // endcase
    end

    //=========================================================================
    // Exception detection
    //=========================================================================
    assign ex_exception = id_ex_valid & (id_ex_illegal_instr | id_ex_is_ecall | id_ex_is_ebreak);
    assign ex_cause     = id_ex_illegal_instr ? `CAUSE_ILLEGAL_INSTR :
                          id_ex_is_ecall      ? `CAUSE_ECALL_M       :
                                                `CAUSE_BREAKPOINT;
    assign ex_mepc      = id_ex_pc;

    //=========================================================================
    // PC+4 (link address for JAL/JALR)
    //=========================================================================
    logic [31:0] pc_plus4;
    assign pc_plus4 = id_ex_pc + 32'd4; // TODO: PC+2 for RVC

    //=========================================================================
    // TODO: EX/MEM pipeline register
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ex_mem_rd_addr          <= 5'd0;
            ex_mem_alu_result_out   <= 32'd0;
            ex_mem_rs2_data         <= 32'd0;
            ex_mem_mem_read         <= 1'b0;
            ex_mem_mem_write        <= 1'b0;
            ex_mem_mem_funct3       <= 3'd0;
            ex_mem_wb_src           <= WB_ALU;
            ex_mem_reg_wen          <= 1'b0;
            ex_mem_pc_plus4         <= 32'd0;
            ex_mem_valid            <= 1'b0;
        end else begin
            ex_mem_rd_addr          <= id_ex_rd_addr;
            ex_mem_alu_result_out   <= (id_ex_is_csr) ? csr_rd_data : ex_result;
            ex_mem_rs2_data         <= operand_b_rs2;  // forwarded rs2 for stores
            ex_mem_mem_read         <= id_ex_mem_read  & id_ex_valid;
            ex_mem_mem_write        <= id_ex_mem_write & id_ex_valid;
            ex_mem_mem_funct3       <= id_ex_mem_funct3;
            ex_mem_wb_src           <= id_ex_wb_src;
            ex_mem_reg_wen          <= id_ex_reg_wen   & id_ex_valid;
            ex_mem_pc_plus4         <= pc_plus4;
            ex_mem_valid            <= id_ex_valid & ~ex_exception;
        end
    end

endmodule
