//=============================================================================
// rv32_defines.svh — RV32IMC opcode, funct3, funct7, CSR definitions
// Spec: RISC-V Unprivileged ISA v20191213, Table 24.1 + Chapter 19 (RVC)
//       RISC-V Privileged Architecture v20211203, Chapter 2 (CSRs)
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

`ifndef RV32_DEFINES_SVH
`define RV32_DEFINES_SVH

//-----------------------------------------------------------------------------
// Instruction width markers
//-----------------------------------------------------------------------------
`define INSTR_WIDTH_32  2'b11   // bits[1:0] == 11 → 32-bit instruction
`define INSTR_WIDTH_16  2'b00   // bits[1:0] != 11 → RVC 16-bit instruction
// (also 2'b01 and 2'b10 are 16-bit encodings per RVC spec)

//-----------------------------------------------------------------------------
// RV32I Base Opcodes (bits[6:0]) — Table 24.1 RISC-V Unprivileged ISA
//-----------------------------------------------------------------------------
`define OPC_LOAD        7'b000_0011   // LB LH LW LBU LHU
`define OPC_STORE       7'b010_0011   // SB SH SW
`define OPC_MADD        7'b100_0011   // (F-ext, not used)
`define OPC_BRANCH      7'b110_0011   // BEQ BNE BLT BGE BLTU BGEU
`define OPC_LOAD_FP     7'b000_0111   // (F-ext, not used)
`define OPC_STORE_FP    7'b010_0111   // (F-ext, not used)
`define OPC_CUSTOM_0    7'b000_1011   // custom-0
`define OPC_MISC_MEM    7'b000_1111   // FENCE FENCE.I
`define OPC_OP_IMM      7'b001_0011   // ADDI SLTI SLTIU XORI ORI ANDI SLLI SRLI SRAI
`define OPC_OP_IMM_32   7'b001_1011   // (RV64 only)
`define OPC_AUIPC       7'b001_0111   // AUIPC
`define OPC_OP          7'b011_0011   // ADD SUB SLL SLT SLTU XOR SRL SRA OR AND + M-ext
`define OPC_OP_32       7'b011_1011   // (RV64 only)
`define OPC_LUI         7'b011_0111   // LUI
`define OPC_JALR        7'b110_0111   // JALR
`define OPC_JAL         7'b110_1111   // JAL
`define OPC_SYSTEM      7'b111_0011   // ECALL EBREAK CSRRW CSRRS CSRRC CSRRWI CSRRSI CSRRCI

//-----------------------------------------------------------------------------
// funct3 — LOAD instructions
//-----------------------------------------------------------------------------
`define F3_LB           3'b000
`define F3_LH           3'b001
`define F3_LW           3'b010
`define F3_LBU          3'b100
`define F3_LHU          3'b101

//-----------------------------------------------------------------------------
// funct3 — STORE instructions
//-----------------------------------------------------------------------------
`define F3_SB           3'b000
`define F3_SH           3'b001
`define F3_SW           3'b010

//-----------------------------------------------------------------------------
// funct3 — BRANCH instructions
//-----------------------------------------------------------------------------
`define F3_BEQ          3'b000
`define F3_BNE          3'b001
`define F3_BLT          3'b100
`define F3_BGE          3'b101
`define F3_BLTU         3'b110
`define F3_BGEU         3'b111

//-----------------------------------------------------------------------------
// funct3 — OP-IMM instructions
//-----------------------------------------------------------------------------
`define F3_ADDI         3'b000
`define F3_SLTI         3'b010
`define F3_SLTIU        3'b011
`define F3_XORI         3'b100
`define F3_ORI          3'b110
`define F3_ANDI         3'b111
`define F3_SLLI         3'b001
`define F3_SRLI_SRAI    3'b101   // disambiguated by funct7[5]

//-----------------------------------------------------------------------------
// funct3 — OP (R-type) + M-extension
//-----------------------------------------------------------------------------
`define F3_ADD_SUB      3'b000   // funct7[5]=0 → ADD, funct7[5]=1 → SUB
`define F3_SLL          3'b001
`define F3_SLT          3'b010
`define F3_SLTU         3'b011
`define F3_XOR          3'b100
`define F3_SRL_SRA      3'b101   // funct7[5]=0 → SRL, funct7[5]=1 → SRA
`define F3_OR           3'b110
`define F3_AND          3'b111
// M-extension (funct7 = 7'b000_0001 for all)
`define F3_MUL          3'b000
`define F3_MULH         3'b001
`define F3_MULHSU       3'b010
`define F3_MULHU        3'b011
`define F3_DIV          3'b100
`define F3_DIVU         3'b101
`define F3_REM          3'b110
`define F3_REMU         3'b111

//-----------------------------------------------------------------------------
// funct3 — SYSTEM instructions
//-----------------------------------------------------------------------------
`define F3_ECALL_EBREAK 3'b000
`define F3_CSRRW        3'b001
`define F3_CSRRS        3'b010
`define F3_CSRRC        3'b011
`define F3_CSRRWI       3'b101
`define F3_CSRRSI       3'b110
`define F3_CSRRCI       3'b111

//-----------------------------------------------------------------------------
// funct7 fields
//-----------------------------------------------------------------------------
`define F7_NORMAL       7'b000_0000
`define F7_ALT          7'b010_0000   // SUB, SRA, SRAI
`define F7_MEXT         7'b000_0001   // M-extension (MUL, DIV, etc.)

//-----------------------------------------------------------------------------
// ALU operation select — internal encoding (not ISA-defined)
// Used to drive the ALU operation MUX in EX stage
//-----------------------------------------------------------------------------
typedef enum logic [4:0] {
    ALU_ADD     = 5'd0,
    ALU_SUB     = 5'd1,
    ALU_AND     = 5'd2,
    ALU_OR      = 5'd3,
    ALU_XOR     = 5'd4,
    ALU_SLL     = 5'd5,
    ALU_SRL     = 5'd6,
    ALU_SRA     = 5'd7,
    ALU_SLT     = 5'd8,
    ALU_SLTU    = 5'd9,
    ALU_LUI     = 5'd10,  // pass operand B (imm) through
    ALU_AUIPC   = 5'd11,  // PC + imm
    ALU_MUL     = 5'd12,
    ALU_MULH    = 5'd13,
    ALU_MULHSU  = 5'd14,
    ALU_MULHU   = 5'd15,
    ALU_DIV     = 5'd16,
    ALU_DIVU    = 5'd17,
    ALU_REM     = 5'd18,
    ALU_REMU    = 5'd19,
    ALU_NOP     = 5'd20
} alu_op_t;

//-----------------------------------------------------------------------------
// Writeback source select
//-----------------------------------------------------------------------------
typedef enum logic [1:0] {
    WB_ALU   = 2'b00,   // result from ALU/MUL/DIV
    WB_MEM   = 2'b01,   // load data from memory
    WB_PC4   = 2'b10    // PC+4 (JAL, JALR link address)
} wb_src_t;

//-----------------------------------------------------------------------------
// Forwarding MUX select (EX stage operand A and B)
//-----------------------------------------------------------------------------
typedef enum logic [1:0] {
    FWD_NONE   = 2'b00,  // use register file output (no hazard)
    FWD_EX_MEM = 2'b01,  // forward from EX/MEM pipeline register
    FWD_MEM_WB = 2'b10   // forward from MEM/WB pipeline register
} fwd_sel_t;

//-----------------------------------------------------------------------------
// Exception / trap causes — mcause values
// Spec: RISC-V Privileged Architecture v20211203, Table 3.6
//-----------------------------------------------------------------------------
`define CAUSE_INSTR_MISALIGN    32'h0000_0000
`define CAUSE_INSTR_FAULT       32'h0000_0001
`define CAUSE_ILLEGAL_INSTR     32'h0000_0002
`define CAUSE_BREAKPOINT        32'h0000_0003
`define CAUSE_LOAD_MISALIGN     32'h0000_0004
`define CAUSE_LOAD_FAULT        32'h0000_0005
`define CAUSE_STORE_MISALIGN    32'h0000_0006
`define CAUSE_STORE_FAULT       32'h0000_0007
`define CAUSE_ECALL_M           32'h0000_000B

//-----------------------------------------------------------------------------
// CSR addresses — machine mode
// Spec: RISC-V Privileged Architecture v20211203, Table 2.2
//-----------------------------------------------------------------------------
`define CSR_MSTATUS   12'h300
`define CSR_MISA      12'h301
`define CSR_MIE       12'h304
`define CSR_MTVEC     12'h305
`define CSR_MSCRATCH  12'h340
`define CSR_MEPC      12'h341
`define CSR_MCAUSE    12'h342
`define CSR_MTVAL     12'h343
`define CSR_MIP       12'h344
`define CSR_MVENDORID 12'hF11
`define CSR_MARCHID   12'hF12
`define CSR_MIMPID    12'hF13
`define CSR_MHARTID   12'hF14

//-----------------------------------------------------------------------------
// Reset / boot vector
//-----------------------------------------------------------------------------
`define RESET_PC      32'h8000_0000

//-----------------------------------------------------------------------------
// NOP encoding (ADDI x0, x0, 0)
//-----------------------------------------------------------------------------
`define NOP_INSTR     32'h0000_0013

//-----------------------------------------------------------------------------
// RVC (Compressed) quadrant encodings — bits[1:0]
// Spec: RISC-V Unprivileged ISA, Chapter 16
//-----------------------------------------------------------------------------
`define RVC_Q0        2'b00
`define RVC_Q1        2'b01
`define RVC_Q2        2'b10
// Q3 (2'b11) = 32-bit instruction

//-----------------------------------------------------------------------------
// Instruction format immediate sign-extension masks
//-----------------------------------------------------------------------------
`define IMM_I_SIGN_BIT  31   // bit[31] after shift is sign for I-type
`define IMM_S_SIGN_BIT  31
`define IMM_B_SIGN_BIT  31
`define IMM_U_SIGN_BIT  31
`define IMM_J_SIGN_BIT  31

`endif // RV32_DEFINES_SVH
