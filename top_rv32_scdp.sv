    module rv32_scdp # (
        parameter ADDR_WIDTH = 32,
        parameter INSTR_WIDTH = 32, // 4 byte instruction
        parameter DEPTH = 1024    
    ) (
        input logic clk,
        input logic rst_n
    );

    logic [ADDR_WIDTH-1:0] pc_plus_4;

    logic [ADDR_WIDTH-1:0] next_pc;
    logic [INSTR_WIDTH-1:0] instruction;
    logic [ADDR_WIDTH-1:0] pc_current_addr;

    pc_adder #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) pc_adder_inst (
        .curr_pc(pc_current_addr),
        .pc_plus_4(pc_plus_4)
    );

    // Temporarily connected it as is. Will later be a mux
    assign next_pc = pc_plus_4;

    Fetch # (
        .ADDR_WIDTH(ADDR_WIDTH),
        .INSTR_WIDTH(INSTR_WIDTH),
        .DEPTH(DEPTH)
    ) fetch_stage (
        .clk(clk),
        .rst_n(rst_n),
        .next_pc(next_pc), // PC+4 from adder to increment PC value
        .instruction(instruction), // Output of the Fetch Stage is a 32-bit instruction
        .current_pc(pc_current_addr) // Output of the Fetch Stage also includs the current PC address
    );

    // Decode 


    // Execute


    // Memory 


    // WriteBack

    endmodule