// Throwaway board smoke test (not Humber RTL). Proves the Quartus compile
// and JTAG programming flow end to end on the DE1-SoC:
//   LEDR[9]   blinks 1 s on / 1 s off      -> CLOCK_50 pin + SDC are right
//   HEX0      counts 0..F once per second   -> HEX pins, segment polarity
//   LEDR[8:0] follow SW[8:0]                -> input and output pins
//   KEY[0]    held = reset (HEX0 shows 0, LEDR[9] off)
`default_nettype none
module smoke_top (
    input  wire        CLOCK_50,
    input  wire  [0:0] KEY,       // active low when pressed
    input  wire  [8:0] SW,
    output logic [9:0] LEDR,
    output logic [6:0] HEX0       // active-low segments, bit 0 = a ... bit 6 = g
);
    localparam int unsigned TICKS_PER_SEC = 50_000_000;

    // KEY[0] is asynchronous to CLOCK_50: two flops before it is used as a
    // synchronous reset. Registers power up as 0, so rst_n starts asserted.
    logic [1:0] rst_sync_q;
    logic       rst_n;
    always_ff @(posedge CLOCK_50) rst_sync_q <= {rst_sync_q[0], KEY[0]};
    assign rst_n = rst_sync_q[1];

    // 1 Hz tick: 26 bits holds up to 67,108,863 > 49,999,999.
    logic [25:0] div_q;
    logic        tick;
    assign tick = (div_q == 26'(TICKS_PER_SEC - 1));

    always_ff @(posedge CLOCK_50) begin
        if (!rst_n)    div_q <= '0;
        else if (tick) div_q <= '0;
        else           div_q <= div_q + 26'd1;
    end

    logic [3:0] sec_q;
    logic       beat_q;
    always_ff @(posedge CLOCK_50) begin
        if (!rst_n) begin
            sec_q  <= '0;
            beat_q <= 1'b0;
        end else if (tick) begin
            sec_q  <= sec_q + 4'd1;
            beat_q <= ~beat_q;
        end
    end

    // Hex digit to segments, written active high (gfedcba) then inverted.
    logic [6:0] seg;
    always_comb begin
        case (sec_q)
            4'h0: seg = 7'b011_1111;
            4'h1: seg = 7'b000_0110;
            4'h2: seg = 7'b101_1011;
            4'h3: seg = 7'b100_1111;
            4'h4: seg = 7'b110_0110;
            4'h5: seg = 7'b110_1101;
            4'h6: seg = 7'b111_1101;
            4'h7: seg = 7'b000_0111;
            4'h8: seg = 7'b111_1111;
            4'h9: seg = 7'b110_1111;
            4'hA: seg = 7'b111_0111;
            4'hB: seg = 7'b111_1100;
            4'hC: seg = 7'b011_1001;
            4'hD: seg = 7'b101_1110;
            4'hE: seg = 7'b111_1001;
            4'hF: seg = 7'b111_0001;
        endcase
    end

    assign HEX0 = ~seg;
    assign LEDR = {beat_q, SW};
endmodule
`default_nettype wire
