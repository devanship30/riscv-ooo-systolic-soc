//=============================================================================
// id_stage.sv — Instruction Decode Stage
// Spec: RISC-V Unprivileged ISA v20191213
//         Chapter 2  (RV32I base — all 40 instructions)
//         Chapter 7  (M-extension — MUL/DIV)
//         Chapter 16 (C-extension — compressed instructions)
//
// Responsibilities:
//   1. Decode opcode → control signals for EX/MEM/WB stages
//   2. Read register file (two read ports)
//   3. Generate sign-extended immediates for all 6 formats
//   4. Expand RVC instructions to 32-bit equivalent
//   5. Pass decoded signals into ID/EX pipeline register
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] Full opcode decode table
//            [ ] All 6 immediate formats
//            [ ] RVC expansion (key subset)
//            [ ] ID/EX register with stall/flush
//=============================================================================

`include "rv32_defines.svh"

module id_stage (
    input  logic        clk,
    input  logic        rst_n,

    //-------------------------------------------------------------------------
    // IF/ID pipeline register inputs
    //-------------------------------------------------------------------------
    input  logic [31:0] if_id_pc,
    input  logic [31:0] if_id_instr,
    input  logic        if_id_valid,
    input  logic        if_id_is_rvc,

    //-------------------------------------------------------------------------
    // Hazard unit control inputs
    //-------------------------------------------------------------------------
    input  logic        stall_id,           // freeze ID/EX register
    input  logic        flush_id,           // insert NOP bubble

    //-------------------------------------------------------------------------
    // Register file write port (from WB stage)
    //-------------------------------------------------------------------------
    input  logic [4:0]  wb_rd_addr,
    input  logic [31:0] wb_rd_data,
    input  logic        wb_reg_wen,

    //-------------------------------------------------------------------------
    // ID/EX pipeline register outputs — control signals
    //-------------------------------------------------------------------------
    // Register addresses (needed by hazard unit and forwarding)
    output logic [4:0]  id_ex_rs1_addr,
    output logic [4:0]  id_ex_rs2_addr,
    output logic [4:0]  id_ex_rd_addr,
    // Register file read data
    output logic [31:0] id_ex_rs1_data,
    output logic [31:0] id_ex_rs2_data,
    // Decoded immediate
    output logic [31:0] id_ex_imm,
    // PC of this instruction
    output logic [31:0] id_ex_pc,
    // ALU control
    output alu_op_t     id_ex_alu_op,
    output logic        id_ex_alu_src,      // 0 = rs2, 1 = immediate
    // Memory control
    output logic        id_ex_mem_read,     // 1 = load instruction
    output logic        id_ex_mem_write,    // 1 = store instruction
    output logic [2:0]  id_ex_mem_funct3,   // LB/LH/LW/LBU/LHU, SB/SH/SW
    // Writeback control
    output wb_src_t     id_ex_wb_src,       // ALU / MEM / PC+4
    output logic        id_ex_reg_wen,      // 1 = write result to rd
    // Branch/jump control
    output logic        id_ex_is_branch,
    output logic        id_ex_is_jal,
    output logic        id_ex_is_jalr,
    output logic [2:0]  id_ex_branch_funct3, // BEQ/BNE/BLT/BGE/BLTU/BGEU
    // CSR control
    output logic        id_ex_is_csr,
    output logic [11:0] id_ex_csr_addr,
    output logic [2:0]  id_ex_csr_funct3,
    // Exception flags
    output logic        id_ex_is_ecall,
    output logic        id_ex_is_ebreak,
    output logic        id_ex_illegal_instr,
    // Valid bit (0 = bubble)
    output logic        id_ex_valid
);

    //=========================================================================
    // Internal decode signals (combinational)
    //=========================================================================
    logic [31:0] instr;         // instruction to decode (after RVC expansion)
    logic [6:0]  opcode;
    logic [4:0]  rs1, rs2, rd;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] imm_i, imm_s, imm_b, imm_u, imm_j;

    // Decoded control signals (combinational, registered into ID/EX)
    alu_op_t     dec_alu_op;
    logic        dec_alu_src;
    logic        dec_mem_read;
    logic        dec_mem_write;
    wb_src_t     dec_wb_src;
    logic        dec_reg_wen;
    logic        dec_is_branch;
    logic        dec_is_jal;
    logic        dec_is_jalr;
    logic        dec_is_csr;
    logic        dec_is_ecall;
    logic        dec_is_ebreak;
    logic        dec_illegal;

    // Register file outputs
    logic [31:0] rf_rs1_data;
    logic [31:0] rf_rs2_data;

    //=========================================================================
    // Register file instantiation
    //=========================================================================
    reg_file u_reg_file (
        .clk        (clk),
        .rst_n      (rst_n),
        // Read ports
        .rs1_addr   (rs1),
        .rs2_addr   (rs2),
        .rs1_data   (rf_rs1_data),
        .rs2_data   (rf_rs2_data),
        // Write port (from WB stage)
        .rd_addr    (wb_rd_addr),
        .rd_data    (wb_rd_data),
        .wen        (wb_reg_wen)
    );

    //=========================================================================
    // TODO: RVC instruction expansion
    // If if_id_is_rvc, expand 16-bit instruction to 32-bit equivalent
    // Key instructions to support (project spec subset):
    //   C.ADD   → ADD
    //   C.LW    → LW  (with stack-pointer or register-based offset)
    //   C.SW    → SW
    //   C.J     → JAL x0, offset
    //   C.BEQZ  → BEQ rs1', x0, offset
    //   C.BNEZ  → BNE rs1', x0, offset
    //   C.LI    → ADDI rd, x0, imm
    //   C.MV    → ADD rd, x0, rs2
    // Spec: RISC-V Unprivileged ISA Chapter 16, Table 16.1 – 16.6
    //=========================================================================
    always_comb begin
        if (if_id_is_rvc && if_id_valid) begin
            instr = 32'h0000_0013; // TODO: expand RVC — placeholder NOP
        end else begin
            instr = if_id_instr;
        end
    end

    //=========================================================================
    // Instruction field extraction (standard 32-bit encoding)
    //=========================================================================
    assign opcode = instr[6:0];
    assign rd     = instr[11:7];
    assign funct3 = instr[14:12];
    assign rs1    = instr[19:15];
    assign rs2    = instr[24:20];
    assign funct7 = instr[31:25];

    //=========================================================================
    // TODO: Immediate generator — all 6 formats
    // Spec: RISC-V Unprivileged ISA v20191213, Section 2.3 (Immediate Encoding)
    //
    // I-type: instr[31:20]                                  sign-extended to 32b
    // S-type: {instr[31:25], instr[11:7]}                  sign-extended
    // B-type: {instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}
    // U-type: {instr[31:12], 12'b0}                        (no sign ext needed)
    // J-type: {instr[31], instr[19:12], instr[20], instr[30:21], 1'b0}
    //=========================================================================
    assign imm_i = {{20{instr[31]}}, instr[31:20]};
    assign imm_s = {{20{instr[31]}}, instr[31:25], instr[11:7]};
    assign imm_b = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
    assign imm_u = {instr[31:12], 12'b0};
    assign imm_j = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};

    //=========================================================================
    // TODO: Main decode logic
    // Map opcode/funct3/funct7 → control signals
    // Use the opcode constants from rv32_defines.svh
    //=========================================================================
    always_comb begin
        // Default / safe values — prevent latches
        dec_alu_op      = ALU_NOP;
        dec_alu_src     = 1'b0;     // use rs2
        dec_mem_read    = 1'b0;
        dec_mem_write   = 1'b0;
        dec_wb_src      = WB_ALU;
        dec_reg_wen     = 1'b0;
        dec_is_branch   = 1'b0;
        dec_is_jal      = 1'b0;
        dec_is_jalr     = 1'b0;
        dec_is_csr      = 1'b0;
        dec_is_ecall    = 1'b0;
        dec_is_ebreak   = 1'b0;
        dec_illegal     = 1'b0;

        case (opcode)
            //------------------------------------------------------------------
            // LUI — Load Upper Immediate
            // rd = imm_u
            //------------------------------------------------------------------
            `OPC_LUI: begin
                // TODO:
                // dec_alu_op  = ALU_LUI;
                // dec_alu_src = 1'b1;
                // dec_reg_wen = 1'b1;
                // dec_wb_src  = WB_ALU;
            end

            //------------------------------------------------------------------
            // AUIPC — Add Upper Immediate to PC
            // rd = PC + imm_u
            //------------------------------------------------------------------
            `OPC_AUIPC: begin
                // TODO:
                // dec_alu_op  = ALU_AUIPC;
                // dec_alu_src = 1'b1;
                // dec_reg_wen = 1'b1;
            end

            //------------------------------------------------------------------
            // JAL — Jump and Link
            // rd = PC+4; PC = PC + imm_j
            //------------------------------------------------------------------
            `OPC_JAL: begin
                // TODO:
                // dec_is_jal  = 1'b1;
                // dec_reg_wen = 1'b1;
                // dec_wb_src  = WB_PC4;
            end

            //------------------------------------------------------------------
            // JALR — Jump and Link Register
            // rd = PC+4; PC = (rs1 + imm_i) & ~1
            //------------------------------------------------------------------
            `OPC_JALR: begin
                // TODO:
                // dec_is_jalr = 1'b1;
                // dec_alu_op  = ALU_ADD;
                // dec_alu_src = 1'b1;
                // dec_reg_wen = 1'b1;
                // dec_wb_src  = WB_PC4;
            end

            //------------------------------------------------------------------
            // BRANCH — BEQ, BNE, BLT, BGE, BLTU, BGEU
            //------------------------------------------------------------------
            `OPC_BRANCH: begin
                // TODO:
                // dec_is_branch = 1'b1;
                // // branch target = PC + imm_b (computed in EX stage)
                // // branch condition checked by branch comparator in EX
            end

            //------------------------------------------------------------------
            // LOAD — LB, LH, LW, LBU, LHU
            //------------------------------------------------------------------
            `OPC_LOAD: begin
                // TODO:
                // dec_alu_op   = ALU_ADD;   // address = rs1 + imm_i
                // dec_alu_src  = 1'b1;
                // dec_mem_read = 1'b1;
                // dec_reg_wen  = 1'b1;
                // dec_wb_src   = WB_MEM;
            end

            //------------------------------------------------------------------
            // STORE — SB, SH, SW
            //------------------------------------------------------------------
            `OPC_STORE: begin
                // TODO:
                // dec_alu_op   = ALU_ADD;   // address = rs1 + imm_s
                // dec_alu_src  = 1'b1;
                // dec_mem_write = 1'b1;
            end

            //------------------------------------------------------------------
            // OP-IMM — ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
            //------------------------------------------------------------------
            `OPC_OP_IMM: begin
                // TODO: decode funct3 to select ALU op
                // dec_alu_src = 1'b1;
                // dec_reg_wen = 1'b1;
                // case (funct3)
                //     `F3_ADDI:      dec_alu_op = ALU_ADD;
                //     `F3_SLTI:      dec_alu_op = ALU_SLT;
                //     `F3_SLTIU:     dec_alu_op = ALU_SLTU;
                //     `F3_XORI:      dec_alu_op = ALU_XOR;
                //     `F3_ORI:       dec_alu_op = ALU_OR;
                //     `F3_ANDI:      dec_alu_op = ALU_AND;
                //     `F3_SLLI:      dec_alu_op = ALU_SLL;
                //     `F3_SRLI_SRAI: dec_alu_op = funct7[5] ? ALU_SRA : ALU_SRL;
                //     default:       dec_illegal = 1'b1;
                // endcase
            end

            //------------------------------------------------------------------
            // OP — ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
            //      + M-extension: MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU
            //------------------------------------------------------------------
            `OPC_OP: begin
                // TODO:
                // dec_reg_wen = 1'b1;
                // if (funct7 == `F7_MEXT) begin
                //     // M-extension
                //     case (funct3)
                //         `F3_MUL:    dec_alu_op = ALU_MUL;
                //         `F3_MULH:   dec_alu_op = ALU_MULH;
                //         `F3_MULHSU: dec_alu_op = ALU_MULHSU;
                //         `F3_MULHU:  dec_alu_op = ALU_MULHU;
                //         `F3_DIV:    dec_alu_op = ALU_DIV;
                //         `F3_DIVU:   dec_alu_op = ALU_DIVU;
                //         `F3_REM:    dec_alu_op = ALU_REM;
                //         `F3_REMU:   dec_alu_op = ALU_REMU;
                //         default:    dec_illegal = 1'b1;
                //     endcase
                // end else begin
                //     // Base RV32I
                //     case ({funct7[5], funct3})
                //         {1'b0, `F3_ADD_SUB}: dec_alu_op = ALU_ADD;
                //         {1'b1, `F3_ADD_SUB}: dec_alu_op = ALU_SUB;
                //         ...
                //     endcase
                // end
            end

            //------------------------------------------------------------------
            // SYSTEM — ECALL, EBREAK, CSR*
            //------------------------------------------------------------------
            `OPC_SYSTEM: begin
                // TODO:
                // case (funct3)
                //     `F3_ECALL_EBREAK: begin
                //         dec_is_ecall  = (instr[20] == 1'b0);
                //         dec_is_ebreak = (instr[20] == 1'b1);
                //     end
                //     `F3_CSRRW, `F3_CSRRS, `F3_CSRRC,
                //     `F3_CSRRWI,`F3_CSRRSI,`F3_CSRRCI: begin
                //         dec_is_csr  = 1'b1;
                //         dec_reg_wen = 1'b1;
                //     end
                //     default: dec_illegal = 1'b1;
                // endcase
            end

            //------------------------------------------------------------------
            // MISC-MEM — FENCE (treat as NOP for this SoC)
            //------------------------------------------------------------------
            `OPC_MISC_MEM: begin
                // FENCE → NOP in simple in-order CPU
            end

            default: begin
                dec_illegal = 1'b1;
            end
        endcase
    end

    //=========================================================================
    // Immediate selection mux — choose based on opcode
    //=========================================================================
    logic [31:0] dec_imm;
    always_comb begin
        case (opcode)
            `OPC_OP_IMM, `OPC_LOAD, `OPC_JALR : dec_imm = imm_i;
            `OPC_STORE                          : dec_imm = imm_s;
            `OPC_BRANCH                         : dec_imm = imm_b;
            `OPC_LUI, `OPC_AUIPC               : dec_imm = imm_u;
            `OPC_JAL                            : dec_imm = imm_j;
            default                             : dec_imm = imm_i;
        endcase
    end

    //=========================================================================
    // TODO: ID/EX pipeline register
    // - flush_id → all control signals deasserted, valid=0
    // - stall_id → hold all values
    // - otherwise → latch decoded values
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush_id) begin
            id_ex_rs1_addr      <= 5'd0;
            id_ex_rs2_addr      <= 5'd0;
            id_ex_rd_addr       <= 5'd0;
            id_ex_rs1_data      <= 32'd0;
            id_ex_rs2_data      <= 32'd0;
            id_ex_imm           <= 32'd0;
            id_ex_pc            <= 32'd0;
            id_ex_alu_op        <= ALU_NOP;
            id_ex_alu_src       <= 1'b0;
            id_ex_mem_read      <= 1'b0;
            id_ex_mem_write     <= 1'b0;
            id_ex_mem_funct3    <= 3'd0;
            id_ex_wb_src        <= WB_ALU;
            id_ex_reg_wen       <= 1'b0;
            id_ex_is_branch     <= 1'b0;
            id_ex_is_jal        <= 1'b0;
            id_ex_is_jalr       <= 1'b0;
            id_ex_branch_funct3 <= 3'd0;
            id_ex_is_csr        <= 1'b0;
            id_ex_csr_addr      <= 12'd0;
            id_ex_csr_funct3    <= 3'd0;
            id_ex_is_ecall      <= 1'b0;
            id_ex_is_ebreak     <= 1'b0;
            id_ex_illegal_instr <= 1'b0;
            id_ex_valid         <= 1'b0;
        end else if (!stall_id) begin
            // TODO: latch decoded signals from combinational logic above
            id_ex_rs1_addr      <= rs1;
            id_ex_rs2_addr      <= rs2;
            id_ex_rd_addr       <= rd;
            id_ex_rs1_data      <= rf_rs1_data;
            id_ex_rs2_data      <= rf_rs2_data;
            id_ex_imm           <= dec_imm;
            id_ex_pc            <= if_id_pc;
            id_ex_alu_op        <= dec_alu_op;
            id_ex_alu_src       <= dec_alu_src;
            id_ex_mem_read      <= dec_mem_read;
            id_ex_mem_write     <= dec_mem_write;
            id_ex_mem_funct3    <= funct3;
            id_ex_wb_src        <= dec_wb_src;
            id_ex_reg_wen       <= dec_reg_wen & if_id_valid;
            id_ex_is_branch     <= dec_is_branch;
            id_ex_is_jal        <= dec_is_jal;
            id_ex_is_jalr       <= dec_is_jalr;
            id_ex_branch_funct3 <= funct3;
            id_ex_is_csr        <= dec_is_csr;
            id_ex_csr_addr      <= instr[31:20];
            id_ex_csr_funct3    <= funct3;
            id_ex_is_ecall      <= dec_is_ecall;
            id_ex_is_ebreak     <= dec_is_ebreak;
            id_ex_illegal_instr <= dec_illegal;
            id_ex_valid         <= if_id_valid;
        end
        // else stall → hold
    end

endmodule
