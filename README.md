# RISC-V OoO SoC with Systolic Array Accelerator

A RISC-V out-of-order processor integrated with a 4x4 systolic array
accelerator, designed and verified from RTL through tape-in ready GDS.

## Overview

This project explores the architectural challenge of feeding a fixed-function
accelerator at full bandwidth when the working dataset exceeds on-chip memory
capacity. The SoC pairs a general-purpose RISC-V out-of-order core with an
8x8 weight-stationary systolic array accelerator, connected over an AXI4
interconnect, targeting fixed-kernel image convolution (blur/sharpen) on
1024x1024 images. The core directly accesses on-chip SRAM over AXI4 for
both instructions and data. The interesting design problems are in the memory
system — sizing the scratchpad, sustaining accelerator bandwidth, and
streaming image data row-by-row to avoid buffering the full image on-chip.


<p align="center">
  <img src="docs/architecture_diagram.png" alt="SoC Architecture" width="600">
</p>

## Components

| Block | Description |
|---|---|
| RISC-V OoO Core | RV32I, 16-entry ROB, 8-entry reservation stations, register renaming (RAT), bimodal branch predictor |
| Systolic Array | 8x8 INT8 PE grid, weight-stationary dataflow, AXI4-Stream interface |
| On-Chip SRAM | Single shared memory for instructions and data, IHP PDK macro, accessed directly over AXI4 |
| AXI4 Crossbar | 2 masters, 4 slaves, address-decoded routing with round-robin arbitration |

## Repository Structure

```
rtl/          — RTL design files
  core/       — RISC-V OoO core (fetch, decode, rename, issue, execute, commit)
  ai_acc/     — AI accelerator (PE array, weight controller, scratchpad, output buffer)
  interconnect/— AXI4 crossbar and APB bridge
tb/           — Verification environment
  unit/       — Standalone module testbenches (per-module sanity checks)
  env/        — Full UVM environment (agents, scoreboard, sequences, coverage)
docs/         — Architecture spec, DV plan, microarchitecture diagrams
```