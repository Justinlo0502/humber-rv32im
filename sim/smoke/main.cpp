#include "Vcounter.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cstdio>
int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    Vcounter top;
    VerilatedVcdC tfp;
    top.trace(&tfp, 99);
    tfp.open("smoke.vcd");
    vluint64_t t = 0;
    top.rst_n = 0; top.clk = 0;
    for (int i = 0; i < 40; i++) {
        if (i == 4) top.rst_n = 1;
        top.clk = !top.clk; top.eval(); tfp.dump(t++);
    }
    tfp.close();
    // 40 half-cycles = 20 posedges; reset held for the first 2, so 18 counts -> 18 mod 16 = 2
    printf("count_q = %d (expect 2)\n", top.count_q);
    return top.count_q == 2 ? 0 : 1;
}
