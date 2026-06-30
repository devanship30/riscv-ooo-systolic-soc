//=============================================================================
// sram_model.sv — Behavioral SRAM for Simulation
//
// Single-port word-addressable SRAM with AXI4 slave interface.
// Used in simulation only — replace with foundry SRAM macro for tapeout.
//
// Serves BOTH instruction fetch (AXI4-Lite read) and data access (AXI4 R/W).
// The SoC interconnect routes both ports here; internally arbitrated.
//
// Parameters:
//   DEPTH_WORDS  — number of 32-bit words (default 16K = 64KB)
//   BASE_ADDR    — base address in SoC memory map
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

`include "axi4_defines.svh"

module sram_model #(
    parameter int DEPTH_WORDS = 16384,    // 16K × 32b = 64 KB
    parameter logic [31:0] BASE_ADDR = `SRAM_BASE_ADDR
)(
    input  logic        clk,
    input  logic        rst_n,

    //=========================================================================
    // Instruction fetch port (AXI4-Lite read-only)
    //=========================================================================
    input  logic [31:0] instr_araddr,
    input  logic        instr_arvalid,
    output logic        instr_arready,
    output logic [31:0] instr_rdata,
    output logic [1:0]  instr_rresp,
    output logic        instr_rvalid,
    input  logic        instr_rready,

    //=========================================================================
    // Data port (AXI4 read + write with WSTRB)
    //=========================================================================
    input  logic [31:0] data_awaddr,
    input  logic [7:0]  data_awlen,
    input  logic [2:0]  data_awsize,
    input  logic [1:0]  data_awburst,
    input  logic        data_awvalid,
    output logic        data_awready,
    input  logic [31:0] data_wdata,
    input  logic [3:0]  data_wstrb,
    input  logic        data_wlast,
    input  logic        data_wvalid,
    output logic        data_wready,
    output logic [1:0]  data_bresp,
    output logic        data_bvalid,
    input  logic        data_bready,
    input  logic [31:0] data_araddr,
    input  logic [7:0]  data_arlen,
    input  logic [2:0]  data_arsize,
    input  logic [1:0]  data_arburst,
    input  logic        data_arvalid,
    output logic        data_arready,
    output logic [31:0] data_rdata,
    output logic [1:0]  data_rresp,
    output logic        data_rvalid,
    input  logic        data_rready
);

    //=========================================================================
    // Memory array
    //=========================================================================
    logic [31:0] mem [0:DEPTH_WORDS-1];

    // Initialize to 0 (firmware loaded by testbench $readmemh)
    initial begin
        for (int i = 0; i < DEPTH_WORDS; i++) begin
            mem[i] = 32'd0;
        end
    end

    // Convenience task for testbench firmware loading
    task load_hex(input string filename);
        $readmemh(filename, mem);
        $display("[SRAM] Loaded firmware from %s", filename);
    endtask

    //=========================================================================
    // Address → word index
    //=========================================================================
    function automatic int addr_to_idx(input logic [31:0] addr);
        return (addr - BASE_ADDR) >> 2;
    endfunction

    //=========================================================================
    // Instruction fetch port — simple 1-cycle response
    //=========================================================================
    logic        instr_pending;
    logic [31:0] instr_addr_reg;

    assign instr_arready = 1'b1;  // always ready to accept read address

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            instr_rvalid   <= 1'b0;
            instr_rdata    <= 32'd0;
            instr_rresp    <= `AXI4_RESP_OKAY;
        end else begin
            if (instr_arvalid && instr_arready) begin
                // Latch and respond next cycle
                instr_rdata  <= mem[addr_to_idx(instr_araddr)];
                instr_rresp  <= `AXI4_RESP_OKAY;
                instr_rvalid <= 1'b1;
            end else if (instr_rvalid && instr_rready) begin
                instr_rvalid <= 1'b0;
            end
        end
    end

    //=========================================================================
    // Data write port — accept AW and W channels, respond on B channel
    // Simple: accept AW and W in any order, write when both received
    //=========================================================================
    logic        aw_received, w_received;
    logic [31:0] aw_addr_reg;
    logic [31:0] w_data_reg;
    logic [3:0]  w_strb_reg;

    assign data_awready = 1'b1;
    assign data_wready  = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            aw_received  <= 1'b0;
            w_received   <= 1'b0;
            data_bvalid  <= 1'b0;
            data_bresp   <= `AXI4_RESP_OKAY;
        end else begin
            // Capture write address
            if (data_awvalid && data_awready) begin
                aw_addr_reg <= data_awaddr;
                aw_received <= 1'b1;
            end
            // Capture write data
            if (data_wvalid && data_wready) begin
                w_data_reg  <= data_wdata;
                w_strb_reg  <= data_wstrb;
                w_received  <= 1'b1;
            end
            // Perform write when both are ready
            if (aw_received && w_received) begin
                // Byte-enable write
                if (w_strb_reg[0]) mem[addr_to_idx(aw_addr_reg)][7:0]   <= w_data_reg[7:0];
                if (w_strb_reg[1]) mem[addr_to_idx(aw_addr_reg)][15:8]  <= w_data_reg[15:8];
                if (w_strb_reg[2]) mem[addr_to_idx(aw_addr_reg)][23:16] <= w_data_reg[23:16];
                if (w_strb_reg[3]) mem[addr_to_idx(aw_addr_reg)][31:24] <= w_data_reg[31:24];
                aw_received  <= 1'b0;
                w_received   <= 1'b0;
                data_bvalid  <= 1'b1;
                data_bresp   <= `AXI4_RESP_OKAY;
            end else if (data_bvalid && data_bready) begin
                data_bvalid <= 1'b0;
            end
        end
    end

    //=========================================================================
    // Data read port — 1-cycle response
    //=========================================================================
    assign data_arready = 1'b1;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_rvalid <= 1'b0;
            data_rdata  <= 32'd0;
            data_rresp  <= `AXI4_RESP_OKAY;
        end else begin
            if (data_arvalid && data_arready) begin
                data_rdata  <= mem[addr_to_idx(data_araddr)];
                data_rresp  <= `AXI4_RESP_OKAY;
                data_rvalid <= 1'b1;
            end else if (data_rvalid && data_rready) begin
                data_rvalid <= 1'b0;
            end
        end
    end

endmodule
