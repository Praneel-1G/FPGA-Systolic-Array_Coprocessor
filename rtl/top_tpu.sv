`timescale 1ns / 1ps

module top_tpu (
    input wire clk,
    input wire rst,
    input wire rx,
    output wire tx
);
    wire rx_empty, rx_rd, tx_full, tx_wr;
    wire [7:0] rx_data, tx_data;
    wire load_wt;
    wire [127:0] flat_weights;
    wire [31:0]  flat_data_in;
    wire [71:0]  internal_acc_wire;
    wire [31:0]  flat_ppu_out;

    // DVSR = 50MHz / (16 * 115200) = 27
    uart #(.DVSR(27)) my_uart (
        .clk(clk), .rst(rst), .rx(rx), .tx(tx),
        .rx_empty(rx_empty), .r_data(rx_data), .rd_uart(rx_rd),
        .tx_full(tx_full), .w_data(tx_data), .wr_uart(tx_wr)
    );

    tpu_controller my_controller (
        .clk(clk), .rst(rst),
        .rx_empty(rx_empty), .rx_data(rx_data), .rx_rd(rx_rd),
        .tx_full(tx_full), .tx_data(tx_data), .tx_wr(tx_wr),
        .load_wt(load_wt), .flat_weights(flat_weights),
        .flat_data_in(flat_data_in), .flat_ppu_out(flat_ppu_out)
    );

    systolic_array my_mmu (
        .clk(clk), .rst(rst), .load_wt(load_wt),
        .flat_weights(flat_weights), .flat_data_in(flat_data_in),
        .flat_acc_out(internal_acc_wire)
    );

    ppu my_ppu (
        .clk(clk), .rst(rst),
        .flat_acc_in(internal_acc_wire), .flat_ppu_out(flat_ppu_out)
    );
endmodule