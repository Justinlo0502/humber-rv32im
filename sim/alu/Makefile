# ALU unit test. Run from the repo root:
#   make -C sim/alu        build and run
#   make -C sim/alu clean
# Needs: source ~/tools/oss-cad-suite/environment
#
# How the pieces fit together:
#   1. Verilator reads the SystemVerilog (package FIRST, because the ALU uses
#      the type humber_pkg::alu_op_e and a package must be compiled before
#      anything that refers to it).
#   2. It translates that into C++ (a class named V<top-module>, here
#      Vhumber_alu) in the build directory.
#   3. --exe/--build then compiles that C++ together with alu_tb.cpp (our
#      testbench) into one executable, which `run` executes.
#
# We point at the RTL in src/core instead of copying it here, so the test
# always checks the file you are actually editing.

BUILD := ../../build/alu
SRC   := ../../src/core

# Order matters: package first, then the module that uses it.
RTL   := $(SRC)/humber_pkg.sv $(SRC)/humber_alu.sv

.PHONY: all run clean
all: run

# Rebuild whenever any RTL file or the testbench changes.
$(BUILD)/Vhumber_alu: $(RTL) alu_tb.cpp
	mkdir -p $(BUILD)
	verilator --cc --exe --build -Wall --top-module humber_alu \
	    --Mdir $(BUILD) $(RTL) alu_tb.cpp -j 8

# The testbench's exit code (0 = all checks passed) becomes make's result.
run: $(BUILD)/Vhumber_alu
	$(BUILD)/Vhumber_alu

clean:
	rm -rf $(BUILD)
