# Bug Tracker — RV32IMC-GEMM SoC

> **Policy:** Every RTL bug found during verification must be logged here.
> Fields required: Bug ID, test that found it, root cause (module + signal), fix applied, regression status.
> This document is a first-class project deliverable.

---

## Bug Log

| ID | Title | Module | Found By | Status |
|----|-------|--------|----------|--------|
| — | *No bugs yet — Phase 1 RTL in progress* | — | — | — |

---

## Bug Template

Copy and fill in for each new bug:

```
## BUG-001: [Short descriptive title]

**Date found:** YYYY-MM-DD
**Found by:** [test name] in [UVM phase / directed test / formal]
**Severity:** Critical / Major / Minor

**Symptom:**
[What the scoreboard or assertion observed. Include signal values and waveform timestamp if relevant.]

**Root cause:**
- Module: `rtl/cpu/[module_name].sv`, line [N]
- Signal: `[signal_name]`
- Description: [What was wrong in the RTL logic]

**Fix:**
```diff
- [old RTL code]
+ [new RTL code]
```

**Regression status:** PASS ✅ / FAIL ❌ (after fix applied)

**Notes:** [Any additional context — spec citation, related signals, etc.]
```

---

*Last updated: Week 1 — pre-verification*
