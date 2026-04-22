`timescale 1ns / 1ps

module mac_pe #(
    // --- Fully Parametrizable Widths ---
    parameter D_WIDTH   = 8,   // DATA (Pixel) width (e.g., 8-bit)
    parameter W_WIDTH   = 8,   // Weight width (e.g., 8-bit signed)
    parameter ACC_WIDTH = 16   // Accumulator width (Large enough to prevent overflow)
)(
    input  wire clk,
    input  wire rst,

    // --- Weight Pre-loading ---
    input  wire                 load_wt,   // High when loading the filter matrix
    input  wire signed [W_WIDTH-1:0] wt_in,     // The weight to save inside this PE

    // --- Systolic Data Flow (The Wave) ---
    input  wire signed [D_WIDTH-1:0] data_in,    // Pixel coming from the LEFT
    input  wire signed [ACC_WIDTH-1:0] acc_in,  // Partial sum coming from the TOP

    output reg  signed [D_WIDTH-1:0] data_out,   // Pixel passing to the RIGHT
    output reg  signed [ACC_WIDTH-1:0] acc_out  // New sum passing to the BOTTOM
);

    // Internal register to hold this specific blue box's weight
    reg signed [W_WIDTH-1:0] weight_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            weight_reg <= 0;
            data_out    <= 0;
            acc_out    <= 0;
        end else begin
            
            // 1. Weight-Stationary Load
            // When the TPU gets an opcode, it loads the weights first.
            if (load_wt) begin
                weight_reg <= wt_in;
            end

            // 2. Pass Data to the Right (The Horizontal Wave)
            // It takes exactly 1 clock cycle for the pixel to move through the box
            data_out <= data_in
    ; 

            // 3. The MAC Math (The Vertical Wave)
            // Multiply the pixel by the weight, add it to the sum from above, 
            // and pass the result down to the next row on the clock edge.
            acc_out <= acc_in + (data_in* weight_reg);

        end
    end

endmodule