#==============================================================================
# Makefile — RV32IMC-GEMM SoC Build System
# Tools: VCS (simulation), Verdi (waveform), SpyGlass/Verilator (lint),
#        SymbiYosys (formal), DC/Yosys (synthesis)
#
# Usage:
#   make lint          — Verilator lint check on all RTL
#   make compile       — VCS compile (elaboration)
#   make sim TEST=directed_cpu_test — run a specific test
#   make regress       — run full regression (Python script)
#   make formal        — run SymbiYosys formal checks
#   make clean         — remove build artifacts
#
# Authors : Student 1 (DV) + Student 2 (RTL)
# Project : RV32IMC-GEMM SoC
#==============================================================================

#------------------------------------------------------------------------------
# Tool configuration — update paths for your environment
#------------------------------------------------------------------------------
VCS       := vcs
VERDI     := verdi
VERILATOR := verilator
SBY       := sby
PYTHON    := python3

#------------------------------------------------------------------------------
# Directory structure
#------------------------------------------------------------------------------
RTL_DIR     := ../rtl
TB_DIR      := ../tb
FORMAL_DIR  := ../formal
SCRIPTS_DIR := .

INC_DIR     := $(RTL_DIR)/include
CPU_DIR     := $(RTL_DIR)/cpu
GEMM_DIR    := $(RTL_DIR)/gemm
SOC_DIR     := $(RTL_DIR)/soc

BUILD_DIR   := ./build
WAVE_DIR    := ./waves
COV_DIR     := ./coverage

#------------------------------------------------------------------------------
# RTL source file lists
#------------------------------------------------------------------------------
RTL_INCS := \
    $(INC_DIR)/rv32_defines.svh \
    $(INC_DIR)/axi4_defines.svh

RTL_CPU := \
    $(CPU_DIR)/reg_file.sv \
    $(CPU_DIR)/alu.sv \
    $(CPU_DIR)/mul_div_unit.sv \
    $(CPU_DIR)/csr_regfile.sv \
    $(CPU_DIR)/hazard_unit.sv \
    $(CPU_DIR)/if_stage.sv \
    $(CPU_DIR)/id_stage.sv \
    $(CPU_DIR)/ex_stage.sv \
    $(CPU_DIR)/mem_stage.sv \
    $(CPU_DIR)/wb_stage.sv \
    $(CPU_DIR)/rv32imc_core.sv

RTL_GEMM := \
    $(GEMM_DIR)/pe_cell.sv \
    $(GEMM_DIR)/pe_array_4x4.sv \
    $(GEMM_DIR)/input_buffer.sv \
    $(GEMM_DIR)/output_buffer.sv \
    $(GEMM_DIR)/gemm_ctrl_fsm.sv \
    $(GEMM_DIR)/axi4_slave_if.sv \
    $(GEMM_DIR)/gemm_accelerator.sv

RTL_SOC := \
    $(SOC_DIR)/sram_model.sv \
    $(SOC_DIR)/axi4_interconnect.sv \
    $(SOC_DIR)/riscv_gemm_soc.sv

RTL_ALL := $(RTL_CPU) $(RTL_GEMM) $(RTL_SOC)

TB_ENV := \
    $(TB_DIR)/env/soc_env.sv \
    $(TB_DIR)/env/cpu_scoreboard.sv \
    $(TB_DIR)/env/gemm_scoreboard.sv \
    $(TB_DIR)/env/coverage_collector.sv

TB_AGENTS := \
    $(TB_DIR)/agents/instr_agent/instr_agent.sv \
    $(TB_DIR)/agents/data_agent/data_agent.sv

TB_SEQS := \
    $(TB_DIR)/sequences/rv32imc_instr_seq.sv \
    $(TB_DIR)/sequences/hazard_seq.sv \
    $(TB_DIR)/sequences/exception_seq.sv \
    $(TB_DIR)/sequences/gemm_seq.sv

#------------------------------------------------------------------------------
# Default test
#------------------------------------------------------------------------------
TEST     ?= directed_cpu_test
TOP_TB   := $(TB_DIR)/tests/$(TEST).sv

#------------------------------------------------------------------------------
# VCS flags
#------------------------------------------------------------------------------
VCS_FLAGS := \
    -full64 \
    -sverilog \
    -timescale=1ns/1ps \
    -ntb_opts uvm-1.2 \
    +incdir+$(INC_DIR) \
    +incdir+$(TB_DIR)/env \
    +incdir+$(TB_DIR)/agents/instr_agent \
    +incdir+$(TB_DIR)/agents/data_agent \
    +incdir+$(TB_DIR)/sequences \
    -cm line+cond+fsm+branch+tgl \
    -cm_dir $(COV_DIR)/$(TEST) \
    +define+SIMULATION \
    -debug_access+all \
    -kdb

# Formal: enable SVA elaboration
VCS_FORMAL_FLAGS := $(VCS_FLAGS) +define+FORMAL_EN

#------------------------------------------------------------------------------
# Targets
#------------------------------------------------------------------------------

.PHONY: all lint compile sim wave regress formal clean help

all: compile

## Verilator lint — fast, no license required
lint:
	@echo "=== Running Verilator lint ==="
	$(VERILATOR) --lint-only -sv \
	    +incdir+$(INC_DIR) \
	    $(RTL_ALL) \
	    2>&1 | tee $(BUILD_DIR)/lint.log
	@echo "=== Lint done — see build/lint.log ==="

## VCS compilation + elaboration
compile: $(BUILD_DIR)/.compile_done

$(BUILD_DIR)/.compile_done: $(RTL_ALL) $(TB_ENV) $(TB_AGENTS) $(TB_SEQS) $(TOP_TB)
	@mkdir -p $(BUILD_DIR) $(WAVE_DIR) $(COV_DIR)
	@echo "=== VCS Compile: TEST=$(TEST) ==="
	$(VCS) $(VCS_FLAGS) \
	    $(RTL_ALL) \
	    $(TB_ENV) $(TB_AGENTS) $(TB_SEQS) \
	    $(TOP_TB) \
	    -o $(BUILD_DIR)/simv_$(TEST)
	@touch $@
	@echo "=== Compile done ==="

## Run simulation
sim: compile
	@echo "=== Running simulation: TEST=$(TEST) ==="
	$(BUILD_DIR)/simv_$(TEST) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=UVM_MEDIUM \
	    -cm line+cond+fsm+branch+tgl \
	    -cm_dir $(COV_DIR)/$(TEST) \
	    -ucli -do $(SCRIPTS_DIR)/wave.tcl \
	    2>&1 | tee $(BUILD_DIR)/$(TEST).log

## Open waveform in Verdi
wave:
	$(VERDI) -sv \
	    +incdir+$(INC_DIR) \
	    $(RTL_ALL) \
	    -ssf $(WAVE_DIR)/$(TEST).fsdb &

## Full regression (Python script handles parallel runs + coverage merge)
regress:
	@echo "=== Running full regression ==="
	$(PYTHON) $(SCRIPTS_DIR)/run_regression.py \
	    --tests directed_cpu_test random_cpu_test directed_gemm_test \
	            random_gemm_test soc_integration_test \
	    --jobs 4 \
	    --cov_dir $(COV_DIR) \
	    --report_dir ../docs

## SymbiYosys formal verification
formal:
	@echo "=== Running formal verification ==="
	cd $(FORMAL_DIR) && $(SBY) -f cpu_pipeline.sby
	cd $(FORMAL_DIR) && $(SBY) -f gemm_ctrl_fsm.sby
	cd $(FORMAL_DIR) && $(SBY) -f axi4_slave.sby

## Clean build artifacts
clean:
	rm -rf $(BUILD_DIR) $(WAVE_DIR) $(COV_DIR)
	rm -rf csrc DVEfiles simv* ucli.key vc_hdrs.h
	rm -rf AN.DB novas_dump* verdi_config_file
	find . -name "*.log" -delete
	@echo "=== Clean done ==="

## Help
help:
	@echo ""
	@echo "RV32IMC-GEMM SoC Build System"
	@echo "------------------------------"
	@echo "  make lint              — Verilator lint (no license needed)"
	@echo "  make compile           — VCS compile (default TEST=directed_cpu_test)"
	@echo "  make sim TEST=<name>   — Run simulation"
	@echo "  make wave TEST=<name>  — Open Verdi waveform"
	@echo "  make regress           — Full regression + coverage"
	@echo "  make formal            — SymbiYosys formal checks"
	@echo "  make clean             — Remove all build artifacts"
	@echo ""
	@echo "Available tests:"
	@echo "  directed_cpu_test      — All RV32IMC instructions, directed"
	@echo "  random_cpu_test        — Constrained-random 100k+ instruction streams"
	@echo "  directed_gemm_test     — GEMM accelerator directed tests"
	@echo "  random_gemm_test       — 1000+ random INT8 matrix pairs"
	@echo "  soc_integration_test   — CPU programs GEMM end-to-end"
	@echo ""

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)
