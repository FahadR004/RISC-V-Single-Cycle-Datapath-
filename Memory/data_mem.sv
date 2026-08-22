module data_memory #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 1024
)(
    input clk,
    input logic [ADDR_WIDTH-1:0] address, // byte address
    input logic memRead,
    input logic memWrite,
    input logic [DATA_WIDTH-1:0] write_data,

    output logic [DATA_WIDTH-1:0] read_data
); 

logic [DATA_WIDTH-1:0] memory [0:DEPTH-1];

// Byte to word address conversion
logic [$clog2(DEPTH)-1:0] word_address;
assign word_address = address[$clog2(DEPTH)+1 : 2]; // $clog2(1024) returns 10. We require 10 bits to address 1024 words. 
// However, if we did 10:2, then we would only have 9-bits. Hence, we add plus one. So, we can have a total of 10-bits.
// Additionally, shift by 2 is equivalent to divide by 4. A word has 4 bytes, so we require 2 less bits to address a word.

always_ff @(posedge clk) begin 
    if (memWrite) begin
        memory[word_address] <= write_data;
    end
end

always_comb begin
    if (memRead) begin
        read_data = memory[word_address];
    end else begin
        read_data = {DATA_WIDTH{1'b0}};
    end
end
// initial begin
//     $readmemh("instructions.hex", memory);
// end

endmodule
