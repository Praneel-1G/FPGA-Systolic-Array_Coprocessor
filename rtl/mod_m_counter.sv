`timescale 1ns / 1ps

module mod_m_counter #(
    parameter M = 10,
    parameter N = 2 
    )(
    input wire clk, rst,
    output wire max_tick,
    output wire [N-1:0] q
);

    reg [N-1:0] r_reg; // current State of the counter
    wire [N-1:0] r_next; // next state 

    always @(posedge clk or posedge rst) begin
        if (rst)
            r_reg <= 0;
        else
            r_reg <= r_next;
    end
    //if r_reg has reached M-1 then reset it to 0 

    assign r_next = (r_reg == M - 1) ? 0 : r_reg + 1;
    assign q = r_reg;
    // pulse max_tick high for excatly one clock cycle when we hit the max value
    assign max_tick = (r_reg == M - 1) ? 1'b1 : 1'b0;

endmodule