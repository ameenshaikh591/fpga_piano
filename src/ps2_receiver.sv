/*
Author: Ameen Shaikh
Basic PS/2 Keyboard Receiver module
Receives PS/2 Keyboard transactions and updates "key" register
to the scan code of the currently pressed key. If no key is being
pressed, "key" will hold the value of 0.

LSB first.
*/
`define PS2_DATA_WIDTH 8
`define COUNTER_WIDTH 4
`define MSB 7

module ps2_receiver (
    input logic async_rst,
    input logic sys_clk,

    input logic ps2_clk,
    input logic ps2_data,

    output logic [`PS2_DATA_WIDTH-1:0] key
);

    // 4-bit counter to keep track of incoming bits
    logic [`COUNTER_WIDTH-1:0] counter;

    // ps2_clk synchronizers and edge detection
    logic ps2_clk_1;
    logic ps2_clk_2;
    logic ps2_clk_3;

    logic falling_edge; // asserted when falling edge detected on "ps2_clk"

    // ps2_data synchronizers
    logic ps2_data_1;
    logic ps2_data_2;

    // async_rst synchronizers
    logic async_rst_1;
    logic async_rst_2;

    logic reset; // asserted when async_rst is asserted

    always_comb begin
        falling_edge = ps2_clk_3 & ~ps2_clk_2;
        reset = async_rst_2;
    end

    logic [`PS2_DATA_WIDTH-1:0] shift_register;
    logic break_flag;

    always_ff @(posedge sys_clk) begin
        async_rst_1 <= async_rst;
        async_rst_2 <= async_rst_1;

        if (reset) begin
            counter <= 0;
            shift_register <= 0;
            key <= 0;
            break_flag <= 0;
        end else begin
            ps2_clk_1 <= ps2_clk;
            ps2_clk_2 <= ps2_clk_1;
            ps2_clk_3 <= ps2_clk_2;

            ps2_data_1 <= ps2_data;
            ps2_data_2 <= ps2_data_1;

            if (falling_edge) begin
                if (counter == 0) begin
                    // Start bit
                    counter <= counter + 1;
                end else if (counter < 9) begin
                    // Data bits
                    shift_register[`MSB] <= ps2_data_2;
                    shift_register[6:0] <= shift_register[7:1];
                    counter <= counter + 1;
                end else if (counter == 9) begin
                    // Parity bit
                    counter <= counter + 1;
                end else begin
                    // Stop bit
                    // Evaluate contents of "shift_register"
                    if (shift_register == 8'hF0) begin
                        break_flag <= 1;
                    end else begin
                        if (break_flag == 1) begin
                            if (shift_register == key) begin
                                key <= 8'h0;
                            end
                            break_flag <= 0;
                        end else if (break_flag == 0 && key == 8'h0) begin
                            key <= shift_register;
                        end
                    end
                    counter <= 0; 
                end
            end
        end
    end
endmodule