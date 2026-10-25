`default_nettype none
module counter (
    input  wire       clk,
    input  wire       rst_n,
    output logic [3:0] count_q
);
    always_ff @(posedge clk) begin
        if (!rst_n) count_q <= '0;
        else        count_q <= count_q + 4'd1;
    end
endmodule
`default_nettype wire
