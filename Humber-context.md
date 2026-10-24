# Humber: project context

*A coherent dual-core RISC-V system on the DE1-SoC. Last updated: 2026-10-23. This replaces the earlier plans (Context.pdf and Tiller-context.md). Keep this file current: update the status log, decisions and open questions as the project moves.*

---

## 0. How to use this file

This is the standing context for a personal project. Any assistant helping on it should read it first and follow the working agreement in §14. The plan is in §4, the concepts each stage needs in §6, readings in §7, reference projects in §8, and the verification strategy in §10.

---

## 1. About me

- **Who:** Justin, Electrical and Computer Engineering student at the University of Toronto, on a 16-month FPGA Hardware Design internship at Altera (May 2026 – about Aug 2027).
- **Day job:** Higher-level RTL in Verilog/SystemVerilog around communication protocols and IP integration (PCIe, Ethernet, EMIF), Linux kernel drivers, and full hardware/software reference designs for Agilex 5.
- **Background:** Coursework in digital design (Verilog/SystemVerilog, FSMs, fixed-point arithmetic), CMOS VLSI, computer organization, algorithms, embedded systems (STM32, ESP32). Former head of electronics on a UofT design team (PCB design in KiCad, CAN, firmware).
- **Hardware I own:** Terasic DE1-SoC: Cyclone V SoC 5CSEMA5F31C6, 85K logic elements (about 32K ALMs), 4,450 Kbits of on-chip memory (M10K blocks), 87 DSP blocks, 64 MB SDRAM on the FPGA side, 1 GB DDR3 on the ARM side, dual-core Cortex-A9.
- **Time budget:** About 10–12 hours a week on the project plus 2–3 hours of interview prep, on top of a full-time job. Two weeknight sessions of 2–3 hours and one weekend block of 5–6 hours. A light week every six weeks or so.

## 2. Goal

Become a strong candidate for **new-grad RTL design and design-verification roles at chip companies** (NVIDIA, Apple, AMD, Tenstorrent, Qualcomm, Etched, Google TPU and similar). Trading-firm FPGA work is a possible later project.

**Why this project.**
- "RISC-V core in Verilog" is the most common hardware project on LinkedIn, and most are five-stage, in-order and simulation-only. A core alone won't stand out, so here **the core is the foundation and the memory system is the headline**.
- Cache coherence and memory ordering are among the hardest things chip companies design and verify. Memory-subsystem teams hire heavily.
- Coherence is a protocol problem, and protocols are what I do at work (PCIe, Ethernet). This builds on my strength instead of starting from zero.
- It also covers what postings ask for:

| What postings ask for | Example | How Humber shows it |
| --- | --- | --- |
| Microarchitecture | Etched RTL intern: microarchitecture, SV/UVM/Python | Pipelined core, write-back caches, MESI snooping protocol, LR/SC reservations |
| Verification | Tenstorrent DV intern: UVM, cocotb, formal, coverage | riscv-formal, Spike lockstep, formal protocol invariants, litmus tests, mutation testing |
| Real hardware and timing | NVIDIA ASIC new grad: high-frequency, low-power design | Two coherent cores running on the DE1-SoC; Fmax and the timing cost of coherence logic |

It doubles as interview prep: pipelines, hazards, caches, coherence and memory consistency are standard interview topics.

## 3. The project

**Humber: two of my own in-order RISC-V cores sharing memory correctly, through write-back caches and a coherence protocol I design, running on the DE1-SoC.**

**Naming:** the project and the single core are both **Humber**, after the Humber River where I paddle. The dual-core system gets its own name when stage 3 starts (candidate: **Undercurrent**, after the Bill Evans / Jim Hall duo album). Until then it's "the dual-core system".

### 3.1 Target system (end of stage 4)

- **Cores:** two copies of my 5-stage in-order **RV32IMA** core (Humber), machine mode only. CSRs for benchmarking and traps (`mcycle`, `minstret`, `mhartid`, `mtvec`, `mepc`, `mcause`), plus `FENCE` and `FENCE.I`.
- **Private L1 caches per core:**
  - I-cache: read-only; `FENCE.I` invalidates it.
  - D-cache: write-back, write-allocate, direct-mapped to start (2-way stretch), 16-byte lines, a few KB each in M10K. Blocking: one miss at a time.
- **Coherence:** snooping over a shared **atomic bus** (one transaction at a time) with a round-robin arbiter. MSI first, then MESI.
- **Atomics:**
  - `LR.W`/`SC.W` with one reservation per core, at cache-line granularity. The reservation clears when the line is invalidated or evicted, or on the core's own `SC`.
  - AMOs execute in the L1 while the line is held in M state.
- **Memory model:** blocking in-order cores with no store buffer behave as sequentially consistent (SC). That's stronger than RISC-V's RVWMO model, so it's allowed. Optional stage-4 extension: add a store buffer so the "store buffering" litmus test shows a relaxed outcome without a fence and an SC outcome with one.
- **Shared memory:** on-chip M10K behind a simple memory controller first; the 64 MB SDRAM is a stretch goal.
- **System:**
  - The ARM side (HPS) loads programs into shared memory over the lightweight HPS-to-FPGA bridge, releases both cores from reset, and reads results and counters back.
  - Software tells the cores apart with `mhartid`.
  - A memory-mapped console prints output.
- **Performance counters:** per core cycles and instructions retired, L1 hits and misses, bus transactions, invalidations, writebacks, and SC failures.

### 3.2 What makes it original

Coherent multicore systems exist in academia (BlackParrot, OpenPiton), but they're rare as personal projects. The standout parts:
- my own core, caches and protocol, end to end
- **formal proofs of the protocol's core rules**
- **the official RISC-V memory-model litmus tests running on real hardware**, with outcome histograms
- a **measured MSI-vs-MESI comparison** on the same workloads

### 3.3 The numbers the project should end with

- CoreMark/MHz and Fmax of one core; the Fmax cost of adding caches and coherence
- Speedup of two cores over one on parallel workloads (parallel sum, matrix multiply, producer–consumer)
- L1 hit rates; bus transactions per 1,000 instructions; **bus traffic saved by MESI vs MSI**
- Litmus tests: number of tests × runs on hardware, outcome histograms, **zero forbidden outcomes**
- Formal: the protocol invariants proven (single-writer/multiple-reader, data-value), with depth or induction
- Lock throughput under contention: LR/SC-based lock vs `AMOSWAP` lock

**Target résumé entry** (fill the brackets with measured numbers):

```
Humber: Coherent Dual-Core RISC-V System                              [dates]
SystemVerilog, C, Python, Verilator, SymbiYosys, Quartus              [GitHub]
• Designed two 5-stage RV32IMA cores with write-back L1 caches and a MESI snooping
  protocol with LR/SC reservations, running on a Cyclone V (DE1-SoC) at [Y] MHz
• Formally proved the protocol's single-writer and data-value invariants; verified
  each core with riscv-formal and lockstep co-simulation against Spike
• Ran [N] RISC-V memory-model litmus tests on hardware ([M] runs each) with zero
  forbidden outcomes; mutation testing caught [K]/[K] planted coherence bugs
• Measured [X]× two-core speedup; MESI cut bus traffic [Z]% vs MSI
```

## 4. Plan and milestones

Each stage ends at a **stopping point**: something finished and presentable if the project has to stop there. Hours assume 10–12 hours a week; first projects overrun, so plan to the low end of scope.

| Stage | Target date | Cumulative hours | Deliverable (stopping point) |
| --- | --- | --- | --- |
| 0. Setup and spec | Nov 1, 2026 | ~10 | Toolchain installed; one-page spec; manager conversation done |
| 1. Quick core | Jan 10, 2027 | ~90 | 5-stage RV32IM passing riscv-tests and riscv-arch-test, Spike lockstep and riscv-formal in CI; running CoreMark on the DE1-SoC, loaded from the HPS |
| 2. Caches and atomics (one core) | Feb 14, 2027 | ~140 | Write-back L1 I/D caches, A extension (LR/SC, AMOs), `FENCE`/`FENCE.I`; Spike lockstep still passing with caches on |
| 3. Two coherent cores | Apr 25, 2027 | ~260 | Snooping bus, MSI then MESI; formal protocol invariants; multicore stress tests; litmus tests on hardware; spinlock demo |
| 4. Measure and write up | May 31, 2027 | ~310 | MSI-vs-MESI traffic, speedups, lock comparison; optional store buffer + fence demo; README, results, write-up |

**Freeze rule for stage 1:** the core is a means, not the goal. If it's still dragging at week 10 (around Jan 10), freeze it at whatever passes the tests and move on. No out-of-order, no branch predictor beyond static not-taken, no caches in stage 1.

**After May (optional, pick one):**
- **Predictor study:** build gshare and TAGE in RTL, prove they match the CBP-NG C++ model bit-exact, and compare OpenROAD costs with the championship's HARCOM cost model. Plugs into Humber's fetch stage.
- **Scale up:** 4 cores with a directory protocol, or a split-transaction bus.
- An out-of-order version of the core.
- The trading-firm project (line-rate market-data engine on a 10G board).
- The single core on a Tiny Tapeout shuttle (TTGF27a ~April 2027, TTSKY27a ~May 2027).

### Week-1 checklist

- [ ] Tell my manager about the project. Altera ships its own RISC-V soft core (Nios V), so it's in the same product category. Confirm my agreement's IP and outside-work terms. Use only my own time, equipment and public material. Write everything from public sources and never reuse or mirror work code.
- [ ] Install the toolchain (§9) and run Spike on a hello-world.
- [ ] Read the riscv-formal README and the RVFI spec.
- [ ] Write the one-page spec: ISA subset, pipeline diagram, memory map (including where shared memory, the console and counters live), target Fmax, verification plan.
- [ ] Rough M10K budget: two cores' register files, two L1 I/D pairs, shared memory. Confirm it fits the DE1-SoC.

## 5. Decisions made

| Decision | Chosen | Rejected, and why |
| --- | --- | --- |
| Headline | Coherent dual-core memory system | **Out-of-order core first:** months of work, and "RISC-V core" is the most crowded project category. **MiniHLS-style compiler:** mostly software, and a UofT peer is doing it. **Tiny TPU:** crowded on this exact board. |
| Order | Quick in-order core, then caches, then coherence | Coherence on someone else's core: owning the whole stack is the better story, and the core doubles as interview prep. |
| Alternative original project | Predictor study (CBP-NG cost model vs RTL), kept as the post-May option | n/a |
| Protocol style | Snooping on an atomic bus | **Directory:** unnecessary for 2 cores (broadcast is cheap); a stretch for 4 cores. **Split-transaction bus:** many more transient states and races; a stretch. |
| Protocol order | MSI, then MESI | Starting with MESI: harder to debug, and MSI gives the baseline for the traffic comparison. |
| Memory model | SC by construction (no store buffer); store buffer optional later | A relaxed design from day one: verification gets much harder before anything works. |
| Shared memory | On-chip M10K first | SDRAM first: adds a controller and latency before the protocol works. |
| Name | Humber (the Humber River, where I paddle); dual-core name decided at stage 3 (candidate: Undercurrent) | RiskV: search engines "correct" it to RISC-V. Tiller, Sunnyside, Ares and others: considered and dropped. |
| Target employers | Chip companies (RTL and DV) | Trading firms: possible later project. |

## 6. Concepts to learn, by stage

Learn just in time: each list is what the stage needs.

### Stage 0–1: the quick core

- **ISA:** RV32I/M formats and immediates; M-extension corner cases (divide by zero, signed overflow of `DIV`/`REM`, `MULH*`); minimal machine-mode CSRs and trap flow; `ecall`/`ebreak` for ending tests.
- **Pipelining:** 5-stage datapath; forwarding paths; load-use stall; branch resolution and flushing; structural hazards from a multi-cycle divider.
- **FPGA memory:** M10K synchronous read latency, read-during-write behavior, byte enables, `$readmemh`; DSP inference for the multiplier.
- **Toolchain:** `riscv64-unknown-elf-gcc -march=rv32im -mabi=ilp32`; linker scripts; minimal `crt0`; `objcopy` to hex.
- **Verification:**
  - RVFI and the riscv-formal checks.
  - SymbiYosys (bounded model checking, k-induction).
  - Lockstep co-simulation with Spike.
  - riscv-tests and riscv-arch-test (RISCOF).
  - CI (GitHub Actions); mutation testing.
- **On the board:**
  - Quartus constraints (SDC), PLLs, the Timing Analyzer and critical paths.
  - Platform Designer, Avalon-MM, and the lightweight HPS-to-FPGA bridge; loading memory from Linux (`mmap` of `/dev/mem`); reset control.
  - CoreMark porting (`core_portme`, timing via `mcycle`).

### Stage 2: caches and atomics (one core)

- **Cache organization:** sets, tags, offsets; direct-mapped vs set-associative; write-back with dirty bits; write-allocate; replacement.
- **Cache timing on FPGA:** tag and data arrays in M10K with synchronous reads, so the tag check moves a cycle; hit/miss pipelining; stalling the pipeline on a miss.
- **Miss handling:** refill and writeback state machines; a simple memory bus with valid/ready handshakes.
- **Instruction cache:** coherence with stores via `FENCE.I`; why self-modifying code needs it.
- **A extension:** `LR.W`/`SC.W` semantics (reservation set, SC failure codes, the constrained-loop forward-progress rule); AMOs; the `aq`/`rl` bits; misaligned atomics trap.
- **Checking:** with one core, Spike lockstep still works with caches on, so cache bugs show up as architectural mismatches.

### Stage 3: two coherent cores

- **Coherence fundamentals:** the single-writer/multiple-reader (SWMR) invariant and the data-value invariant.
- **Snooping protocols:** bus transactions (read, read-exclusive, upgrade, writeback).
  - MSI and MESI state machines, including transient states.
  - What the E state buys (silent upgrade on a private write).
- **Bus and arbitration:** atomic bus, round-robin arbitration, fairness and starvation.
- **Snoop logic:** the core and the snooper both need the tag array (dual-port M10K or a duplicate tag copy); writeback when another core requests a line held in M.
- **Races:** two cores upgrading the same line at once; snoops arriving mid-refill. An atomic bus removes most of these by design.
- **Atomics across cores:** invalidation clears the reservation; AMOs hold the line in M for the read-modify-write; livelock and forward progress.
- **Memory consistency:**
  - Sequential consistency, TSO and RVWMO.
  - Why blocking in-order cores without a store buffer are SC.
- **Litmus tests:**
  - The classic shapes: MP (message passing), SB (store buffering), LB, IRIW, CoRR, 2+2W.
  - Allowed vs forbidden outcomes, computed with herd7.
  - Harness design: synchronized start, randomized delays, many iterations, outcome histograms.
- **Formal on the protocol:** a small configuration (2 caches, 1–2 lines) with SWMR and data-value properties, plus bounded liveness.

### Stage 4: measurement and extensions

- **Performance counters and experiments:**
  - false sharing
  - MSI vs MESI traffic
  - speedup and Amdahl's law
  - spinlocks: test-and-set, test-and-test-and-set, LR/SC vs `AMOSWAP`
- **Optional store buffer:**
  - Store-to-load forwarding from your own buffer.
  - `FENCE` draining it.
  - Observing the relaxed SB outcome, and seeing the fence remove it.

## 7. Reading list

**Priority key:** ★ read in full · ◆ read the named chapters · ○ reference / deep dive

### Books

- ★ Vijay Nagarajan, Daniel J. Sorin, Mark D. Hill and David A. Wood, *A Primer on Memory Consistency and Cache Coherence*, 2nd ed. (2020). **Free, open access** ([listing](https://library.oapen.org/handle/20.500.12657/61248); download from [Springer](https://link.springer.com/10.1007/978-3-031-01764-3)). The main text for stage 3: consistency (SC, TSO, relaxed), coherence basics, snooping protocols.
- ◆ David Harris and Sarah Harris, *Digital Design and Computer Architecture: RISC-V Edition* (2021). Ch. 7 (microarchitecture) for stage 1; ch. 8 (memory systems) for stage 2.
- ◆ David Patterson and John Hennessy, *Computer Organization and Design: RISC-V Edition* (2nd ed.). Ch. 4 (processor); ch. 5 (memory hierarchy, including its cache-coherence section); the synchronization section of ch. 2 (`lr`/`sc`).
- ◆ John Hennessy and David Patterson, *Computer Architecture: A Quantitative Approach* (7th ed., 2025). Appendix C (pipelining), the memory-hierarchy chapter, and the thread-level-parallelism chapter (coherence, synchronization, consistency).
- ○ Stuart Sutherland et al., *SystemVerilog for Design*; Chris Spear and Greg Tumbush, *SystemVerilog for Verification*.
- ○ David Patterson and Andrew Waterman, *The RISC-V Reader*.
- ○ John P. Shen and Mikko H. Lipasti, *Modern Processor Design* (2005), only if the out-of-order option comes later.

### Specifications

- ★ [RISC-V ISA manuals](https://github.com/riscv/riscv-isa-manual): RV32I, M, **A**, Zifencei, and the **RVWMO memory model** with its [explanatory appendix](https://docs.riscv.org/reference/isa/unpriv/mm-eplan.html).
- ★ [RVFI, the RISC-V Formal Interface](https://yosyshq.readthedocs.io/projects/riscv-formal/en/latest/rvfi.html).
- ◆ [TileLink specification 1.8.1](https://starfivetech.com/uploads/tilelink_spec_1.8.1.pdf), the TL-C (cached) chapters: a real industrial coherence protocol written as a bus spec. It reads naturally coming from PCIe.

### Papers, in reading order

1. ★ L. Lamport, "How to Make a Multiprocessor Computer That Correctly Executes Multiprocess Programs," *IEEE Trans. Computers*, 1979. The definition of sequential consistency (2 pages).
2. ★ S. V. Adve and K. Gharachorloo, ["Shared Memory Consistency Models: A Tutorial,"](https://www.csl.cornell.edu/courses/ece5750/adve.tr95.pdf) DEC WRL TR 95/7 (IEEE Computer, 1996).
3. ★ M. S. Papamarcos and J. H. Patel, "A Low-Overhead Coherence Solution for Multiprocessors with Private Cache Memories," ISCA 1984. The MESI ("Illinois") protocol.
4. ◆ J. Alglave, L. Maranget and M. Tautschnig, "Herding Cats: Modelling, Simulation, Testing, and Data Mining for Weak Memory," *ACM TOPLAS*, 2014. The model behind herd7 and the litmus tests.
5. ◆ Y. A. Manerkar et al., ["RTLCheck: Verifying the Memory Consistency of RTL Designs,"](https://mrmgroup.cs.princeton.edu/papers/MICRO-50_Manerkar.pdf) MICRO 2017. Turns litmus tests into SVA properties on a small multicore RISC-V: the closest research to stage 3.
6. ◆ [The BlackParrot BedRock Cache Coherence System](https://arxiv.org/pdf/2211.06390) (2022). How an open, real coherent RISC-V multicore organizes its protocol.
7. ○ D. Lustig, M. Pellauer and M. Martonosi, "PipeCheck: Specifying and Verifying Microarchitectural Enforcement of Memory Consistency Models," MICRO 2014.

### Lectures and courses

- ★ [Onur Mutlu's computer architecture lectures](https://www.youtube.com/@OnurMutluLectures): pipelining, caches, coherence, consistency.
- ◆ CMU 15-418/618 (Parallel Computer Architecture and Programming): lectures on snooping coherence, memory consistency and synchronization; slides are on the public course site.
- ◆ [UC Berkeley CS152](https://inst.eecs.berkeley.edu/~cs152/): caches and multiprocessor lectures.
- ○ UofT ECE552 (Computer Architecture) in fourth year covers the same ideas in C simulators. It reinforces the project rather than repeating it. Keep course lab code out of the public repo.

### Verification and tools

- ★ [riscv-formal documentation](https://yosyshq.readthedocs.io/projects/riscv-formal/en/latest/)
- ★ [ZipCPU blog](https://zipcpu.com/): formal verification tutorials with SymbiYosys.
- ◆ [Ibex co-simulation with Spike](https://ibex-core.readthedocs.io/en/latest/03_reference/cosim.html): the industrial pattern for lockstep checking.
- ◆ [litmus-tests-riscv](https://github.com/litmus-tests/litmus-tests-riscv) and [herdtools7](https://github.com/herd/herdtools7) (herd7 computes the allowed outcomes).
- ◆ [Verilator manual](https://verilator.org/guide/latest/): version 5.050 added covergroups; 5.052 (Sept 2026) supports UVM 2020-3.2 with limitations.
- ○ [riscv-dv](https://github.com/chipsalliance/riscv-dv) for random single-core programs; [cocotb](https://github.com/cocotb/cocotb) for unit tests.
- ○ Cliff Cummings' Sunburst Design papers on nonblocking assignments and clock-domain crossing.

### FPGA and board

- ◆ DE1-SoC User Manual (Terasic) and the Cyclone V HPS Technical Reference Manual (HPS–FPGA bridges chapter).
- ○ Altera FPGA University Program "DE1-SoC Computer System" docs, as a ready-made HPS and bridges reference.

## 8. Reference projects

Study these for structure and ideas. Don't copy code: I need to own and explain every line.

| Project | Language | Study it for |
| --- | --- | --- |
| [biRISC-V](https://github.com/ultraembedded/biriscv) | Verilog | Clean in-order pipeline structure for stage 1 |
| [Ibex](https://github.com/lowRISC/ibex) | SystemVerilog | Industrial-quality small core and its Spike co-simulation flow |
| [Hazard3](https://github.com/Wren6991/Hazard3) | Verilog | Small, clean core (shipped in Raspberry Pi's RP2350), including its A-extension implementation |
| [raptor-chip](https://github.com/Kingfish404/raptor-chip) | SystemVerilog | Best verification template found: RISCOF, difftest, RVFI, SVA, fuzzing in CI |
| [learn-fpga / FemtoRV](https://github.com/BrunoLevy/learn-fpga) | Verilog | Step-by-step core building |
| [BlackParrot](https://github.com/black-parrot/black-parrot) | SystemVerilog | Open coherent RISC-V multicore; BedRock protocol organization |
| [OpenPiton](https://github.com/PrincetonUniversity/openpiton) | Verilog | Open manycore with directory coherence (P-Mesh); for the post-May 4-core option |
| [RTLCheck](https://github.com/ymanerka/rtlcheck) | SV / tools | Litmus tests as SVA properties on a small multicore RISC-V |
| [VexRiscv](https://github.com/SpinalHDL/VexRiscv) | SpinalHDL | SMP configurations with coherent data caches |
| [Rocket Chip](https://github.com/chipsalliance/rocket-chip) | Chisel | TileLink coherence in a production-grade design |
| [litmus-tests-riscv](https://github.com/litmus-tests/litmus-tests-riscv) | Tests | The memory-model tests to run on hardware |
| [CoreMark](https://github.com/eembc/coremark) | C | Single-core benchmark |
| [Feed_Handler](https://github.com/laraaskovic/Feed_Handler) | SystemVerilog | **Methodology template, not domain:** golden model first, measurements setting every constant, mutation testing, an honest "deliberately not done" section |
| [cbp-ng](https://github.com/AmpereComputing/cbp-ng) | C++ | Only for the post-May predictor study |

## 9. Toolchain and repo setup

- **Environment:** Linux or WSL2.
- **Compiler:** RISC-V GCC (riscv-gnu-toolchain or a prebuilt bare-metal build): `rv32im` for stage 1, `rv32ima` from stage 2.
- **Simulation:** Verilator ≥ 5.052; GTKWave or Surfer.
- **Golden model:** [Spike](https://github.com/riscv-software-src/riscv-isa-sim).
- **Tests:** [riscv-tests](https://github.com/riscv-software-src/riscv-tests), [riscv-arch-test](https://github.com/riscv-non-isa/riscv-arch-test) via [RISCOF](https://github.com/riscv-software-src/riscof), litmus-tests-riscv with herd7.
- **Formal:** Yosys, [SymbiYosys](https://github.com/YosysHQ/sby), an SMT solver (Bitwuzla, Boolector or Yices), [riscv-formal](https://github.com/YosysHQ/riscv-formal).
- **FPGA:** Quartus Prime Lite (supports Cyclone V).
- **Python:** scripts, plots, outcome comparison, cocotb.
- **Optional:** OpenROAD-flow-scripts for an ASIC area/timing report (post-May).

**Repo name:** `humber`.

**Suggested repo layout:**

```
rtl/core/       pipeline, ALU, mul/div, CSRs
rtl/cache/      L1 I/D caches, miss handling, reservation logic
rtl/coherence/  bus, arbiter, snoop logic, protocol FSMs
rtl/soc/        two-core top, shared memory, console, counters
tb/             unit tests, Spike lockstep harness, multicore stress tests
formal/         riscv-formal config; coherence properties (SWMR, data-value)
sw/             crt0 with mhartid dispatch, linker script, tests, CoreMark,
                litmus harness, parallel workloads, lock benchmarks
fpga/de1soc/    Quartus project, Platform Designer system, HPS loader
tools/          mutation testing, litmus outcome comparison, per-address checker
docs/           spec, protocol diagrams, decisions log, results, write-up
.github/        CI workflows
```

## 10. Verification strategy

Every layer catches a class of bug the others can't.

1. **Single-core correctness (stage 1, kept green throughout):**
   - riscv-tests and riscv-arch-test.
   - Lockstep co-simulation with Spike on every retired instruction.
   - riscv-formal.
   - Random programs from riscv-dv.
2. **Caches (stage 2):**
   - Unit tests against a small C++/Python cache model.
   - Spike lockstep with caches on: a single-core cache bug shows up as an architectural mismatch.
3. **Protocol formal (stage 3):** SymbiYosys on a small configuration (two caches, one or two lines) proving:
   - SWMR: never M in one cache while another holds a valid copy.
   - The data-value invariant: every valid copy holds the latest written value.
   - Bounded forward progress for both cores.
4. **Multicore stress tests:** both cores hammer a few shared lines with random loads, stores and AMOs. Checks:
   - Self-checking patterns: N increments from each core must total 2N; false-sharing slots keep their values.
   - A per-address checker on the bus trace: every load returns a value some store wrote, and no core ever sees an address's values go backward.
5. **Litmus tests on hardware:**
   - Run each test thousands of times with randomized delays and record outcome histograms.
   - Compare against herd7's allowed set for RVWMO.
   - Any forbidden outcome is a bug. With no store buffer, expect only SC outcomes.
6. **SVA assertions:**
   - Never two caches in M for the same line.
   - A reservation is cleared whenever its line is invalidated.
   - Bus grants are one-hot.
   - Every request is eventually granted.
7. **Mutation testing:** plant realistic coherence bugs and require a check to fail. Keep a mutation report. For example:
   - skip the invalidation on an upgrade
   - forget the writeback when a line in M is snooped
   - don't clear the reservation on invalidate
   - make the arbiter starve a core
8. **On the board:** CoreMark, spinlock and parallel workloads, and the litmus suite, loaded from the HPS. Expect "works in sim, not on the board" bugs: reset, clocking, memory timing.
9. **Coverage:** functional coverage of protocol transitions (Verilator covergroups), so "tested" becomes a list of state transitions actually hit.

## 11. What makes the write-up stand out

- [ ] A number in every claim, labelled by source: simulation, synthesis, or board.
- [ ] Honest baselines: one core vs two; MSI vs MESI on the same workloads.
- [ ] Proof the tests work: mutation report, coverage of protocol transitions, formal results.
- [ ] Real hardware: litmus histograms and workloads measured on the DE1-SoC.
- [ ] Every design constant justified by a measurement (cache size from an M10K budget and hit-rate sweep, line size from traffic data).
- [ ] Protocol state diagrams, and a bug log of the interesting bugs and how they were found.
- [ ] A "deliberately not done" section and known limitations.
- [ ] An independence statement: built on my own time and equipment from public specs, with no employer code or material.
- [ ] Everything in the repo that the résumé claims.
- [ ] I can explain every line and every trade-off in an interview.

## 12. Context and timeline

- **Recruiting:** new-grad postings for my graduating class should open around summer–fall 2027 (assumption; check when target firms opened last year). Stages 1–4 end by May 2027, so results are in hand when applying.
- **Interview prep:** 2–3 hours a week during the project: whiteboard Verilog (FIFOs, arbiters, CDC synchronizers, FSMs), timing (setup/hold, pipelining), and algorithm/C++ practice. Ramp to 6–8 hours a week from about May 2027. The project itself covers pipelines, caches, coherence and consistency questions.
- **Overlap with work:** the job is protocol integration. Coherence is new territory, and protocol thinking transfers. Keep all designs from public sources.
- **Community:** the UofT ASIC Team (IEEE UofT Student Branch) tapes out designs through Tiny Tapeout and takes project proposals ([uoftasic.com](https://uoftasic.com)).

## 13. Open questions

- [ ] L1 size, line size and associativity: decide from the M10K budget (week 1) and hit-rate data (stage 2).
- [ ] Snoop access to tags: dual-port M10K or a duplicate tag array?
- [ ] AMOs in the L1 (holding the line in M) or at the shared memory? (Default: in the L1.)
- [ ] Boot: both cores start at the same vector and branch on `mhartid`, or core 1 waits for a release flag?
- [ ] Litmus harness: how to synchronize the start and randomize timing on bare metal.
- [ ] Add the store buffer in stage 4, or spend that time on measurements?
- [ ] Name for the dual-core system, decided at stage 3 (candidate: Undercurrent).
- [ ] After May: predictor study, 4-core directory, out-of-order, or the trading project?
- [ ] Outcome of the manager conversation about Nios V and outside-work terms.

## 14. Working agreement with the assistant

*(Suggested; edit to taste.)*

- I write the RTL. The assistant explains concepts, reviews my code, hunts bugs, proposes tests and challenges design decisions. No complete modules unless I explicitly ask; I need to be able to explain every line.
- Tie explanations to the stage I'm in (§4) and its concept list (§6).
- Be honest about scope: if I'm behind the hour budget, say so and propose the cut. Enforce the stage-1 freeze rule.
- Separate facts (with sources) from estimates and opinions. Prefer measurements over opinions.
- When reviewing RTL, check reset behavior, synthesizability, latches, blocking vs nonblocking, width mismatches, combinational loops, and whether a test would catch the bug. For protocol logic, also check every state × event combination, races, and what happens to a reservation.

## 15. Status log

| Date | Stage | Hours this week | Done | Next | Blockers |
| --- | --- | --- | --- | --- | --- |
| 2026-10-19 | 0 | 0 | Researched options; first plan (out-of-order core) | n/a | n/a |
| 2026-10-22 | 0 | 0 | Plan changed: quick in-order core, then coherent dual-core system | n/a | n/a |
| 2026-10-23 | 0 | 0 | Named the project and core Humber | Week-1 checklist | Manager conversation |
