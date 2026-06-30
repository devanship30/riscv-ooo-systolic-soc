//=============================================================================
// hazard_unit.sv — Pipeline Hazard Detection and Control
//
// Handles all 5 hazard types in the RV32IMC 5-stage pipeline:
//   1. EX→EX RAW forwarding  (consecutive ALU instructions)
//   2. MEM→EX RAW forwarding (2nd instruction after producer)
//   3. Load-use stall        (LOAD followed immediately by dependent instr)
//   4. Branch flush          (2-cycle flush on taken branch)
//   5. Exception flush       (full pipeline flush on trap)
//
// Forwarding priority rule (SVA: forward_path_priority):
//   EX/MEM forwarding takes priority over MEM/WB forwarding when both
//   registers match. This handles the case: A→B→C (B's result in EX/MEM,
//   A's result in MEM/WB — we want B's value for C).
//
// Spec references:
//   RISC-V Unprivileged ISA v20191213, Section 2.2 — x0 is always 0
//   (never forward to/from x0 register)
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] Load-use stall condition
//            [ ] Branch flush condition
//            [ ] Exception flush condition
//            [ ] Forwarding select logic
//=============================================================================

`include "rv32_defines.svh"

module hazard_unit (
    //-------------------------------------------------------------------------
    // Pipeline register fields needed for hazard detection
    //-------------------------------------------------------------------------
    // ID stage current instruction sources
    input  logic [4:0]  id_ex_rs1_addr,     // rs1 of instruction in EX
    input  logic [4:0]  id_ex_rs2_addr,     // rs2 of instruction in EX
    // EX/MEM register (instruction just leaving EX)
    input  logic [4:0]  ex_mem_rd_addr,     // rd of instruction in MEM
    input  logic        ex_mem_reg_wen,     // does MEM-stage instruction write rd?
    input  logic        ex_mem_mem_read,    // is MEM-stage instruction a LOAD?
    // MEM/WB register (instruction just leaving MEM)
    input  logic [4:0]  mem_wb_rd_addr,     // rd of instruction in WB
    input  logic        mem_wb_reg_wen,     // does WB-stage instruction write rd?
    // ID/EX register source addresses (for load-use detection)
    input  logic [4:0]  if_id_rs1_addr,    // rs1 of instruction currently in ID
    input  logic [4:0]  if_id_rs2_addr,    // rs2 of instruction currently in ID
    input  logic        ex_mem_valid,
    input  logic        mem_wb_valid,
    // Branch/exception signals from EX stage
    input  logic        branch_taken,       // from EX branch comparator
    input  logic        ex_exception,       // from EX exception detector
    input  logic        mem_exception,      // from MEM misalignment detector
    // Memory stall from MEM stage
    input  logic        mem_stall,          // AXI transaction pending

    //-------------------------------------------------------------------------
    // Pipeline control outputs (stall and flush signals)
    //-------------------------------------------------------------------------
    output logic        stall_if,           // freeze IF stage
    output logic        stall_id,           // freeze ID stage
    output logic        flush_if,           // insert NOP into IF/ID
    output logic        flush_id,           // insert NOP into ID/EX
    output logic        flush_ex,           // insert NOP into EX/MEM (exception)
    output logic [1:0]  pc_sel,             // next-PC source for IF stage

    //-------------------------------------------------------------------------
    // Forwarding select outputs to EX stage
    //-------------------------------------------------------------------------
    output fwd_sel_t    fwd_a_sel,          // forwarding for rs1 (operand A)
    output fwd_sel_t    fwd_b_sel           // forwarding for rs2 (operand B)
);

    //=========================================================================
    // Internal signals
    //=========================================================================
    logic load_use_hazard;
    logic ex_ex_fwd_a, ex_ex_fwd_b;
    logic mem_ex_fwd_a, mem_ex_fwd_b;

    //=========================================================================
    // TODO: EX→EX forwarding detection
    // Condition: instruction in EX needs a result just written by instruction in MEM
    //
    //   fwd_a from EX/MEM if:
    //     ex_mem_reg_wen == 1
    //     AND ex_mem_rd_addr != 0       (x0 never forwarded — always 0)
    //     AND ex_mem_rd_addr == id_ex_rs1_addr
    //     AND ex_mem_valid
    //
    //   Same for fwd_b (rs2)
    //
    // SVA reference: forward_path_priority — EX/MEM wins over MEM/WB
    //=========================================================================
    assign ex_ex_fwd_a = ex_mem_reg_wen
                       & (ex_mem_rd_addr != 5'd0)
                       & (ex_mem_rd_addr == id_ex_rs1_addr)
                       & ex_mem_valid;

    assign ex_ex_fwd_b = ex_mem_reg_wen
                       & (ex_mem_rd_addr != 5'd0)
                       & (ex_mem_rd_addr == id_ex_rs2_addr)
                       & ex_mem_valid;

    //=========================================================================
    // TODO: MEM→EX forwarding detection
    // Condition: instruction in EX needs a result written 2 cycles ago (now in WB)
    // Must NOT override EX→EX forwarding (EX/MEM takes priority for same reg)
    //=========================================================================
    assign mem_ex_fwd_a = mem_wb_reg_wen
                        & (mem_wb_rd_addr != 5'd0)
                        & (mem_wb_rd_addr == id_ex_rs1_addr)
                        & ~ex_ex_fwd_a     // EX/MEM takes priority
                        & mem_wb_valid;

    assign mem_ex_fwd_b = mem_wb_reg_wen
                        & (mem_wb_rd_addr != 5'd0)
                        & (mem_wb_rd_addr == id_ex_rs2_addr)
                        & ~ex_ex_fwd_b
                        & mem_wb_valid;

    //=========================================================================
    // Forwarding mux selects
    //=========================================================================
    always_comb begin
        fwd_a_sel = FWD_NONE;
        if      (ex_ex_fwd_a)  fwd_a_sel = FWD_EX_MEM;
        else if (mem_ex_fwd_a) fwd_a_sel = FWD_MEM_WB;
    end

    always_comb begin
        fwd_b_sel = FWD_NONE;
        if      (ex_ex_fwd_b)  fwd_b_sel = FWD_EX_MEM;
        else if (mem_ex_fwd_b) fwd_b_sel = FWD_MEM_WB;
    end

    //=========================================================================
    // TODO: Load-use hazard detection
    // Condition: instruction in EX is a LOAD, and the immediately following
    //            instruction in ID reads the same register.
    //
    //   load_use_hazard if:
    //     ex_mem_mem_read == 1
    //     AND ex_mem_rd_addr != 0
    //     AND (ex_mem_rd_addr == if_id_rs1_addr OR ex_mem_rd_addr == if_id_rs2_addr)
    //
    // Action: stall IF and ID for 1 cycle; insert 1 bubble into EX
    // SVA reference: load_use_stall — exactly 1 bubble inserted
    //=========================================================================
    assign load_use_hazard = ex_mem_mem_read
                           & (ex_mem_rd_addr != 5'd0)
                           & ((ex_mem_rd_addr == if_id_rs1_addr) |
                              (ex_mem_rd_addr == if_id_rs2_addr));

    //=========================================================================
    // TODO: Stall and flush control
    // Priority (highest first):
    //   1. Exception (flush entire pipeline, redirect to mtvec)
    //   2. Branch taken (flush IF and ID)
    //   3. Load-use hazard (stall IF and ID, flush EX)
    //   4. Memory stall (stall IF, ID, EX — wait for AXI)
    //
    // SVA reference: stall_propagation — if MEM stalls, IF and ID also stall
    //=========================================================================
    always_comb begin
        // Default: no stalls or flushes
        stall_if = 1'b0;
        stall_id = 1'b0;
        flush_if = 1'b0;
        flush_id = 1'b0;
        flush_ex = 1'b0;
        pc_sel   = 2'b00;

        if (ex_exception | mem_exception) begin
            // Exception: flush everything, redirect to mtvec
            flush_if = 1'b1;
            flush_id = 1'b1;
            flush_ex = 1'b1;
            pc_sel   = 2'b11;
        end else if (branch_taken) begin
            // TODO: Branch taken — flush IF and ID (2-cycle penalty)
            // SVA reference: no_instr_lost_on_flush — both IF and ID output NOP
            flush_if = 1'b1;
            flush_id = 1'b1;
            pc_sel   = 2'b01; // branch_target
        end else if (load_use_hazard) begin
            // TODO: Load-use — stall IF+ID, flush EX (insert 1 bubble)
            stall_if = 1'b1;
            stall_id = 1'b1;
            flush_id = 1'b1; // insert NOP/bubble into ID/EX
        end else if (mem_stall) begin
            // TODO: AXI stall — freeze everything up to MEM
            stall_if = 1'b1;
            stall_id = 1'b1;
        end
    end

endmodule
