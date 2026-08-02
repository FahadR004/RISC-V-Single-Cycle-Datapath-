module PC_Register #(
    parameter ADDR_WIDTH = 32
) (
    input clk,
    input rst_n,
    input pc_write, // From Hazard Unit
    input [ADDR_WIDTH-1:0] next_pc, // Next PC value (Byte Address)
    output reg [ADDR_WIDTH-1:0] pc_current // Current PC value (Byte Address)
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_current <= {ADDR_WIDTH{1'b0}};  // Reset 
        else if (pc_write)
            pc_current <= next_pc;  // Update value to next address     
        else
            pc_current <= pc_current;  // Hold current address            
    end

endmodule