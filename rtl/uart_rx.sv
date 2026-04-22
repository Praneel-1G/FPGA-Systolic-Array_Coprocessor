`timescale 1ns / 1ps

// the uart reciever will monitor the single wire rx which translates the stream of highs and lows into an 8 bit BYtE
// when the rx = 0 then the sequence starts
// STart : when the line drops to 0 ; reciever counter 7 s_tick pulses cuz that puts the reciever right in the middle of the start bit



module uart_rx #(
    parameter DBIT = 8,
    parameter SB_TICK = 16
)(
    input wire clk, rst,
    input wire rx, s_tick, // rx: single pin where data enters serially (1 bit at a time)
                            // s_tick comes from the baud rate generator
    output reg rx_done_tick,  
    output wire [7:0] dout
);
    localparam [1:0] idle = 2'b00, start = 2'b01, data = 2'b10, stop = 2'b11;

    // splitting of the fsm into registors : curent state and next states
    reg [1:0] state_reg, state_next; // keeps track of idle/start/stop/data
    reg [3:0] s_reg, s_next;         // counts tics (0 to 15) to find the mid bit
    reg [2:0] n_reg, n_next;        // counts how many data bits to read (0 to 7)
    reg [7:0] b_reg, b_next;        // shift registor to collext all the incoming bits into a byte

    // the controller next state 
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_reg <= idle;
            s_reg <= 0;
            n_reg <= 0;
            b_reg <= 0;
        end else begin
            state_reg <= state_next;
            s_reg <= s_next;
            n_reg <= n_next;
            b_reg <= b_next;
        end
    end

    always @(*) begin
        state_next = state_reg;
        rx_done_tick = 1'b0;
        s_next = s_reg;
        n_next = n_reg;
        b_next = b_reg;

        case (state_reg)
            idle: begin
                if (~rx) begin  
                    state_next = start;
                    s_next = 0;
                end
            end
            start: begin
                if (s_tick) begin
                    if (s_reg == 7) begin
                        s_next = 0;
                        n_next = 0;
                        state_next = data;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end
            data: begin
                if (s_tick) begin
                    if (s_reg == 15) begin
                        s_next = 0;
                        b_next = {rx, b_reg[7:1]};
                        if (n_reg == (DBIT - 1))
                            state_next = stop;
                        else
                            n_next = n_reg + 1;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end
            stop: begin
                if (s_tick) begin
                    if (s_reg == (SB_TICK - 1)) begin
                        rx_done_tick = 1'b1;
                        state_next = idle;
                    end else begin
                        s_next = s_reg + 1;
                    end
                end
            end
        endcase
    end

    assign dout = b_reg;

endmodule