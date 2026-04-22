`timescale 1ns / 1ps

module tb_top_tpu();
    localparam CLK_PERIOD = 20;   // 50 MHz
    localparam BIT_TIME = 8680;   // 115200 Baud

    reg clk, rst, rx;
    wire tx;
    top_tpu dut (.clk(clk), .rst(rst), .rx(rx), .tx(tx));

    initial begin clk = 0; forever #(CLK_PERIOD / 2) clk = ~clk; end

    task send_byte(input [7:0] d);
        integer i;
        begin
            rx = 0; #(BIT_TIME);
            for (i=0; i<8; i=i+1) begin rx = d[i]; #(BIT_TIME); end
            rx = 1; #(BIT_TIME);
        end
    endtask

    // Concurrent Background Receiver
    integer cap_idx = 0;
    reg [7:0] captured [0:15];
    initial begin
        forever begin
            @(negedge tx);
            #(BIT_TIME / 2);
            for (integer i=0; i<8; i=i+1) begin #(BIT_TIME); captured[cap_idx][i] = tx; end
            #(BIT_TIME);
            cap_idx = cap_idx + 1;
        end
    end

    integer idx;
    initial begin
        rx = 1; rst = 1; #(CLK_PERIOD*10); rst = 0; #(CLK_PERIOD*10);
        $dumpfile("top_tpu_full.vcd"); $dumpvars(0, tb_top_tpu);

        $display("--- Loading Identity Matrix Weights ---");
        send_byte(8'hAA);
        for (idx=0; idx<16; idx=idx+1) send_byte((idx%5==0) ? 8'h01 : 8'h00); //  (idx%5==0) is a shortcut to send an Identity Matrix. 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1.

        #(BIT_TIME*5);
        $display("--- Sending Pixels 1-16 ---");  
        send_byte(8'hBB);
        for (idx=0; idx<16; idx=idx+1) send_byte(idx+1); // sends 1, 2, 3... 16 as pixels.

        wait(cap_idx == 16);   // The script stops here and waits. It won't move until the Background Receiver has successfully caught 16 bytes coming back from the FPGA.
        for (idx=0; idx<16; idx=idx+1) begin
            $display("Byte %0d: %0d (Expected %0d)", idx, captured[idx], idx+1);
            if (captured[idx] !== idx+1) $display("Mismatch!");
        end
        $display("Test Finished.");
        $finish;
    end
endmodule