`timescale 1ns / 1ps

module mac_pe_tb;

    // --- Parametrizable Widths (Matches the DUT) ---
    localparam D_WIDTH   = 8;
    localparam W_WIDTH   = 8;
    localparam ACC_WIDTH = 20;

    // --- Inputs ---
    reg clk;
    reg rst;
    reg load_wt;
    reg signed [W_WIDTH-1:0] wt_in;
    reg signed [D_WIDTH-1:0] data_in;
    reg signed [ACC_WIDTH-1:0] acc_in;

    // --- Outputs ---
    wire signed [D_WIDTH-1:0] data_out;
    wire signed [ACC_WIDTH-1:0] acc_out;

    // --- Instantiate the MAC Unit (Processing Element) ---
    mac_pe #(
        .D_WIDTH(D_WIDTH), 
        .W_WIDTH(W_WIDTH), 
        .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk),
        .rst(rst),
        .load_wt(load_wt),
        .wt_in(wt_in),
        .data_in(data_in),
        .acc_in(acc_in),
        .data_out(data_out),
        .acc_out(acc_out)
    );

    // --- Clock Generation ---
    always #5 clk = ~clk;

    // Helper task to wait exactly 1 clock cycle
    task tick();
        begin
            @(posedge clk);
            #1; // Wait 1ns after clock edge to read stable values
        end
    endtask

    initial begin
        // Setup GTKWave
        $dumpfile("mac_test.vcd");
        $dumpvars(0, mac_pe_tb);

        // 1. Initialize
        clk = 0;
        rst = 1;
        load_wt = 0;
        wt_in  = 0;
        data_in = 0;
        acc_in = 0;

        #20 rst = 0; // Release reset

        $display("=======================================");
        $display("🚀 SINGLE MAC UNIT TESTBENCH STARTED");
        $display("=======================================\n");

        // ---------------------------------------------------------
        // TEST 1: The Weight-Stationary Load
        // ---------------------------------------------------------
        $display("[+] TEST 1: Loading Weight = 5");
        load_wt = 1;
        wt_in = 5;
        tick();        // Clock edge happens! Weight is now locked inside.
        load_wt = 0;   // Drop the load signal
        wt_in = 0;     // Clear the input wire to prove the box remembered it

        // ---------------------------------------------------------
        // TEST 2: Basic MAC Math & 1-Cycle Delay
        // ---------------------------------------------------------
        $display("[+] TEST 2: Sending Pixel = 10, Acc_in = 100");
        data_in = 10;
        acc_in = 100;
        
        $display("    Before Clock -> data_out: %0d | acc_out: %0d", data_out, acc_out);
        
        tick(); // Clock edge happens! Data moves through the flip-flops.
        
        // Expected Math: acc_out = acc_in + (data_in * weight)
        // Expected Math: acc_out = 100 + (10 * 5) = 150
        $display("    After  Clock -> data_out: %0d | acc_out: %0d (Expected: 150)", data_out, acc_out);
        if (acc_out === 150 && data_out === 10) $display("    ✅ PASS!"); else $display("    ❌ FAIL!");

        $display("");

        // ---------------------------------------------------------
        // TEST 3: Edge Detection Math (Negative Weights!)
        // ---------------------------------------------------------
        $display("[+] TEST 3: Loading Negative Edge-Detection Weight = -2");
        load_wt = 1;
        wt_in = -2; // Standard Edge Detection kernel uses negative numbers
        tick();
        load_wt = 0;

        $display("[+] Sending Pixel = 20, Acc_in = 50");
        data_in = 20;
        acc_in = 50;
        
        tick(); // Clock edge happens!
        
        // Expected Math: acc_out = 50 + (20 * -2) = 10
        $display("    After  Clock -> data_out: %0d | acc_out: %0d (Expected: 10)", data_out, acc_out);
        if (acc_out === 10 && data_out === 20) $display("    ✅ PASS!"); else $display("    ❌ FAIL!");

        $display("\n=======================================");
        $display("🎉 MAC TEST FINISHED!");
        $display("=======================================");
        
        #50;
        $finish;
    end

endmodule