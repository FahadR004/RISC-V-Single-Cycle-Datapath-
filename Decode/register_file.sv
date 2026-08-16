module register_file #(
    parameter DATA_WIDTH = 32,
    parameter NUM_REGS = 32
) ( 
    // Register Numbers
    input logic [$clog2(REG_NUMS)-1:0] read_reg1, // rs1
    input logic [$clog2(REG_NUMS)-1:0] read_reg2, // rs2
    input logic [$clog2(REG_NUMS)-1:0] write_reg,

    // WriteBack Data
    input logic [DATA_WIDTH-1:0] write_data

    // Control Signals
    input logic regWrite,

    // Output of the Register File
    output logic [DATA_WIDTH-1:0] read_data1,
    output logic [DATA_WIDTH-1:0] read_data2
);

logic [DATA_WIDTH-1:0] registers [NUM_REGS-1:0];

always_comb begin 
    if (regWrite) begin
        registers[write_reg] = write_data;
    end
end

assign read_data1 = registers[read_reg1];
assign read_data2 = registers[read_reg2];


endmodule