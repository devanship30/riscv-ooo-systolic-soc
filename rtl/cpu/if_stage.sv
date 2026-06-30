//=============================================================================
// if_stage.sv — Instruction Fetch Stage
// Spec: RISC-V Unprivileged ISA v20191213, Chapter 1 (PC behavior)
//       AMBA AXI4-Lite Protocol Specification IHI0022E
//
// Responsibilities:
//   1. Drive Program Counter (PC) — reset to RESET_PC (0x80000000)
//   2. Issue AXI4-Lite read request to instruction SRAM
//   3. Detect RVC 16-bit instructions (bits[1:0] != 2'b11)
//   4. Compute next PC: PC+4 (32-bit), PC+2 (RVC), branch target, or trap vector
//   5. Stall if AXI read not yet returned (RVALID=0)
//   6. Output IF/ID pipeline register contents
//
// Hazard inputs (from hazard_unit.sv):
//   - stall_if  : hold PC and IF/ID register (load-use or memory stall)
//   - flush_if  : invalidate IF/ID register (branch taken or exception)
//   - pc_sel    : select next PC source
//   - branch_target / exception_target / jalr_target
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] AXI4-Lite read handshake
//            [ ] RVC detection logic
//            [ ] Stall/flush behavior
//            [ ] Next-PC mux
//=============================================================================

`include "rv32_defines.svh"
`include "axi4_defines.svh"

module if_stage (
    input  logic        clk,
    input  logic        rst_n,

    //-------------------------------------------------------------------------
    // Hazard unit control inputs
    //-------------------------------------------------------------------------
    input  logic        stall_if,           // 1 → freeze PC and IF/ID register
    input  logic        flush_if,           // 1 → insert NOP into IF/ID register
    input  logic [1:0]  pc_sel,             // next-PC source select
                                            // 2'b00 = PC+4 or PC+2 (sequential)
                                            // 2'b01 = branch_target
                                            // 2'b10 = jalr_target
                                            // 2'b11 = exception_target (mtvec)
    input  logic [31:0] branch_target,      // from EX stage branch comparator
    input  logic [31:0] jalr_target,        // from EX stage ALU (JALR)
    input  logic [31:0] exception_target,   // from CSR regfile (mtvec)

    //-------------------------------------------------------------------------
    // AXI4-Lite instruction fetch port (master — read-only)
    // Spec: IHI0022E Section B1 (AXI4-Lite)
    //-------------------------------------------------------------------------
    // Read address channel
    output logic [31:0] instr_araddr,
    output logic        instr_arvalid,
    input  logic        instr_arready,
    // Read data channel
    input  logic [31:0] instr_rdata,
    input  logic [1:0]  instr_rresp,
    input  logic        instr_rvalid,
    output logic        instr_rready,

    //-------------------------------------------------------------------------
    // IF/ID pipeline register outputs
    //-------------------------------------------------------------------------
    output logic [31:0] if_id_pc,           // PC of fetched instruction
    output logic [31:0] if_id_instr,        // fetched instruction (32-bit or expanded RVC)
    output logic        if_id_valid,        // 0 = bubble/NOP in this slot
    output logic        if_id_is_rvc        // 1 = this was a 16-bit compressed instruction
);

    //=========================================================================
    // Internal signals
    //=========================================================================
    logic [31:0] pc_reg;            // current program counter
    logic [31:0] pc_next;           // next PC value (before stall gating)
    logic        instr_is_rvc;      // 1 if fetched instruction is RVC
    logic        fetch_done;        // 1 when RVALID handshake completes
    logic [31:0] fetched_instr;     // raw instruction from memory

    //=========================================================================
    // TODO: PC register
    // - Reset to `RESET_PC (0x80000000)
    // - On stall_if: hold PC
    // - Otherwise: update to pc_next
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_reg <= `RESET_PC;
        end else if (!stall_if) begin
            // TODO: pc_reg <= pc_next;
            pc_reg <= pc_reg; // placeholder — replace with pc_next
        end
    end

    //=========================================================================
    // TODO: Next-PC mux
    // Priority (highest first):
    //   1. exception_target  (pc_sel == 2'b11) — trap vector
    //   2. jalr_target       (pc_sel == 2'b10) — JALR result
    //   3. branch_target     (pc_sel == 2'b01) — taken branch
    //   4. sequential        (pc_sel == 2'b00) — PC+4 or PC+2 for RVC
    //
    // NOTE: instr_is_rvc must be registered (from PREVIOUS fetch) to determine
    // whether *current* PC is a 16-bit instruction. Use if_id_is_rvc for this.
    //=========================================================================
    always_comb begin
        pc_next = pc_reg; // TODO: replace with mux logic
        // case (pc_sel)
        //     2'b00: pc_next = if_id_is_rvc ? pc_reg + 32'd2 : pc_reg + 32'd4;
        //     2'b01: pc_next = branch_target;
        //     2'b10: pc_next = jalr_target & ~32'd1; // clear bit[0] per spec
        //     2'b11: pc_next = exception_target;
        // endcase
    end

    //=========================================================================
    // TODO: AXI4-Lite read address channel
    // - Assert ARVALID when a new fetch is needed (not stalled, not waiting)
    // - Drive ARADDR = pc_reg
    // - Deassert ARVALID once ARREADY is seen (handshake complete)
    // Spec: IHI0022E Section A3.2 — VALID/READY handshake rules
    //   "Once ARVALID is asserted it must remain asserted until ARREADY is HIGH"
    //=========================================================================
    assign instr_araddr  = pc_reg;
    assign instr_arvalid = 1'b0;  // TODO: implement handshake FSM
    assign instr_rready  = 1'b1;  // always ready to accept read data (can simplify for AXI4-Lite)

    //=========================================================================
    // TODO: RVC detection
    // Spec: RISC-V Unprivileged ISA Chapter 16
    //   "All RVC instructions have bits[1:0] != 2'b11"
    // If RVC: instruction is 16-bit; instr_rdata[15:0] holds the instruction
    //         next fetch should be from PC+2
    //=========================================================================
    assign instr_is_rvc   = (instr_rdata[1:0] != `INSTR_WIDTH_32);
    assign fetch_done     = instr_rvalid & instr_rready;
    assign fetched_instr  = fetch_done ? instr_rdata : `NOP_INSTR;

    //=========================================================================
    // TODO: IF/ID pipeline register
    // - On flush_if: output NOP (ADDI x0, x0, 0 = 0x00000013), valid=0
    // - On stall_if: hold current values
    // - Otherwise:   latch fetched instruction and PC
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            if_id_pc      <= 32'h0;
            if_id_instr   <= `NOP_INSTR;
            if_id_valid   <= 1'b0;
            if_id_is_rvc  <= 1'b0;
        end else if (flush_if) begin
            if_id_pc      <= pc_reg;
            if_id_instr   <= `NOP_INSTR;
            if_id_valid   <= 1'b0;
            if_id_is_rvc  <= 1'b0;
        end else if (!stall_if) begin
            // TODO: fill in from fetch result
            // if_id_pc     <= pc_reg;
            // if_id_instr  <= fetched_instr; // or RVC-expanded
            // if_id_valid  <= fetch_done;
            // if_id_is_rvc <= instr_is_rvc;
        end
        // else: stall — hold all values
    end

endmodule
