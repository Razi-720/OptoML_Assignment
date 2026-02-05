`timescale 1ns/1ps

module pipeline_register_tb;

    // Parameters
    parameter int DATA_WIDTH = 32;
    parameter int CLK_PERIOD = 10;
    
    // DUT signals
    logic                    clk;
    logic                    rst;
    logic                    in_valid;
    logic                    in_ready;
    logic [DATA_WIDTH-1:0]   in_data;
    logic                    out_valid;
    logic                    out_ready;
    logic [DATA_WIDTH-1:0]   out_data;
    
    // Testbench variables
    int errors = 0;
    int test_num = 0;
    
    // Instantiate DUT
    pipeline_register #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .in_valid(in_valid),
        .in_ready(in_ready),
        .in_data(in_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .out_data(out_data)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Task to apply reset
    task automatic apply_reset();
        rst = 1;
        in_valid = 0;
        in_data = 0;
        out_ready = 0;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        $display("[%0t] Reset complete", $time);
    endtask
    
    // Task to drain pipeline
    task automatic drain_pipeline();
        in_valid = 0;
        out_ready = 1;
        repeat(3) @(posedge clk);
        out_ready = 0;
        @(posedge clk);
    endtask
    
    // Task to check expected output
    task automatic check_output(input logic [DATA_WIDTH-1:0] expected);
        if (out_data !== expected) begin
            $display("[%0t] ERROR: Expected out_data = 0x%h, got 0x%h", 
                     $time, expected, out_data);
            errors++;
        end else begin
            $display("[%0t] PASS: out_data = 0x%h", $time, out_data);
        end
    endtask
    
    // Main test sequence
    initial begin
        int i;
        logic [DATA_WIDTH-1:0] sent_queue[$];
        logic [DATA_WIDTH-1:0] received_queue[$];
        logic [DATA_WIDTH-1:0] temp_data;
        
        $display("========================================");
        $display("Pipeline Register Testbench");
        $display("========================================");
        
        // Initialize
        apply_reset();
        
        //-------------------------------------
        // Test 1: Reset state check
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Reset State Check", test_num);
        if (out_valid !== 0) begin
            $display("[%0t] ERROR: out_valid should be 0 after reset", $time);
            errors++;
        end
        if (in_ready !== 1) begin
            $display("[%0t] ERROR: in_ready should be 1 after reset (empty)", $time);
            errors++;
        end
        $display("[%0t] PASS: Reset state correct", $time);
        
        //-------------------------------------
        // Test 2: Single transfer
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Single Transfer", test_num);
        in_data = 32'hDEADBEEF;
        in_valid = 1;
        out_ready = 0;
        @(posedge clk);
        @(posedge clk);
        in_valid = 0;
        
        // Check data is stored
        if (out_valid !== 1) begin
            $display("[%0t] ERROR: out_valid should be 1", $time);
            errors++;
        end
        check_output(32'hDEADBEEF);
        
        // Check backpressure
        if (in_ready !== 0) begin
            $display("[%0t] ERROR: in_ready should be 0 (full, not draining)", $time);
            errors++;
        end
        
        // Consume data
        out_ready = 1;
        @(posedge clk);
        @(posedge clk);
        out_ready = 0;
        
        if (out_valid !== 0) begin
            $display("[%0t] ERROR: out_valid should be 0 after consumption", $time);
            errors++;
        end
        if (in_ready !== 1) begin
            $display("[%0t] ERROR: in_ready should be 1 (empty)", $time);
            errors++;
        end
        $display("[%0t] PASS: Single transfer completed", $time);
        
        //-------------------------------------
        // Test 3: Back-to-back transfers
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Back-to-back Transfers", test_num);
        out_ready = 1;  // Always ready
        
        for (i = 0; i < 5; i++) begin
            in_data = 32'h1000 + i;
            in_valid = 1;
            @(posedge clk);
        end
        in_valid = 0;
        
        $display("[%0t] PASS: Back-to-back transfers completed", $time);
        drain_pipeline();
        
        //-------------------------------------
        // Test 4: Backpressure handling
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Backpressure Handling", test_num);
        
        in_data = 32'hCAFEBABE;
        in_valid = 1;
        out_ready = 0;
        @(posedge clk);
        @(posedge clk);
        in_valid = 0;
        
        repeat(5) @(posedge clk);
        
        check_output(32'hCAFEBABE);
        if (out_valid !== 1) begin
            $display("[%0t] ERROR: Data should be held during backpressure", $time);
            errors++;
        end
        
        out_ready = 1;
        @(posedge clk);
        @(posedge clk);
        out_ready = 0;
        $display("[%0t] PASS: Backpressure handled correctly", $time);
        
        //-------------------------------------
        // Test 5: Simultaneous valid/ready
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Simultaneous Input/Output", test_num);
        
        in_data = 32'h5555AAAA;
        in_valid = 1;
        out_ready = 0;
        @(posedge clk);
        in_valid = 0;
        @(posedge clk);
        
        in_data = 32'hAAAA5555;
        in_valid = 1;
        out_ready = 1;
        @(posedge clk);
        
        @(posedge clk);
        check_output(32'hAAAA5555);
        
        out_ready = 1;
        @(posedge clk);
        @(posedge clk);
        in_valid = 0;
        out_ready = 0;
        $display("[%0t] PASS: Simultaneous operation works", $time);
        
        //-------------------------------------
        // Test 6: Sporadic input pattern
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Sporadic Input Pattern", test_num);
        
        for (i = 0; i < 10; i++) begin
            repeat($urandom_range(1, 3)) @(posedge clk);
            in_data = 32'h2000 + i;
            in_valid = 1;
            out_ready = $urandom_range(0, 1);
            @(posedge clk);
            in_valid = 0;
        end
        
        drain_pipeline();
        $display("[%0t] PASS: Sporadic pattern handled", $time);
        
        //-------------------------------------
        // Test 7: No data loss verification
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] No Data Loss Verification", test_num);
        
        sent_queue = {};
        received_queue = {};
        
        fork
            begin
                for (int j = 0; j < 20; j++) begin
                    temp_data = $urandom();
                    sent_queue.push_back(temp_data);
                    
                    in_data = temp_data;
                    in_valid = 1;
                    @(posedge clk);
                    
                    while (!in_ready) begin
                        @(posedge clk);
                    end
                    
                    in_valid = 0;
                    repeat($urandom_range(0, 2)) @(posedge clk);
                end
                in_valid = 0;
                $display("[%0t] Sender complete: sent %0d items", $time, sent_queue.size());
            end
            
            begin
                for (int j = 0; j < 20; j++) begin
                    while (!out_valid) begin
                        @(posedge clk);
                    end
                    
                    out_ready = 1;
                    @(posedge clk);
                    received_queue.push_back(out_data);
                    
                    out_ready = 0;
                    repeat($urandom_range(0, 2)) @(posedge clk);
                end
                out_ready = 0;
                $display("[%0t] Receiver complete: received %0d items", $time, received_queue.size());
            end
        join
        
        if (sent_queue.size() != received_queue.size()) begin
            $display("[%0t] ERROR: Size mismatch! Sent %0d, Received %0d", 
                     $time, sent_queue.size(), received_queue.size());
            errors++;
        end else begin
            for (i = 0; i < sent_queue.size(); i++) begin
                if (sent_queue[i] !== received_queue[i]) begin
                    $display("[%0t] ERROR: Data mismatch at index %0d! Sent 0x%h, Received 0x%h",
                             $time, i, sent_queue[i], received_queue[i]);
                    errors++;
                end
            end
            $display("[%0t] PASS: All %0d transactions completed without data loss", 
                     $time, sent_queue.size());
        end
        
        //-------------------------------------
        // Test 8: Reset during operation
        //-------------------------------------
        test_num++;
        $display("\n[TEST %0d] Reset During Operation", test_num);
        
        // Load data into register
        in_data = 32'hFFFFFFFF;
        in_valid = 1;
        out_ready = 0;
        @(posedge clk);
        @(posedge clk);
        
        // Stop sending - this is critical!
        in_valid = 0;
        in_data = 0;
        
        // Now reset
        rst = 1;
        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);
        
        // After reset, should be clear
        if (out_valid !== 0) begin
            $display("[%0t] ERROR: out_valid should be 0 after reset", $time);
            errors++;
        end else begin
            $display("[%0t] PASS: out_valid correctly cleared by reset", $time);
        end
        
        if (in_ready !== 1) begin
            $display("[%0t] ERROR: in_ready should be 1 after reset", $time);
            errors++;
        end
        
        $display("[%0t] PASS: Reset during operation works", $time);
        
        //-------------------------------------
        // Final Summary
        //-------------------------------------
        repeat(5) @(posedge clk);
        
        $display("\n========================================");
        $display("Test Summary");
        $display("========================================");
        $display("Total Tests: %0d", test_num);
        $display("Total Errors: %0d", errors);
        
        if (errors == 0) begin
            $display("*** ALL TESTS PASSED ***");
        end else begin
            $display("*** TESTS FAILED ***");
        end
        $display("========================================\n");
        
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #500000;
        $display("[%0t] ERROR: Testbench timeout!", $time);
        $finish;
    end
    
    // Optional: Waveform dumping
    initial begin
        $dumpfile("pipeline_register.vcd");
        $dumpvars(0, pipeline_register_tb);
    end

endmodule
