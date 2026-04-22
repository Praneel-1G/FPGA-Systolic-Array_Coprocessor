`timescale 1ns / 1ps

module systolic_array #(
    parameter D_WIDTH = 9, parameter W_WIDTH = 8, parameter ACC_WIDTH = 18 
)(
    input wire clk, rst, load_wt,
    input wire [127:0] flat_weights, input wire [31:0] flat_data_in,
    output wire [71:0] flat_acc_out
);
    wire signed [W_WIDTH-1:0] wt_in [0:15];
    wire signed [D_WIDTH-1:0] data_in [0:3];
    wire signed [ACC_WIDTH-1:0] acc_out [0:3];

    assign data_in[0] = {1'b0, flat_data_in[7:0]};
    assign data_in[1] = {1'b0, flat_data_in[15:8]};
    assign data_in[2] = {1'b0, flat_data_in[23:16]};
    assign data_in[3] = {1'b0, flat_data_in[31:24]};

    // FIX 1: Added "begin : unpack_wt" and "end"
    genvar w;
    generate for (w = 0; w < 16; w = w + 1) begin : unpack_wt
         assign wt_in[w] = flat_weights[(w*8)+7 : (w*8)];
    end endgenerate
    
    assign flat_acc_out = {acc_out[3], acc_out[2], acc_out[1], acc_out[0]};

    wire signed [D_WIDTH-1:0] d_l [0:3][0:4];
    wire signed [ACC_WIDTH-1:0] a_l [0:4][0:3]; 

    // FIX 2: Added ": edge_assign" to the begin statement
    genvar i;
    generate for (i = 0; i < 4; i = i + 1) begin : edge_assign 
        assign d_l[i][0] = data_in[i]; 
        assign a_l[0][i] = 0; 
        assign acc_out[i] = a_l[4][i]; 
    end endgenerate

    genvar r, c;
    generate for (r = 0; r < 4; r = r + 1) begin : row
        for (c = 0; c < 4; c = c + 1) begin : col
            mac_pe #(.D_WIDTH(D_WIDTH), .W_WIDTH(W_WIDTH), .ACC_WIDTH(ACC_WIDTH)) pe_inst (
                .clk(clk), .rst(rst), .load_wt(load_wt), .wt_in(wt_in[r*4 + c]),
                .data_in(d_l[r][c]), .data_out(d_l[r][c+1]), .acc_in(a_l[r][c]), .acc_out(a_l[r+1][c])
            );
        end
    end endgenerate
    
endmodule