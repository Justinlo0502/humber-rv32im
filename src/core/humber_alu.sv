module humber_alu (
    input humber_pkg::alu_op_e      op,
    input logic[31:0]               a,
    input logic[31:0]               b,
    
    output logic[31:0]              result
);

    always_comb begin
        case (op)
            // The 10 op
            default: result = '0;
        endcase
    end
endmodule

`default_nettpe wire