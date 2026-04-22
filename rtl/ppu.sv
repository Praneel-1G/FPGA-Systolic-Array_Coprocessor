`timescale 1ns / 1ps

module ppu #(
    parameter ACC_WIDTH = 18,
    parameter OUT_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    
    // The 72-bit fat cable coming from the bottom of the MMU (4 columns * 18 bits)
    input wire [(ACC_WIDTH * 4) - 1 : 0] flat_acc_in,
    
    // The 32-bit shrunk cable going to the Output Memory/UART (4 columns * 8 bits)
    output reg [(OUT_WIDTH * 4) - 1 : 0] flat_ppu_out
);

    // 1. Unpack the fat 18-bit wires from the MMU
    wire signed [17:0] col0_in = flat_acc_in[17:0];
    wire signed [17:0] col1_in = flat_acc_in[35:18];
    wire signed [17:0] col2_in = flat_acc_in[53:36];
    wire signed [17:0] col3_in = flat_acc_in[71:54];

    // 2. Combinational Logic: ReLU + Clamping
    // - If it's less than 0 (negative), output 0.
    // - If it's greater than 255, output 255.
    // - Otherwise, just safely take the bottom 8 bits.
    wire [7:0] col0_processed = (col0_in < 0) ? 8'd0 : ((col0_in > 255) ? 8'd255 : col0_in[7:0]);
    wire [7:0] col1_processed = (col1_in < 0) ? 8'd0 : ((col1_in > 255) ? 8'd255 : col1_in[7:0]);
    wire [7:0] col2_processed = (col2_in < 0) ? 8'd0 : ((col2_in > 255) ? 8'd255 : col2_in[7:0]);
    wire [7:0] col3_processed = (col3_in < 0) ? 8'd0 : ((col3_in > 255) ? 8'd255 : col3_in[7:0]);

    // 3. Sequential Logic: Pack them up and sync to the clock!
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            flat_ppu_out <= 0;
        end else begin
            // Pack the 4 processed 8-bit bytes into a single 32-bit output cable
            flat_ppu_out <= {col3_processed, col2_processed, col1_processed, col0_processed};
        end
    end

endmodule