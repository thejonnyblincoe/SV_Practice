// This module allows two logic vectors of different bit widths to be added
// The parameters should be defined with the bitwidths

module adder_parameterized # (
    parameter WIDTH_1 = 8,
    parameter WIDTH_2 = 8
)(
    input logic clk,
    input logic [WIDTH_1-1:0] input_1,
    input logic [WIDTH_2-1:0] input_2,
    output logic [WIDTH_OUT:0] value    
);

    // Use whichever WIDTH is larger and add one to ensure no overflow
    localparam WIDTH_OUT = ((WIDTH_1 > WIDTH_2) ? WIDTH_1 : WIDTH_2) 

    // With proper widths defined, we can simply add the values
    assign value = input_1 + input_2;

endmodule