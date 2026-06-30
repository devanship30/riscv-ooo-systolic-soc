# RV32IMC-GEMM SoC — Microarchitecture Specification
**Student 2 (RTL) — UPenn, Masters in Computer Engineering**
**Revision:** 0.1 — Week 1 skeleton

---

## 1. Overview

This document specifies the microarchitecture of the RV32IMC-GEMM SoC.
It is the authoritative reference for RTL implementation and serves as the contract between RTL and DV.

---

## 2. CPU Pipeline — 5-Stage RV32IMC

### 2.1 Pipeline Diagram

```
Cycle:  1    2    3    4    5    6    7    8
Instr1: IF   ID   EX   MEM  WB
Instr2:      IF   ID   EX   MEM  WB
Instr3:           IF   ID   EX   MEM  WB
```

### 2.2 Stage Descriptions

#### IF — Instruction Fetch
- **PC register:** 32-bit, reset to `0x8000_0000`
- **Instruction fetch:** AXI4-Lite read to shared SRAM
- **RVC detection:** bits[1:0] ≠ 2'b11 → 16-bit compressed instruction
- **Next-PC sources:** PC+4 (32b), PC+2 (RVC), branch target, JALR target, mtvec (exception)

**TODO: fill in AXI4-Lite handshake timing**

#### ID — Instruction Decode
- **Decoder:** full RV32IMC, all 6 immediate formats
- **Register file:** 32×32, 2 async read ports, 1 sync write port
- **RVC expansion:** 16-bit → 32-bit equivalent (8 instruction subset)

**TODO: fill in decoder truth table**

#### EX — Execute
- **ALU:** all RV32I operations (ADD/SUB/AND/OR/XOR/SLL/SRL/SRA/SLT/SLTU/LUI/AUIPC)
- **MUL/DIV unit:** M-extension, multi-cycle (MUL: 1 cycle, DIV: 32 cycles)
- **Branch comparator:** BEQ/BNE/BLT/BGE/BLTU/BGEU
- **Forwarding muxes:** EX→EX and MEM→EX (driven by hazard unit)
- **CSR path:** read-modify-write to CSR register file

#### MEM — Memory Access
- **AXI4 master:** full AXI4 with WSTRB for sub-word stores
- **Byte enables:** SB → 1-byte, SH → 2-byte, SW → 4-byte
- **Load extension:** LB/LBU/LH/LHU/LW sign/zero extension
- **Misalignment:** raises exception → mepc, mcause update

#### WB — Writeback
- **Source mux:** ALU result / load data / PC+4
- **Register file write:** synchronized, x0 permanently 0

### 2.3 Hazard Unit

**TODO: fill in forwarding conditions table**

| Hazard Type | Detection Condition | Action |
|-------------|--------------------|---------
| EX→EX RAW | EX/MEM.rd == ID/EX.rs1 and EX/MEM.wen | Forward EX/MEM result to EX operand A |
| EX→EX RAW | EX/MEM.rd == ID/EX.rs2 and EX/MEM.wen | Forward EX/MEM result to EX operand B |
| MEM→EX RAW | MEM/WB.rd == ID/EX.rs1 and MEM/WB.wen | Forward MEM/WB result to EX operand A |
| MEM→EX RAW | MEM/WB.rd == ID/EX.rs2 and MEM/WB.wen | Forward MEM/WB result to EX operand B |
| Load-use | EX/MEM.mem_read and EX/MEM.rd == IF/ID.rs1 or rs2 | Stall IF+ID, insert 1 bubble |
| Branch taken | branch_taken from EX | Flush IF+ID (2 bubbles) |
| Exception | ex_exception or mem_exception | Flush IF+ID+EX, redirect to mtvec |

### 2.4 CSR Registers

| CSR | Address | Reset | Description |
|-----|---------|-------|-------------|
| mstatus | 0x300 | 0x0 | MIE, MPIE (minimal) |
| misa | 0x301 | 0x4001_0104 | RV32IMC read-only |
| mie | 0x304 | 0x0 | Interrupt enable |
| mtvec | 0x305 | 0x0 | Trap vector (must be programmed by firmware) |
| mscratch | 0x340 | 0x0 | Scratch |
| mepc | 0x341 | 0x0 | Exception PC |
| mcause | 0x342 | 0x0 | Exception cause |
| mtval | 0x343 | 0x0 | Trap value (bad address) |
| mip | 0x344 | 0x0 | Interrupt pending (read-only) |
| mhartid | 0xF14 | 0x0 | Hart ID (read-only, = 0) |

---

## 3. GEMM Accelerator

### 3.1 PE Array

**TODO: Student 2 fills in timing diagram for output-stationary dataflow**

- Array: 4×4 PEs
- Each PE: `acc_int32 += a_int8 × b_int8` per cycle
- A feeds left→right (staggered by row)
- B feeds top→bottom (staggered by column)
- Latency: 4 (fill) + 4 (compute) = ~8 cycles

### 3.2 FSM

```
IDLE ──(start=1)──► LOAD ──(load_done)──► COMPUTE ──(compute_done)──► DONE
 ▲                                                                       │
 └───────────────────────────────────────────────────────────────────────┘
                              (STATUS read / next start)
```

**States:**
- `IDLE`: waiting for CTRL[start]=1
- `LOAD`: shift matrix data into PE array (feed pipeline)
- `COMPUTE`: accumulate K cycles
- `DONE`: set STATUS[done]=1, hold result until next start

### 3.3 AXI4 Slave Timing

**TODO: Student 2 fills in AXI4 read/write transaction timing for control registers**

---

## 4. AXI4 Interconnect

- Topology: 1 master (CPU), 2 slaves (SRAM, GEMM)
- Routing: by address — 0x8000_0000 → SRAM, 0xC000_0000 → GEMM
- No out-of-order: simple priority or round-robin arbitration
- DECERR response if address hits no slave

---

## 5. Open Items

- [ ] AXI4-Lite fetch handshake FSM (IF stage)
- [ ] RVC expansion logic (ID stage)
- [ ] AXI4 write FSM (MEM stage) — AW and W channel ordering
- [ ] MUL/DIV stall handshake (EX stage ↔ hazard unit)
- [ ] MRET instruction handling (decoder + CSR)
- [ ] mtvec vectored mode (currently only direct mode supported)
- [ ] Synthesis: report critical path after Week 4

---

*This document should be complete by end of Week 2.*
