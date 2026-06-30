//=============================================================================
// axi4_defines.svh — AXI4 bus parameter and encoding definitions
// Spec: AMBA AXI4 Protocol Specification IHI0022E
//       Section A2 (signal list), Section A3 (transaction attributes)
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

`ifndef AXI4_DEFINES_SVH
`define AXI4_DEFINES_SVH

//-----------------------------------------------------------------------------
// Bus width parameters — adjust at integration level if needed
//-----------------------------------------------------------------------------
`define AXI4_ADDR_WIDTH   32
`define AXI4_DATA_WIDTH   32
`define AXI4_STRB_WIDTH   (`AXI4_DATA_WIDTH / 8)   // 4 bytes
`define AXI4_ID_WIDTH      4
`define AXI4_LEN_WIDTH     8   // AxLEN field: burst length - 1 (0 = 1 beat)
`define AXI4_SIZE_WIDTH    3
`define AXI4_BURST_WIDTH   2
`define AXI4_RESP_WIDTH    2

//-----------------------------------------------------------------------------
// AxBURST — burst type encoding
// Spec: IHI0022E Section A3.4.1
//-----------------------------------------------------------------------------
`define AXI4_BURST_FIXED    2'b00   // all beats use same address
`define AXI4_BURST_INCR     2'b01   // incrementing burst (most common)
`define AXI4_BURST_WRAP     2'b10   // wrapping burst

//-----------------------------------------------------------------------------
// AxSIZE — transfer size (bytes per beat)
// Spec: IHI0022E Section A3.4.1
//-----------------------------------------------------------------------------
`define AXI4_SIZE_1B        3'b000
`define AXI4_SIZE_2B        3'b001
`define AXI4_SIZE_4B        3'b010   // 32-bit word (default for this SoC)
`define AXI4_SIZE_8B        3'b011
`define AXI4_SIZE_16B       3'b100
`define AXI4_SIZE_32B       3'b101
`define AXI4_SIZE_64B       3'b110
`define AXI4_SIZE_128B      3'b111

//-----------------------------------------------------------------------------
// xRESP — response codes
// Spec: IHI0022E Section A3.4.4
//-----------------------------------------------------------------------------
`define AXI4_RESP_OKAY      2'b00   // normal success
`define AXI4_RESP_EXOKAY    2'b01   // exclusive access success
`define AXI4_RESP_SLVERR    2'b10   // slave error
`define AXI4_RESP_DECERR    2'b11   // decode error (no slave at address)

//-----------------------------------------------------------------------------
// AxPROT bits (not used in this SoC but must be driven)
//-----------------------------------------------------------------------------
`define AXI4_PROT_UNPRIV    3'b000

//-----------------------------------------------------------------------------
// AxCACHE bits (not used — drive to 0 for device/non-cacheable)
//-----------------------------------------------------------------------------
`define AXI4_CACHE_DEVICE   4'b0000

//-----------------------------------------------------------------------------
// AxLOCK (no exclusive access in this SoC)
//-----------------------------------------------------------------------------
`define AXI4_LOCK_NORMAL    1'b0

//-----------------------------------------------------------------------------
// AXI4 address map — SoC memory map
// CPU instruction fetch → SRAM base
// CPU data access     → SRAM base (shared)
// GEMM accelerator    → mapped at separate base address
//-----------------------------------------------------------------------------
`define SRAM_BASE_ADDR      32'h8000_0000
`define SRAM_SIZE           32'h0001_0000   // 64 KB
`define GEMM_BASE_ADDR      32'hC000_0000
`define GEMM_SIZE           32'h0000_0100   // 256 bytes (enough for all registers)

//-----------------------------------------------------------------------------
// GEMM register offsets (relative to GEMM_BASE_ADDR)
// See project spec Table: Control Register Map
//-----------------------------------------------------------------------------
`define GEMM_CTRL_OFF       8'h00
`define GEMM_STATUS_OFF     8'h04
`define GEMM_BASE_A_OFF     8'h08
`define GEMM_BASE_B_OFF     8'h0C
`define GEMM_BASE_C_OFF     8'h10
`define GEMM_BUF_A_OFF      8'h14   // 16 bytes: 0x14–0x50 (16 × INT8, packed 4/word)
`define GEMM_BUF_B_OFF      8'h50   // 16 bytes: 0x50–0x8C
`define GEMM_BUF_C_OFF      8'h90   // 64 bytes: 0x90–0xCC (16 × INT32)

//-----------------------------------------------------------------------------
// AXI4 interface struct — can be used with modports in future
// Keeping as `defines for compatibility with Verilog simulators
//-----------------------------------------------------------------------------

// Write address channel signals prefix: aw_
// Write data channel signals prefix:    w_
// Write response channel signals prefix: b_
// Read address channel signals prefix:  ar_
// Read data channel signals prefix:     r_

`endif // AXI4_DEFINES_SVH
