# Throwaway toolchain smoke test (not Humber RTL). Run from the repo root:
#   make -C sim/smoke        build and run
#   make -C sim/smoke wave   open the waveform
#   make -C sim/smoke clean
# Needs: source ~/tools/oss-cad-suite/environment

BUILD := ../../build/smoke

.PHONY: all run wave clean
all: run

$(BUILD)/Vcounter: counter.sv main.cpp
	mkdir -p $(BUILD)
	verilator --cc --exe --build --trace -Wall --top-module counter \
	    --Mdir $(BUILD) counter.sv main.cpp -j 8

run: $(BUILD)/Vcounter
	cd $(BUILD) && ./Vcounter

wave: run
	surfer $(BUILD)/smoke.vcd

clean:
	rm -rf $(BUILD)
