// This module counts up to the MAX_VALUE and then overflows, indicating an overflow with the overflow bit
// The reset is assumed to be synchronized to clk's domain already

module counter_parameterized # (
    parameter MAX_VALUE = 64;
)(
    input logic clk,
    input logic reset,
    output logic [($clog2(MAX_VALUE)-1):0] count,
    output logic overflow
);

// Counter with an overflow bit, which is set high for 1 clock cycle after an overflow
always_ff @(posedge clk) begin
    if (reset) begin
        count <= 'b0;
        overflow <= 'b0;
    end else if (count == MAX_VALUE) begin
        count <= 'b0;
        overflow <= 'b1;
    end else begin
        count <= count + 1;
        overflow <= 'b0;
    end
end

endmodule