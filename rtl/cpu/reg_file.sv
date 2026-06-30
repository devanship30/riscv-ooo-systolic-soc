//=============================================================================
// reg_file.sv — 32×32 Integer Register File
// Spec: RISC-V Unprivileged ISA v20191213, Section 2.1
//   "Register x0 is hardwired with all bits equal to 0."
//   "Any instruction that attempts to write x0 has no effect."
//
// Architecture:
//   - 32 registers × 32 bits
//   - 2 asynchronous read ports (rs1, rs2) — combinational output
//   - 1 synchronous write port (rd) — registered on clock rising edge
//   - x0 permanently 0: write port ignores wen when rd_addr == 0
//
// Read-after-write (same cycle): if write and read target same register,
//   this implementation returns the NEW value (write-first / bypass).
//   Adjust to return OLD value (read-first) depending on pipeline needs.
//   Currently: write-first (simplifies WB→ID hazard).
//
// SVA reference: x0_never_written (cpu_sva.sv) verifies this behavior
//
// Authors : Student 1 (DV) + Student 2 (RTL)
// Project : RV32IMC-GEMM SoC
//=============================================================================

module reg_file (
    input  logic        clk,
    input  logic        rst_n,

    // Read port 1 (rs1)
    input  logic [4:0]  rs1_addr,
    output logic [31:0] rs1_data,

    // Read port 2 (rs2)
    input  logic [4:0]  rs2_addr,
    output logic [31:0] rs2_data,

    // Write port (rd — from WB stage)
    input  logic [4:0]  rd_addr,
    input  logic [31:0] rd_data,
    input  logic        wen
);

    //=========================================================================
    // Register array — 32 × 32-bit
    //=========================================================================
    logic [31:0] regs [31:0];

    //=========================================================================
    // Synchronous write — x0 write is silently discarded
    //=========================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all registers to 0 on reset
            integer i;
            for (i = 0; i < 32; i++) begin
                regs[i] <= 32'd0;
            end
        end else if (wen && (rd_addr != 5'd0)) begin
            regs[rd_addr] <= rd_data;
        end
        // rd_addr == 0: no write (x0 permanently 0)
    end

    //=========================================================================
    // Asynchronous reads with write-first bypass
    // If the write port and read port address match in same cycle,
    // return the incoming write data (forwarded — avoids 1-cycle RAW for WB→ID)
    //=========================================================================
    assign rs1_data = (wen && (rd_addr == rs1_addr) && (rd_addr != 5'd0))
                      ? rd_data
                      : regs[rs1_addr];

    assign rs2_data = (wen && (rd_addr == rs2_addr) && (rd_addr != 5'd0))
                      ? rd_data
                      : regs[rs2_addr];

    // x0 always reads as 0 regardless of array state
    // (The reset ensures regs[0]=0, but this is belt-and-suspenders)
    // Override: if reading x0, force 0
    // (Optional — covered by reset + write guard above)

endmodule
