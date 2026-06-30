//=============================================================================
// wb_stage.sv — Writeback Stage
// Spec: RISC-V Unprivileged ISA v20191213, Section 2.2 (Register File)
//
// Responsibilities:
//   1. Select writeback data source: ALU result / load data / PC+4
//   2. Drive register file write port (rd_addr, rd_data, wen)
//   3. Provide MEM/WB forwarding data to EX stage
//
// Note: x0 is never written (hardware wires zero). The reg_file module
//       enforces this — see x0_never_written SVA assertion in cpu_sva.sv.
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

`include "rv32_defines.svh"

module wb_stage (
    //-------------------------------------------------------------------------
    // MEM/WB pipeline register inputs
    //-------------------------------------------------------------------------
    input  logic [4:0]  mem_wb_rd_addr,
    input  logic [31:0] mem_wb_alu_result,
    input  logic [31:0] mem_wb_load_data,
    input  wb_src_t     mem_wb_wb_src,
    input  logic        mem_wb_reg_wen,
    input  logic [31:0] mem_wb_pc_plus4,
    input  logic        mem_wb_valid,

    //-------------------------------------------------------------------------
    // Register file write port outputs (connect to ID stage reg_file)
    //-------------------------------------------------------------------------
    output logic [4:0]  wb_rd_addr,
    output logic [31:0] wb_rd_data,
    output logic        wb_reg_wen,

    //-------------------------------------------------------------------------
    // Forwarding output → EX stage mem_wb_result mux
    //-------------------------------------------------------------------------
    output logic [31:0] wb_forward_data
);

    //=========================================================================
    // Writeback data mux
    // Spec: RV32I — result written to rd is:
    //   ALU result for R-type, I-type (non-load), LUI, AUIPC
    //   Load data   for LB, LH, LW, LBU, LHU
    //   PC+4        for JAL, JALR (link address)
    //=========================================================================
    always_comb begin
        case (mem_wb_wb_src)
            WB_ALU : wb_rd_data = mem_wb_alu_result;
            WB_MEM : wb_rd_data = mem_wb_load_data;
            WB_PC4 : wb_rd_data = mem_wb_pc_plus4;
            default: wb_rd_data = mem_wb_alu_result;
        endcase
    end

    assign wb_rd_addr     = mem_wb_rd_addr;
    assign wb_reg_wen     = mem_wb_reg_wen & mem_wb_valid;
    assign wb_forward_data = wb_rd_data;  // forwarding uses same data

endmodule
