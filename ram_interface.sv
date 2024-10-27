// This module has a FIFO that queues up data to put into memory in order of received
// It also allows port b to be read from at any time with a request using enb and addrb

module ram_interface # (
    parameter BRAM_READ_LATENCY = 2,
    parameter FIFO_READ_LATENCY = 1,
    parameter WRITE_WIDTH = 64,
    parameter READ_WIDTH = 64,
    parameter TOTAL_SIZE = 64*128,
    parameter FIFO_DEPTH = 1024
)(
    input logic input_clk,  // This clock is used as the input to the fifo, allowing a CDC
    input logic bram_clk,   // This clock is used for the bram
    input logic reset,  // Assumed to be synchronized to clk's domain before passing in
    input logic din,            // This is connected directly to the fifo input
    input logic din_valid,      // This is connected directly to the fifo input
    input logic enb,
    input logic addrb,

    output logic fifo_overflow,
    output logic fifo_prog_full,
    output logic dout,
    output logic dout_valid,
    output logic read_error
);

typedef enum {
    idle,
    read,
    write
} bram_state;

bram_state current_state;

logic [FIFO_READ_LATENCY-1:0] fifo_valid;

localparam int MAX_ADDRESS_INDEX $clog2(TOTAL_SIZE/WRITE_WIDTH);    // Index sized based on params
logic [MAX_ADDRESS_INDEX-1:0] addra [FIFO_READ_LATENCY-1:0];

logic [BRAM_READ_LATENCY-1:0] bram_valid; 
logic sbiterrb, dbiterrb;

// This block controls streaming data from the fifo into the bram
assign fifo_overflow = fifo_full;
assign fifo_prog_full = fifo_prog_full

always_ff @(posedge bram_clk) begin
    if (reset) begin
        addra <= '{default: '0};
        fifo_valid <= 'b0;
    end else begin
        // If the fifo isnt empty, load data into the BRAM
        // These control signals are pipelined for the FIFO latency
        if (!empty) begin
            // Wrap around the address value, incrementing each time a value is written into the pipeline
            if (addra == (TOTAL_SIZE/WRITE_WIDTH)-1) begin
                addra[BRAM_READ_LATENCY-1:0] <= {addra[BRAM_READ_LATENCY-2:0], 'b0};
            end else begin
                addra[BRAM_READ_LATENCY-1:0] <= {addra[BRAM_READ_LATENCY-2:0], (addra[0]+1)};
            end
            fifo_valid[FIFO_READ_LATENCY-1:0] <= {fifo_valid[FIFO_READ_LATENCY-2:0], 1'b1}; // Pipeline a dvalid signal
        end else begin
            fifo_valid[FIFO_READ_LATENCY-1:0] <= {fifo_valid[FIFO_READ_LATENCY-2:0], 1'b0}; // Pipeline that data is not ready
        end

        // If the data is ready to pass from the FIFO to the BRAM, this value will be a 1
        if (fifo_valid[FIFO_READ_LATENCY-1] == 1'b1) begin
            dina <= fifo_dout;
        end
    end
end        
        

// This block controls the valid signal from the bram, pipelined to match the latency
assign read_error = sbiterrb | dbiterrb;
assign dout = doutb;

always_ff @(posedge bram_clk) begin
    if (reset) begin
        bram_valid <= '{default: '0};
    end else if (enb == 1'b1) begin
        bram_valid[BRAM_READ_LATENCY-1:0] <= {bram_valid[BRAM_READ_LATENCY-2:0], 1'b1}
    end
end

xpm_memory_sdpram #(
    .ADDR_WIDTH_A(6),             
    .ADDR_WIDTH_B(6),             
    .AUTO_SLEEP_TIME(0),          
    .BYTE_WRITE_WIDTH_A(WRITE_WIDTH),      
    .CASCADE_HEIGHT(0),           
    .CLOCKING_MODE("common_clock")
    .ECC_MODE("no_ecc"),          
    .MEMORY_INIT_FILE("none"),    
    .MEMORY_INIT_PARAM("0"),      
    .MEMORY_OPTIMIZATION("true"), 
    .MEMORY_PRIMITIVE("auto"),    
    .MEMORY_SIZE(TOTAL_SIZE),               //64b wide with 256 entries
    .MESSAGE_CONTROL(0),          
    .READ_DATA_WIDTH_B(READ_WIDTH),       
    .READ_LATENCY_B(READ_LATENCY),           
    .READ_RESET_VALUE_B("0"),     
    .RST_MODE_A("SYNC"),          
    .RST_MODE_B("SYNC"),          
    .SIM_ASSERT_CHK(0),           
    .USE_EMBEDDED_CONSTRAINT(0),  
    .USE_MEM_INIT(1),             
    .USE_MEM_INIT_MMI(0),         
    .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(32),      
    .WRITE_MODE_B("no_change"),   
    .WRITE_PROTECT(1)             
 ) xpm_memory_sdpram_inst (
    .dbiterrb(dbiterrb),            
    .doutb(doutb),                  
    .sbiterrb(sbiterrb),            
    .addra(addra),                  
    .addrb(addrb),                  
    .clka(bram_clk),                    
    .clkb(bram_clk),                    
    .dina(dina),                    
    .ena(ena),                      
    .enb(enb),                                                
    .injectdbiterra(injectdbiterra),
    .injectsbiterra(injectsbiterra),
    .regceb(regceb),                
    .rstb(rstb),                    
    .sleep(sleep),                  
    .wea(wea)                       
 );

 // This FIFO input could be wider and not match the input of the BRAM if we need more throughput
 xpm_fifo_async #(
    .CASCADE_HEIGHT(0),       
    .CDC_SYNC_STAGES(2),      
    .DOUT_RESET_VALUE("0"),   
    .ECC_MODE("no_ecc"),      
    .FIFO_MEMORY_TYPE("auto"),
    .FIFO_READ_LATENCY(FIFO_READ_LATENCY),    
    .FIFO_WRITE_DEPTH(FIFO_DEPTH),  
    .FULL_RESET_VALUE(0),     
    .PROG_EMPTY_THRESH(10),   
    .PROG_FULL_THRESH(FIFO_DEPTH-10),    
    .RD_DATA_COUNT_WIDTH(1),  
    .READ_DATA_WIDTH(WRITE_WIDTH),     
    .READ_MODE("std"),        
    .RELATED_CLOCKS(0),       
    .SIM_ASSERT_CHK(0),       
    .USE_ADV_FEATURES("0707"),
    .WAKEUP_TIME(0),          
    .WRITE_DATA_WIDTH(WRITE_WIDTH),    
    .WR_DATA_COUNT_WIDTH(1)   
 ) xpm_fifo_async_inst (
    .almost_empty(almost_empty),   
    .almost_full(almost_full),                                     
    .data_valid(fifo_data_valid),                                         
    .dbiterr(dbiterr),                                              
    .dout(fifo_dout),                                                    
    .empty(empty),                 
    .full(fifo_full),                   
    .overflow(fifo_overflow),           
    .prog_empty(prog_empty),       
    .prog_full(fifo_prog_full),
    .rd_data_count(rd_data_count), 
    .rd_rst_busy(rd_rst_busy),     
    .sbiterr(sbiterr),             
    .underflow(underflow),         
    .wr_ack(wr_ack),               
    .wr_data_count(wr_data_count), 
    .wr_rst_busy(wr_rst_busy),     
    .din(din),                     
    .injectdbiterr(injectdbiterr), 
    .injectsbiterr(injectsbiterr), 
    .rd_clk(bram_clk),               
    .rd_en(fifo_rd_en),                 
    .rst(reset),                     
    .sleep(sleep),                 
    .wr_clk(input_clk),               
    .wr_en(din_valid)                  
 );

endmodule