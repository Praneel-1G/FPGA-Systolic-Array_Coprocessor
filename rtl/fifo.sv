`timescale 1ns / 1ps

module fifo #(
    parameter B = 8,  // Width of data (8 bits)
    parameter W = 4   // Width of pointer (4 bits = 16 words deep)
)(
    input wire clk, rst, rd, wr,
    input wire [B-1:0] w_data,
    output wire empty, full,
    output wire [B-1:0] r_data
);

    // Memory array (2D array of regs in standard Verilog)
    reg [B-1:0] array_reg [0:(2**W)-1]; 
    
    // Internal registers and wires for pointers and status
    reg [W-1:0] w_ptr_reg, w_ptr_next, w_ptr_succ;
    reg [W-1:0] r_ptr_reg, r_ptr_next, r_ptr_succ;
    reg full_reg, empty_reg, full_next, empty_next;
    wire wr_en;

    // Write enable logic
    assign wr_en = wr & ~full_reg;

    // Memory Write Block (Sequential)
    always @(posedge clk) begin
        if (wr_en) begin
            array_reg[w_ptr_reg] <= w_data;
        end
    end

    // Memory Read Logic (Continuous assignment)
    assign r_data = array_reg[r_ptr_reg]; 

    // Pointer and Status Update Block (Sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w_ptr_reg <= 0;
            r_ptr_reg <= 0;
            full_reg  <= 1'b0;
            empty_reg <= 1'b1;
        end else begin
            w_ptr_reg <= w_ptr_next;
            r_ptr_reg <= r_ptr_next;
            full_reg  <= full_next;
            empty_reg <= empty_next;
        end
    end

    // Next-State Logic for Pointers (Combinational)
    always @(*) begin
        // Pre-calculate next pointer values
        w_ptr_succ = w_ptr_reg + 1;
        r_ptr_succ = r_ptr_reg + 1;
        
        // Default assignments to avoid latches
        w_ptr_next = w_ptr_reg;
        r_ptr_next = r_ptr_reg;
        full_next  = full_reg;
        empty_next = empty_reg;
        
        case ({wr, rd})
            2'b01: begin // READ operation
                if (~empty_reg) begin
                    r_ptr_next = r_ptr_succ;
                    full_next  = 1'b0;
                    if (r_ptr_succ == w_ptr_reg)
                        empty_next = 1'b1;
                end
            end
            2'b10: begin // WRITE operation
                if (~full_reg) begin
                    w_ptr_next = w_ptr_succ;
                    empty_next = 1'b0;
                    if (w_ptr_succ == r_ptr_reg)
                        full_next = 1'b1;
                end
            end
            2'b11: begin // READ AND WRITE simultaneously
                w_ptr_next = w_ptr_succ;
                r_ptr_next = r_ptr_succ;
            end
            default: ; // Do nothing
        endcase
    end

    // Output assignments
    assign full  = full_reg;
    assign empty = empty_reg;

endmodule