//=============================================================================
// rv32imc_core.sv — Top-Level RV32IMC CPU Core
//
// Instantiates and connects:
//   if_stage     → ID/EX pipeline register
//   id_stage     → ID/EX pipeline register
//   ex_stage     → EX/MEM pipeline register
//   mem_stage    → MEM/WB pipeline register
//   wb_stage     → register file write
//   hazard_unit  → stall/flush/forwarding control
//   csr_regfile  → machine-mode CSR storage
//
// External interfaces:
//   Instruction fetch: AXI4-Lite read port
//   Data memory:       AXI4 read+write port (with WSTRB)
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

`include "rv32_defines.svh"
`include "axi4_defines.svh"

module rv32imc_core (
    input  logic        clk,
    input  logic        rst_n,

    //=========================================================================
    // Instruction fetch AXI4-Lite port (read-only)
    //=========================================================================
    output logic [31:0] instr_araddr,
    output logic        instr_arvalid,
    input  logic        instr_arready,
    input  logic [31:0] instr_rdata,
    input  logic [1:0]  instr_rresp,
    input  logic        instr_rvalid,
    output logic        instr_rready,

    //=========================================================================
    // Data memory AXI4 port (read + write)
    //=========================================================================
    // Write address channel
    output logic [31:0] data_awaddr,
    output logic [7:0]  data_awlen,
    output logic [2:0]  data_awsize,
    output logic [1:0]  data_awburst,
    output logic        data_awvalid,
    input  logic        data_awready,
    // Write data channel
    output logic [31:0] data_wdata,
    output logic [3:0]  data_wstrb,
    output logic        data_wlast,
    output logic        data_wvalid,
    input  logic        data_wready,
    // Write response channel
    input  logic [1:0]  data_bresp,
    input  logic        data_bvalid,
    output logic        data_bready,
    // Read address channel
    output logic [31:0] data_araddr,
    output logic [7:0]  data_arlen,
    output logic [2:0]  data_arsize,
    output logic [1:0]  data_arburst,
    output logic        data_arvalid,
    input  logic        data_arready,
    // Read data channel
    input  logic [31:0] data_rdata,
    input  logic [1:0]  data_rresp,
    input  logic        data_rvalid,
    output logic        data_rready
);

    //=========================================================================
    // IF/ID pipeline register signals
    //=========================================================================
    logic [31:0] if_id_pc;
    logic [31:0] if_id_instr;
    logic        if_id_valid;
    logic        if_id_is_rvc;

    //=========================================================================
    // ID/EX pipeline register signals
    //=========================================================================
    logic [4:0]  id_ex_rs1_addr;
    logic [4:0]  id_ex_rs2_addr;
    logic [4:0]  id_ex_rd_addr;
    logic [31:0] id_ex_rs1_data;
    logic [31:0] id_ex_rs2_data;
    logic [31:0] id_ex_imm;
    logic [31:0] id_ex_pc;
    alu_op_t     id_ex_alu_op;
    logic        id_ex_alu_src;
    logic        id_ex_mem_read;
    logic        id_ex_mem_write;
    logic [2:0]  id_ex_mem_funct3;
    wb_src_t     id_ex_wb_src;
    logic        id_ex_reg_wen;
    logic        id_ex_is_branch;
    logic        id_ex_is_jal;
    logic        id_ex_is_jalr;
    logic [2:0]  id_ex_branch_funct3;
    logic        id_ex_is_csr;
    logic [11:0] id_ex_csr_addr;
    logic [2:0]  id_ex_csr_funct3;
    logic        id_ex_is_ecall;
    logic        id_ex_is_ebreak;
    logic        id_ex_illegal_instr;
    logic        id_ex_valid;

    //=========================================================================
    // EX/MEM pipeline register signals
    //=========================================================================
    logic [4:0]  ex_mem_rd_addr;
    logic [31:0] ex_mem_alu_result;
    logic [31:0] ex_mem_rs2_data;
    logic        ex_mem_mem_read;
    logic        ex_mem_mem_write;
    logic [2:0]  ex_mem_mem_funct3;
    wb_src_t     ex_mem_wb_src;
    logic        ex_mem_reg_wen;
    logic [31:0] ex_mem_pc_plus4;
    logic        ex_mem_valid;

    //=========================================================================
    // MEM/WB pipeline register signals
    //=========================================================================
    logic [4:0]  mem_wb_rd_addr;
    logic [31:0] mem_wb_alu_result;
    logic [31:0] mem_wb_load_data;
    wb_src_t     mem_wb_wb_src;
    logic        mem_wb_reg_wen;
    logic [31:0] mem_wb_pc_plus4;
    logic        mem_wb_valid;

    //=========================================================================
    // Hazard unit outputs
    //=========================================================================
    logic        stall_if, stall_id;
    logic        flush_if, flush_id, flush_ex;
    logic [1:0]  pc_sel;
    fwd_sel_t    fwd_a_sel, fwd_b_sel;

    //=========================================================================
    // Branch/exception signals from EX
    //=========================================================================
    logic        branch_taken;
    logic [31:0] branch_target;
    logic [31:0] jalr_target;
    logic        ex_exception;
    logic [31:0] ex_cause;
    logic [31:0] ex_mepc;
    logic        mem_exception;
    logic [31:0] mem_cause;
    logic [31:0] mem_bad_addr;
    logic        mem_stall;

    //=========================================================================
    // CSR signals
    //=========================================================================
    logic [11:0] csr_rd_addr;
    logic [31:0] csr_rd_data;
    logic [11:0] csr_wr_addr;
    logic [31:0] csr_wr_data;
    logic        csr_wen;
    logic [31:0] mtvec_out;
    logic [31:0] mepc_out;

    //=========================================================================
    // WB outputs (connect back to ID stage register file write port)
    //=========================================================================
    logic [4:0]  wb_rd_addr;
    logic [31:0] wb_rd_data;
    logic        wb_reg_wen;
    logic [31:0] wb_forward_data;

    //=========================================================================
    // Stage instantiations
    //=========================================================================

    if_stage u_if_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .stall_if           (stall_if),
        .flush_if           (flush_if),
        .pc_sel             (pc_sel),
        .branch_target      (branch_target),
        .jalr_target        (jalr_target),
        .exception_target   (mtvec_out),
        .instr_araddr       (instr_araddr),
        .instr_arvalid      (instr_arvalid),
        .instr_arready      (instr_arready),
        .instr_rdata        (instr_rdata),
        .instr_rresp        (instr_rresp),
        .instr_rvalid       (instr_rvalid),
        .instr_rready       (instr_rready),
        .if_id_pc           (if_id_pc),
        .if_id_instr        (if_id_instr),
        .if_id_valid        (if_id_valid),
        .if_id_is_rvc       (if_id_is_rvc)
    );

    id_stage u_id_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .if_id_pc           (if_id_pc),
        .if_id_instr        (if_id_instr),
        .if_id_valid        (if_id_valid),
        .if_id_is_rvc       (if_id_is_rvc),
        .stall_id           (stall_id),
        .flush_id           (flush_id),
        .wb_rd_addr         (wb_rd_addr),
        .wb_rd_data         (wb_rd_data),
        .wb_reg_wen         (wb_reg_wen),
        .id_ex_rs1_addr     (id_ex_rs1_addr),
        .id_ex_rs2_addr     (id_ex_rs2_addr),
        .id_ex_rd_addr      (id_ex_rd_addr),
        .id_ex_rs1_data     (id_ex_rs1_data),
        .id_ex_rs2_data     (id_ex_rs2_data),
        .id_ex_imm          (id_ex_imm),
        .id_ex_pc           (id_ex_pc),
        .id_ex_alu_op       (id_ex_alu_op),
        .id_ex_alu_src      (id_ex_alu_src),
        .id_ex_mem_read     (id_ex_mem_read),
        .id_ex_mem_write    (id_ex_mem_write),
        .id_ex_mem_funct3   (id_ex_mem_funct3),
        .id_ex_wb_src       (id_ex_wb_src),
        .id_ex_reg_wen      (id_ex_reg_wen),
        .id_ex_is_branch    (id_ex_is_branch),
        .id_ex_is_jal       (id_ex_is_jal),
        .id_ex_is_jalr      (id_ex_is_jalr),
        .id_ex_branch_funct3(id_ex_branch_funct3),
        .id_ex_is_csr       (id_ex_is_csr),
        .id_ex_csr_addr     (id_ex_csr_addr),
        .id_ex_csr_funct3   (id_ex_csr_funct3),
        .id_ex_is_ecall     (id_ex_is_ecall),
        .id_ex_is_ebreak    (id_ex_is_ebreak),
        .id_ex_illegal_instr(id_ex_illegal_instr),
        .id_ex_valid        (id_ex_valid)
    );

    ex_stage u_ex_stage (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .id_ex_rs1_addr         (id_ex_rs1_addr),
        .id_ex_rs2_addr         (id_ex_rs2_addr),
        .id_ex_rd_addr          (id_ex_rd_addr),
        .id_ex_rs1_data         (id_ex_rs1_data),
        .id_ex_rs2_data         (id_ex_rs2_data),
        .id_ex_imm              (id_ex_imm),
        .id_ex_pc               (id_ex_pc),
        .id_ex_alu_op           (id_ex_alu_op),
        .id_ex_alu_src          (id_ex_alu_src),
        .id_ex_mem_read         (id_ex_mem_read),
        .id_ex_mem_write        (id_ex_mem_write),
        .id_ex_mem_funct3       (id_ex_mem_funct3),
        .id_ex_wb_src           (id_ex_wb_src),
        .id_ex_reg_wen          (id_ex_reg_wen),
        .id_ex_is_branch        (id_ex_is_branch),
        .id_ex_is_jal           (id_ex_is_jal),
        .id_ex_is_jalr          (id_ex_is_jalr),
        .id_ex_branch_funct3    (id_ex_branch_funct3),
        .id_ex_is_csr           (id_ex_is_csr),
        .id_ex_csr_addr         (id_ex_csr_addr),
        .id_ex_csr_funct3       (id_ex_csr_funct3),
        .id_ex_is_ecall         (id_ex_is_ecall),
        .id_ex_is_ebreak        (id_ex_is_ebreak),
        .id_ex_illegal_instr    (id_ex_illegal_instr),
        .id_ex_valid            (id_ex_valid),
        .fwd_a_sel              (fwd_a_sel),
        .fwd_b_sel              (fwd_b_sel),
        .ex_mem_alu_result      (ex_mem_alu_result),
        .mem_wb_result          (wb_forward_data),
        .csr_rd_addr            (csr_rd_addr),
        .csr_rd_data            (csr_rd_data),
        .csr_wr_addr            (csr_wr_addr),
        .csr_wr_data            (csr_wr_data),
        .csr_wen                (csr_wen),
        .branch_taken           (branch_taken),
        .branch_target          (branch_target),
        .jalr_target            (jalr_target),
        .ex_exception           (ex_exception),
        .ex_cause               (ex_cause),
        .ex_mepc                (ex_mepc),
        .ex_mem_rd_addr         (ex_mem_rd_addr),
        .ex_mem_alu_result_out  (ex_mem_alu_result),
        .ex_mem_rs2_data        (ex_mem_rs2_data),
        .ex_mem_mem_read        (ex_mem_mem_read),
        .ex_mem_mem_write       (ex_mem_mem_write),
        .ex_mem_mem_funct3      (ex_mem_mem_funct3),
        .ex_mem_wb_src          (ex_mem_wb_src),
        .ex_mem_reg_wen         (ex_mem_reg_wen),
        .ex_mem_pc_plus4        (ex_mem_pc_plus4),
        .ex_mem_valid           (ex_mem_valid)
    );

    mem_stage u_mem_stage (
        .clk                (clk),
        .rst_n              (rst_n),
        .ex_mem_rd_addr     (ex_mem_rd_addr),
        .ex_mem_alu_result  (ex_mem_alu_result),
        .ex_mem_rs2_data    (ex_mem_rs2_data),
        .ex_mem_mem_read    (ex_mem_mem_read),
        .ex_mem_mem_write   (ex_mem_mem_write),
        .ex_mem_mem_funct3  (ex_mem_mem_funct3),
        .ex_mem_wb_src      (ex_mem_wb_src),
        .ex_mem_reg_wen     (ex_mem_reg_wen),
        .ex_mem_pc_plus4    (ex_mem_pc_plus4),
        .ex_mem_valid       (ex_mem_valid),
        .data_awaddr        (data_awaddr),
        .data_awlen         (data_awlen),
        .data_awsize        (data_awsize),
        .data_awburst       (data_awburst),
        .data_awvalid       (data_awvalid),
        .data_awready       (data_awready),
        .data_wdata         (data_wdata),
        .data_wstrb         (data_wstrb),
        .data_wlast         (data_wlast),
        .data_wvalid        (data_wvalid),
        .data_wready        (data_wready),
        .data_bresp         (data_bresp),
        .data_bvalid        (data_bvalid),
        .data_bready        (data_bready),
        .data_araddr        (data_araddr),
        .data_arlen         (data_arlen),
        .data_arsize        (data_arsize),
        .data_arburst       (data_arburst),
        .data_arvalid       (data_arvalid),
        .data_arready       (data_arready),
        .data_rdata         (data_rdata),
        .data_rresp         (data_rresp),
        .data_rvalid        (data_rvalid),
        .data_rready        (data_rready),
        .mem_stall          (mem_stall),
        .mem_exception      (mem_exception),
        .mem_cause          (mem_cause),
        .mem_bad_addr       (mem_bad_addr),
        .mem_wb_rd_addr     (mem_wb_rd_addr),
        .mem_wb_alu_result  (mem_wb_alu_result),
        .mem_wb_load_data   (mem_wb_load_data),
        .mem_wb_wb_src      (mem_wb_wb_src),
        .mem_wb_reg_wen     (mem_wb_reg_wen),
        .mem_wb_pc_plus4    (mem_wb_pc_plus4),
        .mem_wb_valid       (mem_wb_valid)
    );

    wb_stage u_wb_stage (
        .mem_wb_rd_addr     (mem_wb_rd_addr),
        .mem_wb_alu_result  (mem_wb_alu_result),
        .mem_wb_load_data   (mem_wb_load_data),
        .mem_wb_wb_src      (mem_wb_wb_src),
        .mem_wb_reg_wen     (mem_wb_reg_wen),
        .mem_wb_pc_plus4    (mem_wb_pc_plus4),
        .mem_wb_valid       (mem_wb_valid),
        .wb_rd_addr         (wb_rd_addr),
        .wb_rd_data         (wb_rd_data),
        .wb_reg_wen         (wb_reg_wen),
        .wb_forward_data    (wb_forward_data)
    );

    hazard_unit u_hazard_unit (
        .id_ex_rs1_addr     (id_ex_rs1_addr),
        .id_ex_rs2_addr     (id_ex_rs2_addr),
        .ex_mem_rd_addr     (ex_mem_rd_addr),
        .ex_mem_reg_wen     (ex_mem_reg_wen),
        .ex_mem_mem_read    (ex_mem_mem_read),
        .mem_wb_rd_addr     (mem_wb_rd_addr),
        .mem_wb_reg_wen     (mem_wb_reg_wen),
        .if_id_rs1_addr     (id_ex_rs1_addr), // NOTE: see below*
        .if_id_rs2_addr     (id_ex_rs2_addr), // *load-use checks pre-EX instruction
        .ex_mem_valid       (ex_mem_valid),
        .mem_wb_valid       (mem_wb_valid),
        .branch_taken       (branch_taken),
        .ex_exception       (ex_exception),
        .mem_exception      (mem_exception),
        .mem_stall          (mem_stall),
        .stall_if           (stall_if),
        .stall_id           (stall_id),
        .flush_if           (flush_if),
        .flush_id           (flush_id),
        .flush_ex           (flush_ex),
        .pc_sel             (pc_sel),
        .fwd_a_sel          (fwd_a_sel),
        .fwd_b_sel          (fwd_b_sel)
    );

    csr_regfile u_csr_regfile (
        .clk                (clk),
        .rst_n              (rst_n),
        .rd_addr            (csr_rd_addr),
        .rd_data            (csr_rd_data),
        .wr_addr            (csr_wr_addr),
        .wr_data            (csr_wr_data),
        .wen                (csr_wen),
        .trap_en            (ex_exception | mem_exception),
        .trap_pc            (ex_exception ? ex_mepc : id_ex_pc),
        .trap_cause         (ex_exception ? ex_cause : mem_cause),
        .trap_val           (mem_exception ? mem_bad_addr : 32'd0),
        .mret_en            (1'b0),      // TODO: wire MRET from decoder
        .mtvec_out          (mtvec_out),
        .mepc_out           (mepc_out)
    );

    // TODO: Expose debug ports for DV (optional — comment out for synthesis)
    // These are useful for the UVM scoreboard to observe internal state
    // `ifdef SIMULATION
    //     // expose register file, PC, pipeline stage valids
    // `endif

endmodule
