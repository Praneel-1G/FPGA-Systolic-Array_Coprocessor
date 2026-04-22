`timescale 1ns / 1ps

module systolic_array_tb;

    parameter D_WIDTH = 8;
    parameter W_WIDTH = 8;
    parameter ACC_WIDTH = 16;

    reg clk;
    reg rst;
    reg load_wt;
    
    reg signed [W_WIDTH-1:0] wt_in [0:15];
    reg signed [D_WIDTH-1:0] data_in [0:3];
    wire signed [ACC_WIDTH-1:0] acc_out [0:3];

    // 2D Array to hold our input Matrix A
    reg signed [D_WIDTH-1:0] matrix_A [0:3][0:3];

    systolic_array #(
        .D_WIDTH(D_WIDTH), .W_WIDTH(W_WIDTH), .ACC_WIDTH(ACC_WIDTH)
    ) uut (
        .clk(clk), .rst(rst), .load_wt(load_wt), 
        .wt_in(wt_in), .data_in(data_in), .acc_out(acc_out)
    );

    always #5 clk = ~clk;

    integer i, t, row;
    integer cycle_count = 0;

    // Track clock cycles for clean printing
    always @(posedge clk) cycle_count <= cycle_count + 1;

    initial begin
        clk = 0; rst = 1; load_wt = 0;
        for (i=0; i<16; i=i+1) wt_in[i] = 0;
        for (i=0; i<4; i=i+1) data_in[i] = 0;

        // 1. DEFINE MATRIX A (The data to process)
        matrix_A[0][0]=1;  matrix_A[0][1]=2;  matrix_A[0][2]=3;  matrix_A[0][3]=4;
        matrix_A[1][0]=5;  matrix_A[1][1]=6;  matrix_A[1][2]=7;  matrix_A[1][3]=8;
        matrix_A[2][0]=9;  matrix_A[2][1]=10; matrix_A[2][2]=11; matrix_A[2][3]=12;
        matrix_A[3][0]=13; matrix_A[3][1]=14; matrix_A[3][2]=15; matrix_A[3][3]=16;

        #20 rst = 0; #10;

        // 2. LOAD MATRIX B (Weights - The Identity Matrix)
        $display("\n--- LOADING WEIGHTS (IDENTITY MATRIX) ---");
        wt_in[0]=1;  wt_in[1]=0;  wt_in[2]=0;  wt_in[3]=0;   // Row 0
        wt_in[4]=0;  wt_in[5]=1;  wt_in[6]=0;  wt_in[7]=0;   // Row 1
        wt_in[8]=0;  wt_in[9]=0;  wt_in[10]=1; wt_in[11]=0;  // Row 2
        wt_in[12]=0; wt_in[13]=0; wt_in[14]=0; wt_in[15]=1;  // Row 3
        
        load_wt = 1; @(posedge clk); #1; load_wt = 0;

        // 3. STREAM MATRIX A WITH AUTOMATIC STAGGERING
        $display("\n--- STREAMING MATRIX A INTO ARRAY ---");
        
        // Loop for 15 cycles (enough time to feed 4x4 data + stagger delays + let it drain)
        for (t = 0; t < 15; t = t + 1) begin
            
            // For each of the 4 rows on the left side
            for (row = 0; row < 4; row = row + 1) begin
                
                // The Stagger Formula: Row 'r' waits 'r' cycles to start.
                // It then feeds 4 pixels, and goes back to 0.
                if ((t >= row) && (t < row + 4)) begin
                    data_in[row] = matrix_A[row][t - row]; 
                end else begin
                    data_in[row] = 0; // Feed zeros if waiting or finished
                end
            end
            
            @(posedge clk); #1; // Advance time by 1 clock cycle
        end

        $display("\n--- MATH COMPLETE ---");
        $finish;
    end

    // 4. PRINT THE OUTPUTS AS THEY DROP OUT THE BOTTOM
    always @(posedge clk) begin
        if (!rst) begin
            $display("Cycle %0d | Outputs (Matrix C) -> Col0:%2d | Col1:%2d | Col2:%2d | Col3:%2d", 
                     cycle_count, acc_out[0], acc_out[1], acc_out[2], acc_out[3]);
        end
    end
    initial begin 
        $dumpfile("systolic_array.vcd");
        $dumpvars(0,systolic_array_tb);
    end

endmodule
    