//=============================================================================
// mem_stage.sv — Memory Access Stage
// Spec: RISC-V Unprivileged ISA v20191213, Section 2.6 (Load/Store)
//       AMBA AXI4 Protocol IHI0022E, Section A3 (transaction structure)
//
// Responsibilities:
//   1. Issue AXI4 read transactions for LOAD instructions
//   2. Issue AXI4 write transactions for STORE instructions
//   3. Generate byte enables (WSTRB) for SB, SH, SW
//   4. Sign/zero-extend loaded data for LB, LH, LBU, LHU
//   5. Detect address misalignment → raise exception
//   6. Output MEM/WB pipeline register
//
// AXI4 note: Full AXI4 (not AXI4-Lite) because WSTRB (byte strobes) are
//            needed for sub-word stores (SB, SH). Spec: IHI0022E Section A3.4.
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
// TODO     : [ ] AXI4 read/write FSM
//            [ ] Byte enable generation
//            [ ] Load data sign extension
//            [ ] Misalignment detection
//=============================================================================

`include "rv32_defines.svh"
`include "axi4_defines.svh"

module mem_stage (
    input  logic        clk,
    input  logic        rst_n,

    //-------------------------------------------------------------------------
    // EX/MEM pipeline register inputs
    //-------------------------------------------------------------------------
    input  logic [4:0]  ex_mem_rd_addr,
    input  logic [31:0] ex_mem_alu_result,   // computed memory address
    input  logic [31:0] ex_mem_rs2_data,     // store data
    input  logic        ex_mem_mem_read,
    input  logic        ex_mem_mem_write,
    input  logic [2:0]  ex_mem_mem_funct3,
    input  wb_src_t     ex_mem_wb_src,
    input  logic        ex_mem_reg_wen,
    input  logic [31:0] ex_mem_pc_plus4,
    input  logic        ex_mem_valid,

    //-------------------------------------------------------------------------
    // AXI4 data master port (read + write)
    // Spec: IHI0022E — Full AXI4 (WSTRB required for SB/SH)
    //-------------------------------------------------------------------------
    // Write address channel
    output logic [31:0] data_awaddr,
    output logic [7:0]  data_awlen,     // burst length - 1 (0 = single beat)
    output logic [2:0]  data_awsize,    // transfer size (010 = 4 bytes)
    output logic [1:0]  data_awburst,
    output logic        data_awvalid,
    input  logic        data_awready,
    // Write data channel
    output logic [31:0] data_wdata,
    output logic [3:0]  data_wstrb,    // byte enables
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
    output logic        data_rready,

    //-------------------------------------------------------------------------
    // Stall output → hazard unit
    //-------------------------------------------------------------------------
    output logic        mem_stall,      // 1 = AXI transaction not yet complete

    //-------------------------------------------------------------------------
    // Exception output
    //-------------------------------------------------------------------------
    output logic        mem_exception,
    output logic [31:0] mem_cause,
    output logic [31:0] mem_bad_addr,   // mtval = faulting address

    //-------------------------------------------------------------------------
    // MEM/WB pipeline register outputs
    //-------------------------------------------------------------------------
    output logic [4:0]  mem_wb_rd_addr,
    output logic [31:0] mem_wb_alu_result,
    output logic [31:0] mem_wb_load_data,   // sign/zero-extended load result
    output wb_src_t     mem_wb_wb_src,
    output logic        mem_wb_reg_wen,
    output logic [31:0] mem_wb_pc_plus4,
    output logic        mem_wb_valid
);

    //=========================================================================
    // Memory address (word-aligned for AXI transactions)
    //=========================================================================
    logic [31:0] mem_addr;
    logic [1:0]  byte_offset; // bits[1:0] of address
    assign mem_addr    = ex_mem_alu_result;
    assign byte_offset = mem_addr[1:0];

    //=========================================================================
    // TODO: Misalignment detection
    // Spec: RV32I Section 2.6
    //   LH/LHU: address must be 2-byte aligned (addr[0] == 0)
    //   LW:     address must be 4-byte aligned (addr[1:0] == 0)
    //   SH:     address must be 2-byte aligned
    //   SW:     address must be 4-byte aligned
    //   LB/SB:  always aligned
    //=========================================================================
    logic load_misaligned, store_misaligned;
    always_comb begin
        load_misaligned  = 1'b0;
        store_misaligned = 1'b0;
        if (ex_mem_mem_read) begin
            case (ex_mem_mem_funct3)
                `F3_LH, `F3_LHU : load_misaligned  = mem_addr[0];
                `F3_LW           : load_misaligned  = |mem_addr[1:0];
                default          : load_misaligned  = 1'b0;
            endcase
        end
        if (ex_mem_mem_write) begin
            case (ex_mem_mem_funct3)
                `F3_SH : store_misaligned = mem_addr[0];
                `F3_SW : store_misaligned = |mem_addr[1:0];
                default: store_misaligned = 1'b0;
            endcase
        end
    end

    assign mem_exception = ex_mem_valid & (load_misaligned | store_misaligned);
    assign mem_cause     = load_misaligned  ? `CAUSE_LOAD_MISALIGN  :
                           store_misaligned ? `CAUSE_STORE_MISALIGN : 32'd0;
    assign mem_bad_addr  = mem_addr;

    //=========================================================================
    // TODO: Byte enable (WSTRB) generation for stores
    // AXI4 Spec IHI0022E Section A3.4.3 — WSTRB indicates active byte lanes
    //
    // SW  → wstrb = 4'b1111 (all bytes)
    // SH  → wstrb = 4'b0011 << {byte_offset[1], 1'b0}
    //        e.g., addr[1:0]=00 → 4'b0011; addr[1:0]=10 → 4'b1100
    // SB  → wstrb = 4'b0001 << byte_offset
    //        e.g., addr[1:0]=00 → 4'b0001; =01 → 4'b0010; etc.
    //
    // Store data must also be shifted to the correct byte lane:
    // SH at addr[1:0]=2: wdata = {rs2[15:0], 16'b0}
    //=========================================================================
    logic [3:0]  wstrb;
    logic [31:0] wdata_aligned;

    always_comb begin
        wstrb        = 4'b1111;
        wdata_aligned = ex_mem_rs2_data;
        if (ex_mem_mem_write) begin
            case (ex_mem_mem_funct3)
                `F3_SB: begin
                    wstrb         = 4'b0001 << byte_offset;
                    wdata_aligned = {4{ex_mem_rs2_data[7:0]}}; // replicate byte to all lanes
                end
                `F3_SH: begin
                    wstrb         = 4'b0011 << {byte_offset[1], 1'b0};
                    wdata_aligned = {2{ex_mem_rs2_data[15:0]}};
                end
                `F3_SW: begin
                    wstrb         = 4'b1111;
                    wdata_aligned = ex_mem_rs2_data;
                end
                default: begin
                    wstrb = 4'b0000;
                end
            endcase
        end
    end

    //=========================================================================
    // TODO: AXI4 write transaction (store)
    // Single-beat INCR burst: AWLEN=0, AWSIZE=010 (4B), AWBURST=INCR
    // Spec: IHI0022E Section A3.4 — transaction structure
    //
    // FSM states (implement as enum):
    //   IDLE → AW_PHASE (assert AWVALID) →
    //         W_PHASE  (assert WVALID + WLAST) →
    //         B_PHASE  (wait for BVALID) → IDLE
    //=========================================================================
    assign data_awaddr  = {mem_addr[31:2], 2'b00}; // word-align for AXI
    assign data_awlen   = 8'd0;                      // single beat
    assign data_awsize  = `AXI4_SIZE_4B;
    assign data_awburst = `AXI4_BURST_INCR;
    assign data_awvalid = 1'b0; // TODO: drive from FSM
    assign data_wdata   = wdata_aligned;
    assign data_wstrb   = wstrb;
    assign data_wlast   = 1'b1; // always last beat for single-beat burst
    assign data_wvalid  = 1'b0; // TODO: drive from FSM
    assign data_bready  = 1'b1; // always ready to accept write response

    //=========================================================================
    // TODO: AXI4 read transaction (load)
    // Single-beat read; data returned on RDATA channel
    //=========================================================================
    assign data_araddr  = {mem_addr[31:2], 2'b00};
    assign data_arlen   = 8'd0;
    assign data_arsize  = `AXI4_SIZE_4B;
    assign data_arburst = `AXI4_BURST_INCR;
    assign data_arvalid = 1'b0; // TODO: drive from FSM
    assign data_rready  = 1'b1;

    //=========================================================================
    // TODO: Load data extraction and sign-extension
    // AXI4 always returns 32-bit RDATA; extract the relevant byte/halfword
    // and sign/zero-extend to 32 bits.
    //
    // LB:  result = sign_extend(rdata >> (byte_offset*8))[7:0]
    // LBU: result = zero_extend(rdata >> (byte_offset*8))[7:0]
    // LH:  result = sign_extend(rdata >> (byte_offset[1]*16))[15:0]
    // LHU: result = zero_extend(rdata >> (byte_offset[1]*16))[15:0]
    // LW:  result = rdata (no extension needed)
    //=========================================================================
    logic [31:0] load_data_raw;
    logic [31:0] load_data_ext;

    assign load_data_raw = data_rdata; // word from AXI

    always_comb begin
        load_data_ext = 32'd0;
        case (ex_mem_mem_funct3)
            `F3_LB : begin
                // TODO: extract byte, sign-extend
                case (byte_offset)
                    2'b00: load_data_ext = {{24{load_data_raw[7]}},  load_data_raw[7:0]};
                    2'b01: load_data_ext = {{24{load_data_raw[15]}}, load_data_raw[15:8]};
                    2'b10: load_data_ext = {{24{load_data_raw[23]}}, load_data_raw[23:16]};
                    2'b11: load_data_ext = {{24{load_data_raw[31]}}, load_data_raw[31:24]};
                endcase
            end
            `F3_LBU: begin
                case (byte_offset)
                    2'b00: load_data_ext = {24'd0, load_data_raw[7:0]};
                    2'b01: load_data_ext = {24'd0, load_data_raw[15:8]};
                    2'b10: load_data_ext = {24'd0, load_data_raw[23:16]};
                    2'b11: load_data_ext = {24'd0, load_data_raw[31:24]};
                endcase
            end
            `F3_LH : begin
                load_data_ext = byte_offset[1] ?
                    {{16{load_data_raw[31]}}, load_data_raw[31:16]} :
                    {{16{load_data_raw[15]}}, load_data_raw[15:0]};
            end
            `F3_LHU: begin
                load_data_ext = byte_offset[1] ?
                    {16'd0, load_data_raw[31:16]} :
                    {16'd0, load_data_raw[15:0]};
            end
            `F3_LW : load_data_ext = load_data_raw;
            default: load_data_ext = load_data_raw;
        endcase
    end

    //=========================================================================
    // Stall while AXI transaction is pending
    //=========================================================================
    // TODO: mem_stall = 1 when a load/store is issued but RVALID/BVALID not yet seen
    assign mem_stall = 1'b0; // placeholder

    //=========================================================================
    // MEM/WB pipeline register
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_wb_rd_addr    <= 5'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_load_data  <= 32'd0;
            mem_wb_wb_src     <= WB_ALU;
            mem_wb_reg_wen    <= 1'b0;
            mem_wb_pc_plus4   <= 32'd0;
            mem_wb_valid      <= 1'b0;
        end else begin
            mem_wb_rd_addr    <= ex_mem_rd_addr;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_load_data  <= load_data_ext;
            mem_wb_wb_src     <= ex_mem_wb_src;
            mem_wb_reg_wen    <= ex_mem_reg_wen & ex_mem_valid & ~mem_exception;
            mem_wb_pc_plus4   <= ex_mem_pc_plus4;
            mem_wb_valid      <= ex_mem_valid & ~mem_exception;
        end
    end

endmodule
