//=============================================================================
// csr_regfile.sv — Machine-Mode CSR Register File
// Spec: RISC-V Privileged Architecture v20211203
//         Section 2.2 (CSR Instructions)
//         Section 3.1 (Machine-Mode CSRs)
//         Table 3.6   (mcause values)
//
// Implemented CSRs (machine mode only — no U/S mode, no virtual memory):
//   mstatus  (0x300) — MIE, MPIE bits (minimal implementation)
//   mtvec    (0x305) — trap vector base address + mode
//   mscratch (0x340) — scratch register
//   mepc     (0x341) — exception program counter
//   mcause   (0x342) — exception cause code
//   mtval    (0x343) — trap value (bad address for misalign)
//   mie      (0x304) — machine interrupt enable
//   mip      (0x344) — machine interrupt pending (read-only in this impl)
//   mhartid  (0xF14) — hardware thread ID (read-only, hardwired to 0)
//   misa     (0x301) — ISA and extensions (read-only)
//
// Trap handling:
//   On trap: mepc = PC, mcause = cause, mtval = bad_addr
//            mstatus.MPIE = mstatus.MIE; mstatus.MIE = 0
//   On MRET: PC = mepc; mstatus.MIE = mstatus.MPIE; mstatus.MPIE = 1
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] Trap entry logic (mstatus update)
//            [ ] MRET handling
//            [ ] mtvec mode (Direct vs Vectored)
//=============================================================================

`include "rv32_defines.svh"

module csr_regfile (
    input  logic        clk,
    input  logic        rst_n,

    //-------------------------------------------------------------------------
    // CSR read/write from EX stage (CSRRW, CSRRS, etc.)
    //-------------------------------------------------------------------------
    input  logic [11:0] rd_addr,
    output logic [31:0] rd_data,
    input  logic [11:0] wr_addr,
    input  logic [31:0] wr_data,
    input  logic        wen,

    //-------------------------------------------------------------------------
    // Trap entry (from hazard unit / exception logic)
    //-------------------------------------------------------------------------
    input  logic        trap_en,        // 1 = take trap this cycle
    input  logic [31:0] trap_pc,        // mepc ← instruction PC
    input  logic [31:0] trap_cause,     // mcause ← cause code
    input  logic [31:0] trap_val,       // mtval ← bad address

    //-------------------------------------------------------------------------
    // MRET (return from trap) — issued by decode when MRET instruction seen
    //-------------------------------------------------------------------------
    input  logic        mret_en,

    //-------------------------------------------------------------------------
    // CSR output ports (used by other pipeline stages)
    //-------------------------------------------------------------------------
    output logic [31:0] mtvec_out,      // trap vector → IF stage (exception target)
    output logic [31:0] mepc_out        // return address for MRET
);

    //=========================================================================
    // CSR storage
    //=========================================================================
    logic [31:0] mstatus;
    logic [31:0] mtvec;
    logic [31:0] mscratch;
    logic [31:0] mepc;
    logic [31:0] mcause;
    logic [31:0] mtval;
    logic [31:0] mie;
    logic [31:0] mip;

    // Read-only CSRs
    // misa: RV32IMC encoding
    // MXL=01 (32-bit), extensions: I(8), M(12), C(2) → bit 8, 12, 2 set
    localparam logic [31:0] MISA_VAL = {2'b01, 4'b0, 26'h0001104};
    localparam logic [31:0] MHARTID_VAL = 32'd0;

    //=========================================================================
    // CSR output connections
    //=========================================================================
    assign mtvec_out = mtvec;
    assign mepc_out  = mepc;

    //=========================================================================
    // TODO: CSR write logic
    // Priority: trap_en > wen (trap entry overrides normal CSR write)
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mstatus  <= 32'h0000_0000; // MIE=0 at reset (interrupts disabled)
            mtvec    <= 32'h0000_0000; // must be programmed by firmware
            mscratch <= 32'h0000_0000;
            mepc     <= 32'h0000_0000;
            mcause   <= 32'h0000_0000;
            mtval    <= 32'h0000_0000;
            mie      <= 32'h0000_0000;
            mip      <= 32'h0000_0000;
        end else if (trap_en) begin
            // Trap entry: save state, disable interrupts
            // Spec: Privileged Arch Section 3.1.6.1
            //   mstatus.MPIE = mstatus.MIE
            //   mstatus.MIE  = 0
            mepc     <= trap_pc;
            mcause   <= trap_cause;
            mtval    <= trap_val;
            mstatus  <= {mstatus[31:8], mstatus[3], 3'b0, 1'b0, mstatus[2:0]};
            // TODO: set MPIE = old MIE, clear MIE
        end else if (mret_en) begin
            // MRET: restore MIE from MPIE, set MPIE = 1
            // Spec: Privileged Arch Section 3.3.2
            mstatus <= {mstatus[31:8], 1'b1, 3'b0, mstatus[7], mstatus[2:0]};
            // TODO: set MIE = MPIE, set MPIE = 1
        end else if (wen) begin
            // Normal CSR write from CSRRW/CSRRS/CSRRC instructions
            case (wr_addr)
                `CSR_MSTATUS : mstatus  <= wr_data;
                `CSR_MTVEC   : mtvec    <= wr_data;
                `CSR_MSCRATCH: mscratch <= wr_data;
                `CSR_MEPC    : mepc     <= wr_data;
                `CSR_MCAUSE  : mcause   <= wr_data;
                `CSR_MTVAL   : mtval    <= wr_data;
                `CSR_MIE     : mie      <= wr_data;
                // Read-only CSRs: mip, misa, mhartid — ignore writes
                default: ; // illegal CSR address — TODO: raise illegal instruction
            endcase
        end
    end

    //=========================================================================
    // CSR read (combinational)
    //=========================================================================
    always_comb begin
        rd_data = 32'd0;
        case (rd_addr)
            `CSR_MSTATUS : rd_data = mstatus;
            `CSR_MISA    : rd_data = MISA_VAL;
            `CSR_MIE     : rd_data = mie;
            `CSR_MTVEC   : rd_data = mtvec;
            `CSR_MSCRATCH: rd_data = mscratch;
            `CSR_MEPC    : rd_data = mepc;
            `CSR_MCAUSE  : rd_data = mcause;
            `CSR_MTVAL   : rd_data = mtval;
            `CSR_MIP     : rd_data = mip;
            `CSR_MHARTID : rd_data = MHARTID_VAL;
            default      : rd_data = 32'd0; // illegal CSR read returns 0
        endcase
    end

endmodule
