`timescale 1us/1ns

`define SYS_CLK_HALF_PERIOD 5ns
`define PS2_CLK_HALF_PERIOD 30us
`define PS2_DATA_WIDTH 8
`define DELETE_CODE 8'hF0
`define TYPEMATIC_PERIOD 100ms
`define SMALL_USER_DELAY 5ms

module ps2_receiver_tb;
    logic async_rst;
    logic sys_clk;

    logic ps2_clk;
    logic ps2_data;

    logic [`PS2_DATA_WIDTH-1:0] key;

    ps2_receiver dut(
        .async_rst(async_rst),
        .sys_clk(sys_clk),
        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),
        .key(key)
    );

    task automatic reset();
        ps2_clk = 1;
        ps2_data = 1;
        async_rst = 1;
        #10;
        async_rst = 0;
    endtask

    task automatic sys_clk_gen();
        sys_clk = 0;
        forever begin
            #`SYS_CLK_HALF_PERIOD;
            sys_clk = ~sys_clk;
        end
    endtask

    task automatic ps2_transaction(input logic [`PS2_DATA_WIDTH-1:0] data);
        // Start bit
        ps2_clk = 1;
        ps2_data = 0;
        #`PS2_CLK_HALF_PERIOD;
        ps2_clk = 0;
        #`PS2_CLK_HALF_PERIOD;
        
        // Data bits
        for (int i = 0; i < `PS2_DATA_WIDTH; i++) begin
            ps2_clk = 1;
            ps2_data = data[i];
            #`PS2_CLK_HALF_PERIOD;
            ps2_clk = 0;
            #`PS2_CLK_HALF_PERIOD;
        end

        // Parity bit (ignore)
        ps2_clk = 1;
        ps2_data = 1;
        #`PS2_CLK_HALF_PERIOD;
        ps2_clk = 0;
        #`PS2_CLK_HALF_PERIOD;

        // Stop bit
        ps2_clk = 1;
        ps2_data = 1;
        #`PS2_CLK_HALF_PERIOD;
        ps2_clk = 0;
        #`PS2_CLK_HALF_PERIOD;
    endtask

    task automatic key_press(input logic [`PS2_DATA_WIDTH-1:0] scan_code);
        ps2_transaction(scan_code);
    endtask

    task automatic key_delete(input logic [`PS2_DATA_WIDTH-1:0] scan_code);
        ps2_transaction(`DELETE_CODE);
        ps2_transaction(scan_code);
    endtask

    initial begin
        sys_clk_gen();
    end

    /*
    initial begin
        $shm_open("waves.shm");
        $shm_probe("AS");   // A=all, S=signals (dumps whole hierarchy)
    end
    */

    /* 
    Tests behavior if a user continuously holds down a key.
    According to PS/2 protocol, a continuously held key will send its scan code
    every
    Ideally, "key" output should hold the scan code initially received.
    */
    task automatic test_hold_key();
        // 0x15 (Q) scan code will be tested
        for (int i = 0; i < 5; i++) begin
            key_press(8'h0x15);
            #`TYPEMATIC_PERIOD;
        end

        assert(key == 8'h0x15) begin
        end else begin
            $display("[FAIL]: Test Hold Key fails. 'key' does not match scan code.");
        end

        key_delete(8'h0x15);

        assert(key == 8'h00) begin
            $display("[PASS]: Test Hold Key successful.");
        end else begin
            $display("[FAIL]: Test Hold Key fails. 'key' did not reset to 0 correctly.");
        end
    endtask

    /*
    Tests behavior if a user continuously holds a key while pressing others.
    The first key pressed/hold should remained latched in "key".
    */
    task automatic test_hold_primary_key();
        // 0x1D (W) scan code will be tested
        key_press(8'h0x1D);
        #`TYPEMATIC_PERIOD;
        key_press(8'h0x1D);

        // User now randomly presses/releases keys
        key_press(8'h0x15); // Q
        #`SMALL_USER_DELAY;
        key_delete(8'h0x15);

        key_press(8'h0x2D); // R
        #`SMALL_USER_DELAY;
        key_delete(8'h0x2D);

        assert(key == 8'h0x1D) begin
        end else begin
            $display("[FAIL]: Test Hold Primary Key fails. 'key' does not match scan code.");
        end

        key_delete(8'h0x1D);

        assert(key == 8'h0x00) begin
            $display("[SUCCESS]: Test Hold Primary Key successful.");
        end else begin
            $display("[FAIL]: Test Hold Primary Key fails. 'key' did not reset to 0 correctly.");
        end

    endtask


    initial begin
        reset();
        //test_hold_key();
        //$display("Key: %0h", key);
        test_hold_primary_key();
        $finish;
    end
endmodule