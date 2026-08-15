module control_unit #(
    parameter ADDR_WIDTH  = 32,
    parameter INSTR_WIDTH = 32,
    parameter DATA_WIDTH  = 32,
    parameter REG_NUMS    = 32
) (
    input  logic [INSTR_WIDTH-1:0] instruction,

    // Control Signals Output
    output logic       regDst,
    output logic       branch,     // conditional branch (BEQ, BNE, ...)
    output logic       jump,       // unconditional jump, target = PC + imm (JAL)
    output logic       jalr,       // unconditional jump, target = rs1 + imm (JALR)
    output logic       memRead,
    output logic       memToReg,
    output logic [1:0] aluOp,      // coarse category only, NOT the final ALU op
    output logic       memWrite,
    output logic       aluSrc,
    output logic       regWrite,

    output logic [6:0] opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7
);

logic [6:0] opcode_bits;

assign opcode      = opcode_bits;
assign opcode_bits = instruction[6:0];
assign funct3      = instruction[14:12];
assign funct7      = instruction[31:25];

// aluOp == 00 -> For ADD (for load/store)
// aluOp == 01 -> For SUB (for branch)
// aluOp == 10 -> For R-type and I-type arithmetic (defer to funct3/funct7)

always_comb begin
    // Default
    regDst   = 0;
    branch   = 0;
    jump     = 0;
    jalr     = 0;
    memRead  = 0;
    memToReg = 0;
    aluOp    = 2'b00;
    memWrite = 0;
    aluSrc   = 0;
    regWrite = 0;

    case (opcode_bits)
        // Load Instructions (I-type)
        7'h03: begin  // LW, LB, LH, LBU, LHU
            memRead  = 1;
            memToReg = 1;
            aluOp    = 2'b00;   // ADD (address calc)
            aluSrc   = 1;       // immediate
            regWrite = 1;
        end

        // Arithmetic Immediate (I-type)
        7'h13: begin  // ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI
            aluOp    = 2'b10;   // defer to funct3/funct7 in alu_control
            aluSrc   = 1;       // immediate
            regWrite = 1;
        end

        // JALR (I-type)
        7'h67: begin  // JALR
            jalr     = 1;
            aluOp    = 2'b00;   // ADD (rs1 + imm)
            aluSrc   = 1;       // immediate
            regWrite = 1;       // save return address (PC+4)
        end

        // Arithmetic (R-type)
        7'h33: begin  // ADD, SUB, AND, OR, XOR, SLL, SRL, SRA
            regDst   = 1;
            aluOp    = 2'b10;   // defer to funct3/funct7 in alu_control
            aluSrc   = 0;       // register
            regWrite = 1;
        end

        // Store Instructions (S-type)
        7'h23: begin  // SW, SB, SH
            aluOp    = 2'b00;   // ADD (address calc)
            memWrite = 1;
            aluSrc   = 1;       // immediate
        end

        // Branch Instructions (B-type)
        7'h63: begin  // BEQ, BNE, BLT, BGE, BLTU, BGEU
            branch   = 1;
            aluOp    = 2'b01;   // SUBTRACT (comparison)
            aluSrc   = 0;       // register
        end

        // JAL (J-type)
        7'h6F: begin  // JAL
            jump     = 1;
            regWrite = 1;       // save return address (PC+4)
        end

        // Upper Immediate (U-type)
        7'h37: begin  // LUI
            aluOp    = 2'b11;   // pass-through / load-upper-immediate
            aluSrc   = 1;       // immediate
            regWrite = 1;
        end

        // Add Upper Immediate to PC (U-type)
        7'h17: begin  // AUIPC
            aluOp    = 2'b00;   // ADD (PC + immediate)
            aluSrc   = 1;       // immediate
            regWrite = 1;
        end
    endcase
end

endmodule