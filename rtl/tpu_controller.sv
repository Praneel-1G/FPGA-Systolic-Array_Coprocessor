`timescale 1ns / 1ps

module tpu_controller (
    input wire clk, input wire rst,
    input wire rx_empty, input wire [7:0] rx_data, output reg rx_rd,
    input wire tx_full, output reg tx_wr, output reg [7:0] tx_data,
    output reg load_wt, output reg [127:0] flat_weights,    // flat weights is a 128 bus with (16 weights * 8 bits)
    output reg [31:0] flat_data_in, input wire [31:0] flat_ppu_out
	 
	 //flat_data_in sends 4 pixels (32 bits) at once to the rows.
	// flat_ppu_out receives 4 finished pixels from the bottom of the grid.
);
    localparam S_IDLE=0, S_GET_WTS=1, S_GET_DATA=2, S_BURST_MATH=3, S_TX_RESULTS=4;
    reg [2:0] state;
    reg [7:0] byte_count;
    reg [3:0] math_cycle;
    reg [7:0] in_buffer [0:15], out_buffer [0:15]; 
	 //in_buffer stores the 16 raw pixels from Python.
	// out_buffer stores the 16 finished results before sending them back.


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE; rx_rd <= 0; tx_wr <= 0; load_wt <= 0;
        end else begin
            rx_rd <= 0; tx_wr <= 0; load_wt <= 0;     // rx_rd and tx_wr to 0 at the start of every clock cycle.This ensures that when we set them to 1 later, they only stay 1 for exactly one clock cycle (a pulse).
            case (state)
				
				
				//The Controller listens to the UART. 
				//If Python sends 0xAA, it switches to the weight-loading mode. 
				//If 0xBB, it switches to math mode.

                S_IDLE: if (!rx_empty) begin
                    rx_rd <= 1;
                    if (rx_data == 8'hAA) state <= S_GET_WTS;
                    else if (rx_data == 8'hBB) state <= S_GET_DATA;
                    byte_count <= 0;
                end
					 
					 //It collects 16 bytes.
					//The Concatenation: {flat_weights[119:0], rx_data} pushes the new byte into the "tail" of the 128-bit bus, shifting the others over.
					//On the 15th (final) byte, it pulses load_wt to lock these into the PE registers.
					 
					 
                S_GET_WTS: if (!rx_empty && !rx_rd) begin
                    rx_rd <= 1;
                    flat_weights <= {flat_weights[119:0], rx_data};
                    byte_count <= byte_count + 1;
                    if (byte_count == 15) begin load_wt <= 1; state <= S_IDLE; end
                end
					 
					 // It collects 16 image pixels and stores them in in_buffer.
					// Once it has all 16, it starts the high-speed math grid.
					 
                S_GET_DATA: if (!rx_empty && !rx_rd) begin
                    rx_rd <= 1;
                    in_buffer[byte_count] <= rx_data;
                    byte_count <= byte_count + 1;
                    if (byte_count == 15) begin state <= S_BURST_MATH; math_cycle <= 0; end
                end
					 
					 
					 
                S_BURST_MATH: begin
                    math_cycle <= math_cycle + 1;
						  
						 // Part A: The Diagonal Injection (The "Skew")

                    case (math_cycle)
                        0: flat_data_in <= {8'd0, 8'd0, 8'd0, in_buffer[0]};
                        1: flat_data_in <= {8'd0, 8'd0, in_buffer[4], in_buffer[1]};
                        2: flat_data_in <= {8'd0, in_buffer[8], in_buffer[5], in_buffer[2]};
                        3: flat_data_in <= {in_buffer[12], in_buffer[9], in_buffer[6], in_buffer[3]};
                        4: flat_data_in <= {in_buffer[13], in_buffer[10], in_buffer[7], 8'd0};
                        5: flat_data_in <= {in_buffer[14], in_buffer[11], 8'd0, 8'd0};
                        6: flat_data_in <= {in_buffer[15], 8'd0, 8'd0, 8'd0};
                        default: flat_data_in <= 0;
                    endcase
                    // Deskew + Transpose Logic
                    if (math_cycle == 6) begin out_buffer[0] <= flat_ppu_out[7:0]; end
                    if (math_cycle == 7) begin out_buffer[1] <= flat_ppu_out[7:0]; out_buffer[4] <= flat_ppu_out[15:8]; end
                    if (math_cycle == 8) begin out_buffer[2] <= flat_ppu_out[7:0]; out_buffer[5] <= flat_ppu_out[15:8]; out_buffer[8] <= flat_ppu_out[23:16]; end
                    if (math_cycle == 9) begin out_buffer[3] <= flat_ppu_out[7:0]; out_buffer[6] <= flat_ppu_out[15:8]; out_buffer[9] <= flat_ppu_out[23:16]; out_buffer[12] <= flat_ppu_out[31:24]; end
                    if (math_cycle == 10)begin out_buffer[7] <= flat_ppu_out[15:8]; out_buffer[10]<= flat_ppu_out[23:16]; out_buffer[13]<= flat_ppu_out[31:24]; end
                    if (math_cycle == 11)begin out_buffer[11]<= flat_ppu_out[23:16]; out_buffer[14]<= flat_ppu_out[31:24]; end
                    if (math_cycle == 12)begin out_buffer[15]<= flat_ppu_out[31:24]; end
                    if (math_cycle == 13)begin state <= S_TX_RESULTS; byte_count <= 0; end
                end
					 
					 
					 
                S_TX_RESULTS: if (!tx_full && !tx_wr) begin
                    tx_wr <= 1; tx_data <= out_buffer[byte_count];
                    byte_count <= byte_count + 1;
                    if (byte_count == 15) state <= S_IDLE;
                end
            endcase
        end
    end
endmodule