module counter_parameterized # (
    parameter RED_LENGTH = 15,
    parameter YELLOW_LENGTH = 5,
    parameter GREEN_LENGTH = 15
)(
    input logic clk,
    input logic reset,  // Assumed to be synchronized to clk's domain before passing in
    output logic power_red,
    output logic power_yellow,
    output logic power_green
);

typedef enum {
    init, 
    red,
    yellow,
    green
} light_state;

light_state current_state;

// Calculate the largest max value to define the the counter width
localparam int MAX_VALUE =  (RED_LENGTH > YELLOW_LENGTH) ? 
                            ((RED_LENGTH > GREEN_LENGTH) ? RED_LENGTH : GREEN_LENGTH) :
                            ((YELLOW_LENGTH > GREEN_LENGTH) ? YELLOW_LENGTH : GREEN_LENGTH);

logic [$clog2(MAX_VALUE):0] count;

always_ff @(posedge clk) begin
    if(reset) begin
        current_state <= init;
    end else begin
        case (current_state)
            init: begin
                count <= 'b0;
                power_red <= 'b0;
                power_yellow <= 'b0;
                power_green <= 'b0;
                current_state <= red;
            end
            red: begin
                power_red <= 'b1;
                power_yellow <= 'b0;
                power_green <= 'b0;
                if (count == RED_LENGTH-1) begin
                    count <= 0;
                    current_state <= green;
                end else begin
                    count <= count + 1;
                end
            end
            yellow: begin
                power_red <= 'b0;
                power_yellow <= 'b1;
                power_green <= 'b0;
                if (count == YELLOW_LENGTH-1) begin
                    count <= 0;
                    current_state <= red;
                end else begin
                    count <= count + 1;
                end
            end
            green: begin
                power_red <= 'b0;
                power_yellow <= 'b0;
                power_green <= 'b1;
                if (count == GREEN_LENGTH-1) begin
                    count <= 0;
                    current_state <= yellow;
                end else begin
                    count <= count + 1;
                end
            end
        endcase
    end

end

endmodule