`timescale 1ns / 1ps

module uart #(
    parameter DBIT = 8,     // data bits ; tells rx and tx how many bits to wait before declaring "finish" 
    parameter SB_TICK = 16,   // no of tick to process the Stop bit at the end of the transmission
                               // 16x Oversampling used by uart recieviers
    parameter DVSR = 27,     // Set for 115200 Baud @ 50MH   DVSR = (System clk freq) / (16* desired Baud rate)
    parameter DVSR_BIT = 8,  // lengtth of counter to store the DVSR number = log2(DVSR)
    parameter FIFO_W = 5     // size of pinters in the fifo. 
                            // 32-byte deep FIFO ; depth = 2^(FIFO_W)
)(
    input wire clk, rst,
    input wire rd_uart, 
    input wire wr_uart, 
    input wire rx,
    input wire [7:0] w_data,   // system sends data (byte) to out
    output wire tx_full, // not to write the data
    output wire rx_empty,    // 1 means not to read data
    output wire tx,
    output wire [7:0] r_data     // data to be read by the system from fpga
);

    wire tick;
    wire rx_done_tick; 
    wire tx_done_tick;
    wire tx_empty; 
    wire tx_fifo_not_empty;
    wire [7:0] tx_fifo_out, rx_data_out;

    mod_m_counter #(.M(DVSR), .N(DVSR_BIT)) baud_gen_unit(
        .clk(clk), .rst(rst), .q(), .max_tick(tick)
    );

    uart_rx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_rx_unit(
        .clk(clk), .rst(rst), .rx(rx), .s_tick(tick),
        .rx_done_tick(rx_done_tick), .dout(rx_data_out)
    );

    fifo #(.B(DBIT), .W(FIFO_W)) fifo_rx_unit(
        .clk(clk), .rst(rst), .rd(rd_uart), .wr(rx_done_tick),
        .w_data(rx_data_out), .empty(rx_empty), .full(), .r_data(r_data)
    );

    fifo #(.B(DBIT), .W(FIFO_W)) fifo_tx_unit(
        .clk(clk), .rst(rst), .rd(tx_done_tick), .wr(wr_uart),
        .w_data(w_data), .empty(tx_empty), .full(tx_full), .r_data(tx_fifo_out)
    );

    uart_tx #(.DBIT(DBIT), .SB_TICK(SB_TICK)) uart_tx_unit(
        .clk(clk), .rst(rst), .tx_start(tx_fifo_not_empty),
        .s_tick(tick), .din(tx_fifo_out),
        .tx_done_tick(tx_done_tick), .tx(tx)
    );

    assign tx_fifo_not_empty = ~tx_empty;

endmodule