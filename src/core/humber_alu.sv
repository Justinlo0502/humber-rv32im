`default_nettype none

module humber_alu
    import humber_pkg::*;
(
    input alu_op_e                  op,
    input logic[31:0]               a,
    input logic[31:0]               b,
    
    output logic[31:0]              result
);

    always_comb begin
        case (op)
            ALU_ADD:    result = a + b;                         // add; also used for address calc, LUI/AUIPC
            ALU_SUB:    result = a - b;                         // subtract
            ALU_SLL:    result = a << b[4:0];                   // shift left logical, zero fill, amount = low 5 bits of b
            ALU_SLT:    result = {31'b0, $signed(a) < $signed(b)};                    // set 1 if a < b, signed compare, else 0
            ALU_SLTU:   result = {31'b0, a < b}; // set 1 if a < b, unsigned compare, else 0
            ALU_XOR:    result = a ^ b;                         // bitwise exclusive-or
            ALU_SRL:    result = a >> b[4:0];                   // shift right logical, zero fill
            ALU_SRA:    result = $signed(a) >>> b[4:0];                 // shift right arithmetic, sign-bit fill (needs $signed(a))
            ALU_OR:     result = a | b;                          // bitwise or
            ALU_AND:    result = a & b;                          // bitwise and
            default: result = '0;
        endcase
    end
endmodule

`default_nettype wire
