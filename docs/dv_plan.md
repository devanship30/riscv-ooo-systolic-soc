# RV32IMC-GEMM SoC — Verification Plan
**Student 1 (DV) — NC State University, Masters in Computer Engineering**
**Revision:** 0.1 — Week 1 skeleton (fill in by end of Week 5)

---

## 1. Scope

This document covers the verification plan for the RV32IMC-GEMM SoC, consisting of:
- 5-stage RV32IMC CPU core (IF/ID/EX/MEM/WB + hazard unit + CSR)
- INT8 4×4 systolic GEMM accelerator (AXI4 slave)
- AXI4 interconnect (1 master, 2 slaves)

**Out of scope:** physical verification, power analysis, timing sign-off, U/S privilege modes, virtual memory.

---

## 2. Verification Strategy

| Phase | Technique | Tool | Target |
|-------|-----------|------|--------|
| Phase 2, Week 5 | UVM directed tests | VCS | Block-level correctness |
| Phase 2, Week 6 | SVA assertions | VCS | Protocol invariants |
| Phase 2, Week 7 | Constrained-random | VCS + Spike | >90% functional coverage |
| Phase 2, Week 7 | Formal verification | SymbiYosys | Prove key properties |
| Phase 2, Week 8 | Coverage closure | VCS | >90% functional, >85% code |

---

## 3. UVM Environment Architecture

```
soc_env
├── cpu_agent (AXI4 master monitor)
│   ├── instr_agent  (AXI4-Lite instruction fetch monitor)
│   └── data_agent   (AXI4 data R/W driver + monitor)
├── gemm_agent (AXI4 slave monitor)
├── cpu_scoreboard   (Spike step-and-compare via DPI-C)
├── gemm_scoreboard  (INT8 software reference model)
└── coverage_collector
```

### 3.1 Spike DPI-C Integration
- Spike ISS is integrated via DPI-C as a step-and-compare oracle
- On every instruction retirement, the UVM scoreboard:
  1. Steps Spike one instruction
  2. Compares register file state (all 32 registers)
  3. Compares PC
  4. Reports mismatch with full context (PC, instr, expected vs actual)

**TODO (Week 5):** Write the DPI-C wrapper for Spike in `tb/env/cpu_scoreboard.sv`

### 3.2 GEMM Software Reference Model
- Pure SystemVerilog INT8 matrix multiply (no external dependency)
- For each GEMM run: compute expected C = A × B in software, compare to accelerator output
- Checks: all 16 INT32 elements of output matrix C

---

## 4. Test Categories

### 4.1 CPU Directed Tests

| Test Name | Instructions Covered | Hazard Types | Expected Cycles |
|-----------|---------------------|--------------|-----------------|
| test_alu_basic | ADD, SUB, AND, OR, XOR, SLL, SRL, SRA | None | ~40 |
| test_alu_imm | ADDI, SLTI, XORI, ORI, ANDI, SLLI, SRLI, SRAI | None | ~40 |
| test_load_store | LB, LH, LW, LBU, LHU, SB, SH, SW | Load-use stalls | ~80 |
| test_branches | BEQ, BNE, BLT, BGE, BLTU, BGEU | Branch flush | ~60 |
| test_jumps | JAL, JALR | None | ~20 |
| test_upper_imm | LUI, AUIPC | None | ~20 |
| test_m_ext | MUL, MULH, MULHU, MULHSU, DIV, DIVU, REM, REMU | None | ~200 |
| test_rvc | C.ADD, C.LW, C.SW, C.J, C.BEQZ, C.BNEZ, C.LI, C.MV | Mixed | ~60 |
| test_hazards | Back-to-back RAW sequences | EX→EX, MEM→EX | ~50 |
| test_load_use | LOAD + dependent instruction sequences | Load-use stall | ~40 |
| test_exceptions | Illegal instr, misaligned load/store, ECALL | Exception flush | ~30 |
| test_csr | CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI | None | ~40 |

### 4.2 GEMM Directed Tests

| Test Name | Input Data | Expected Behavior |
|-----------|-----------|-------------------|
| test_gemm_identity | A=I₄, B=I₄ | C = I₄ (identity) |
| test_gemm_zero | A=0, B=0 | C = 0 (all zeros) |
| test_gemm_max_pos | A=127, B=127 | C = 127×127×4 = 64516 per element |
| test_gemm_max_neg | A=-128, B=-128 | C = (-128)×(-128)×4 = 65536 per element |
| test_gemm_mixed | A=mixed signs, B=mixed signs | Compare against SW reference |
| test_gemm_overflow | Values near INT32 max | Check saturation/overflow behavior |
| test_gemm_back2back | Multiple consecutive runs | Status FSM correct each time |
| test_gemm_read_busy | Read BUF_C while busy=1 | Stale/undefined behavior documented |

### 4.3 SoC Integration Tests

| Test Name | Description |
|-----------|-------------|
| test_soc_basic_gemm | Full CPU→GEMM sequence: write BUF_A/B, start, poll, read BUF_C |
| test_soc_multi_gemm | 10 back-to-back GEMM runs with different inputs |
| test_soc_gemm_while_cpu | CPU executes other instructions while GEMM runs |

---

## 5. SVA Assertion List (16 properties)

See `formal/properties/cpu_sva.sv` for implementation.

### 5.1 CPU Pipeline Assertions

| ID | Property Name | Description | Stage |
|----|--------------|-------------|-------|
| A1 | no_phantom_write | reg_write_en=0 for non-writing instructions | WB |
| A2 | stall_propagation | IF and ID stall when MEM stalls | Hazard |
| A3 | no_instr_lost_on_flush | IF and ID output NOP cycle after branch flush | Hazard |
| A4 | load_use_stall | Exactly 1 bubble on LOAD→dependent sequence | Hazard |
| A5 | x0_never_written | x0 register always reads 0 | ID/WB |
| A6 | pc_alignment | PC always 2-byte aligned | IF |

### 5.2 AXI4 CPU Master Assertions

| ID | Property Name | Description |
|----|--------------|-------------|
| A7 | axi4_arvalid_stable | ARVALID holds until ARREADY |
| A8 | axi4_awvalid_stable | AWVALID holds until AWREADY |
| A9 | axi4_wdata_stable | WDATA stable while WVALID & ~WREADY |
| A10 | axi4_no_response_before_request | RVALID only after ARVALID |

### 5.3 AXI4 GEMM Slave Assertions

| ID | Property Name | Description |
|----|--------------|-------------|
| A11 | gemm_ctrl_self_clear | CTRL[start] self-clears within 2 cycles |
| A12 | gemm_status_busy_during_compute | STATUS[busy]=1 for compute duration |
| A13 | gemm_no_start_while_busy | New start ignored while busy |
| A14 | gemm_output_stable | BUF_C stable after done until next start |

### 5.4 Hazard Unit Assertions

| ID | Property Name | Description |
|----|--------------|-------------|
| A15 | forward_path_priority | EX/MEM forwarding overrides MEM/WB for same reg |
| A16 | no_double_stall | Load-use inserts exactly 1 bubble, not 2 |

---

## 6. Functional Coverage Model

See `tb/env/coverage_collector.sv` for implementation.

### 6.1 CPU Instruction Coverage (target: 100%)

```systemverilog
// TODO: implement in coverage_collector.sv
covergroup instr_type_cg;
    cp_format: coverpoint instr_format {
        bins r_type = {R_TYPE};
        bins i_type = {I_TYPE};
        bins s_type = {S_TYPE};
        bins b_type = {B_TYPE};
        bins u_type = {U_TYPE};
        bins j_type = {J_TYPE};
    }
endgroup

covergroup rv32i_opcode_cg;
    // All 40 RV32I instructions individually
    // TODO: fill in all 40 bins
endgroup

covergroup m_ext_cg;
    cp_m_op: coverpoint m_ext_opcode {
        bins mul    = {MUL};
        bins mulh   = {MULH};
        bins mulhu  = {MULHU};
        bins mulhsu = {MULHSU};
        bins div    = {DIV};
        bins divu   = {DIVU};
        bins rem    = {REM};
        bins remu   = {REMU};
    }
endgroup
```

### 6.2 Hazard Coverage (target: 100%)

| Coverage Point | Description | Bin |
|---------------|-------------|-----|
| raw_ex_ex_cg | EX→EX forwarding triggered | rs1_hazard, rs2_hazard |
| raw_mem_ex_cg | MEM→EX forwarding triggered | rs1_hazard, rs2_hazard |
| load_use_stall_cg | Load-use stall inserted | 1_bubble |
| branch_flush_cg | Branch taken, 2-cycle flush | taken_branch |
| double_hazard_cg | Two consecutive RAW hazards | a_to_b_to_c |

### 6.3 GEMM Accelerator Coverage (target: 100%)

| Coverage Point | Description | Bins |
|---------------|-------------|------|
| gemm_data_range_cg | INT8 input range | zero, max_pos(127), max_neg(-128), mixed |
| gemm_accumulation_cg | Accumulator near INT32 max | near_overflow |
| gemm_consecutive_runs_cg | Multiple back-to-back runs | 2_runs, 5_runs, 10_runs |
| gemm_read_during_busy_cg | BUF_C read while busy | during_compute |

---

## 7. Formal Verification Plan

### 7.1 SymbiYosys Targets

| File | Module | Properties | Method |
|------|--------|-----------|--------|
| cpu_pipeline.sby | hazard_unit + pipeline | A1–A6, A15–A16 | BMC (depth 20) + prove |
| gemm_ctrl_fsm.sby | gemm_ctrl_fsm | A11–A14 | BMC + prove |
| axi4_slave.sby | axi4_slave_if | A7–A10 | BMC |

### 7.2 Bounded Model Check Depth
- Pipeline assertions: depth=20 cycles (covers longest hazard chain)
- GEMM FSM: depth=16 cycles (covers full GEMM compute: 4+4+padding)
- AXI4 properties: depth=10 cycles

---

## 8. Coverage Closure Plan

### 8.1 Target Metrics

| Metric | Target | Method to Close Gaps |
|--------|--------|---------------------|
| Functional coverage | >90% | Targeted constrained-random sequences |
| Code coverage (line) | >85% | Analyze uncovered lines, write directed tests |
| Code coverage (toggle) | >80% | Corner-case sequences for stuck bits |
| FSM coverage | 100% | State-transition sequences |
| SVA assertion coverage | 100% | Each assertion must fire at least once |

### 8.2 Coverage Exclusion Policy
Any excluded coverage point must be documented in `docs/bug_tracker.md` with justification:
- Unreachable by design (e.g., illegal state in one-hot FSM)
- Not exercised due to scope (e.g., full AXI4 burst types — only INCR used)

---

## 9. Bug Tracking

All bugs found during verification are logged in `docs/bug_tracker.md`.

Format:
```
## BUG-XXX: [Short Title]
- **Found by:** [test name + UVM phase]
- **Symptom:** [what the test observed]
- **Root cause:** [which RTL module, signal, line]
- **Fix:** [what was changed in RTL]
- **Regression status:** [PASS/FAIL after fix]
```

---

## 10. Regression Infrastructure

```
scripts/run_regression.py
  --tests <list>       Tests to run (space-separated)
  --jobs N             Parallel VCS jobs
  --cov_dir DIR        Coverage output directory
  --report_dir DIR     HTML report output
```

Coverage merge: `vcover merge` on all per-test databases → `coverage_merged.vdb`
HTML report: `parse_coverage.py` reads VCS XML → `docs/coverage_report.html`

---

*This document is a living artifact. Update after each regression run.*
