// This module assumes an asynchronous reset it passed in and synchronizes it
// Otherwise, the reset can be used straight up which is often the case if the reset is passed from PS or externally through the block diagram

module flip_flop_with_clkdiv # (
    parameter CLKDIV = 8
)(
    input logic clk,
    input logic async_reset,
    input logic signal,
    output logic signal_q
);

// Declare logic signals for internal logic
logic signal_i;
logic reset_q, reset_qq;
logic [$clog2(CLKDIV)-1:0] count;

// Synchronize the resets
always_ff @(posedge clk) begin
    if (async_reset) begin
        reset_q <= 'b1;
        reset_q <= 'b1;
    end else begin
        reset_q <= 'b0;
        reset_qq <= reset_q;
    end
end

// Flip flop with synchronized reset
always_ff @(posedge clk) begin
    if (reset_qq) begin
        signal_q <= 'b0;
        count <= 'b0;
    end else if (count == CLKDIV-1) begin
        signal_q <= signal;
        count <= 'b0;
    end else begin
        count <= count + 1;
    end
end

endmodule