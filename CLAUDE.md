# Humber

Coherent dual-core RV32IMA system on the DE1-SoC (Cyclone V). Personal
project, built on my own time and equipment from public specs only.
Full plan, stage list, decisions and reading list: @docs/context.md

## Current stage
Stage 0 (setup and spec). Update this line at every stopping point.

## Working agreement (most important section)
- I write the RTL. Do NOT write complete modules or testbenches unless I
  explicitly ask. Explain concepts, review my code, find bugs, propose
  tests, challenge design decisions.
- I must be able to explain every line. If a suggestion is non-obvious,
  explain why.
- Review checklist for RTL: reset behavior, synthesizability, latches,
  blocking vs nonblocking, width mismatches, combinational loops, and
  whether a test would actually catch the bug.
  For protocol logic also check every state x event pair, races, and
  what happens to an LR/SC reservation.
- Be honest about scope. If I'm behind the hour budget, say so and
  propose a cut. Enforce the stage-1 freeze rule (docs/context.md §4).
- Separate facts (with sources) from estimates and opinions.
- Never reproduce or suggest code from my employer or from course labs.
  Reference projects (§8 of context) are for ideas, not copying.

## Environment
- Claude Code runs in WSL2. Verilator, Spike, SymbiYosys, RISC-V GCC live here.
- Quartus and board programming run on Windows, in a separate clone.
  Don't try to run Quartus from WSL.
- Generated files never get committed (see .gitignore).

## Layout
Modeled on the public OFS layout (github.com/OFS/ofs-agx5-pcie-attach).
src/{core,cache,coherence,soc,top}  sim/  verification/  syn/  sw/  tools/  docs/
- src: RTL. sim: Verilator testbenches, unit tests, run scripts, Spike lockstep.
- verification: formal (SymbiYosys, riscv-formal), litmus tests, coverage.
- syn: Quartus project, .qsf/.sdc, DE1-SoC pin assignments.
One module per file; filename matches module name.

## Commands
<!-- Fill in as they come to exist. Don't guess commands that aren't here. -->
- Build sim:      TODO
- Run unit tests: TODO
- Run riscv-tests: TODO
- Spike lockstep: TODO
- Formal (riscv-formal): TODO
- Build sw:       `riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32 ...` (rv32ima from stage 2)

## Code conventions
- SystemVerilog. `always_ff` with nonblocking, `always_comb` with
  blocking. Active-low sync reset `rst_n` unless I say otherwise.
- No latches, no implicit nets (`default_nettype none` at top of each file).
- Parameters in UPPER_CASE, signals snake_case, `_q` for registered,
  `_d` for next-state, `_n` for active-low.
- Every module with state gets a reset test.

## Git
- Commit identity is my personal one (set per repo). Never change it.
- Small commits, branch per task, merge to main when CI is green.
- Never force-push main. Never commit: Quartus db/, incremental_db/,
  output_files/, generated qsys output, waveforms, obj_dir, .sof/.rbf.
- Bitstreams go on tagged releases (stage-1, stage-2, ...), not in the tree.
- Run `git status` and show me the diff before committing; I approve
  commit messages.

## Verification rules
- A change isn't done until the relevant check passes: riscv-tests and
  Spike lockstep for core changes; formal properties for protocol changes.
- Prefer measurements over opinions. Label every number: sim, synthesis,
  or board.
- When a test fails, find the root cause before touching the test.