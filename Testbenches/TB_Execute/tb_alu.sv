`timescale 1ns/1ps

module tb_alu;

localparam DATA_WIDTH = 32;

logic [3:0] alu_control;
logic [DATA_WIDTH-1:0] alu_src_a;
logic [DATA_WIDTH-1:0] alu_src_b;
logic [DATA_WIDTH-1:0] result;
logic zero;

int errors = 0;
int checks = 0;

localparam ALU_ADD  = 4'b0000;
localparam ALU_SUB  = 4'b0001;
localparam ALU_SLL  = 4'b0010;
localparam ALU_SLT  = 4'b0011;
localparam ALU_SLTU = 4'b0100;
localparam ALU_XOR  = 4'b0101;
localparam ALU_SRL  = 4'b0110;
localparam ALU_SRA  = 4'b0111;
localparam ALU_OR   = 4'b1000;
localparam ALU_AND  = 4'b1001;
localparam ALU_LUI  = 4'b1010;

alu #(
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .alu_control (alu_control),
    .alu_src_a   (alu_src_a),
    .alu_src_b   (alu_src_b),
    .result      (result),
    .zero        (zero)
);

task automatic check(
    input string name,
    input logic [DATA_WIDTH-1:0] got_result,
    input logic [DATA_WIDTH-1:0] exp_result,
    input logic                  got_zero,
    input logic                  exp_zero
);
    checks++;
    if (got_result !== exp_result || got_zero !== exp_zero) begin
        errors++;
        $display("[FAIL] %s: expected result=%0h zero=%0b, got result=%0h zero=%0b",
                  name, exp_result, exp_zero, got_result, got_zero);
    end else begin
        $display("[PASS] %s: result=%0h zero=%0b", name, got_result, got_zero);
    end
endtask

initial begin
    $dumpfile("tb_alu.vcd");
    $dumpvars(0, tb_alu);
end

initial begin
    $display("=== ALU Testbench ===");

    $display("\n-- ADD --");
    alu_control = ALU_ADD; alu_src_a = 32'd10; alu_src_b = 32'd15;
    #1; check("add_basic", result, 32'd25, zero, 1'b0);

    alu_control = ALU_ADD; alu_src_a = 32'hFFFFFFFF; alu_src_b = 32'd1; // -1 + 1
    #1; check("add_overflow_to_zero", result, 32'h0, zero, 1'b1);

    $display("\n-- SUB --");
    alu_control = ALU_SUB; alu_src_a = 32'd20; alu_src_b = 32'd5;
    #1; check("sub_basic", result, 32'd15, zero, 1'b0);

    alu_control = ALU_SUB; alu_src_a = 32'd7; alu_src_b = 32'd7;
    #1; check("sub_equal_operands_zero", result, 32'h0, zero, 1'b1);

    alu_control = ALU_SUB; alu_src_a = 32'd5; alu_src_b = 32'd10; // negative result
    #1; check("sub_negative_result", result, 32'hFFFFFFFB, zero, 1'b0);

    $display("\n-- AND / OR / XOR --");
    alu_control = ALU_AND; alu_src_a = 32'hF0F0F0F0; alu_src_b = 32'h0FF00FF0;
    #1; check("and_basic", result, 32'h00F000F0, zero, 1'b0);

    alu_control = ALU_AND; alu_src_a = 32'hAAAA0000; alu_src_b = 32'h55550000;
    #1; check("and_result_zero", result, 32'h0, zero, 1'b1);

    alu_control = ALU_OR; alu_src_a = 32'hF0F0F0F0; alu_src_b = 32'h0F0F0F0F;
    #1; check("or_basic", result, 32'hFFFFFFFF, zero, 1'b0);

    alu_control = ALU_OR; alu_src_a = 32'h0; alu_src_b = 32'h0;
    #1; check("or_result_zero", result, 32'h0, zero, 1'b1);

    alu_control = ALU_XOR; alu_src_a = 32'hFFFF0000; alu_src_b = 32'h0000FFFF;
    #1; check("xor_basic", result, 32'hFFFFFFFF, zero, 1'b0);

    alu_control = ALU_XOR; alu_src_a = 32'hDEADBEEF; alu_src_b = 32'hDEADBEEF;
    #1; check("xor_identical_zero", result, 32'h0, zero, 1'b1);

    $display("\n-- SLL / SRL / SRA --");
    alu_control = ALU_SLL; alu_src_a = 32'h0000_0001; alu_src_b = 32'd4;
    #1; check("sll_basic", result, 32'h0000_0010, zero, 1'b0);

    // shamt uses only bottom 5 bits; upper bits of alu_src_b must be ignored
    alu_control = ALU_SLL; alu_src_a = 32'h0000_0001; alu_src_b = 32'hFFFF_FFE4; // low 5 bits = 4
    #1; check("sll_shamt_masked", result, 32'h0000_0010, zero, 1'b0);

    alu_control = ALU_SRL; alu_src_a = 32'h8000_0000; alu_src_b = 32'd4;
    #1; check("srl_logical_no_sign_ext", result, 32'h0800_0000, zero, 1'b0);

    alu_control = ALU_SRA; alu_src_a = 32'h8000_0000; alu_src_b = 32'd4;
    #1; check("sra_sign_extends", result, 32'hF800_0000, zero, 1'b0);

    alu_control = ALU_SRA; alu_src_a = 32'h7000_0000; alu_src_b = 32'd4; // positive, no sign ext
    #1; check("sra_positive_no_sign_ext", result, 32'h0700_0000, zero, 1'b0);

    alu_control = ALU_SRL; alu_src_a = 32'h0000_00F0; alu_src_b = 32'd8;
    #1; check("srl_shift_to_zero", result, 32'h0, zero, 1'b1);

    $display("\n-- SLT / SLTU --");
    alu_control = ALU_SLT; alu_src_a = 32'd5; alu_src_b = 32'd10; // 5 < 10 -> 1
    #1; check("slt_true", result, 32'd1, zero, 1'b0);

    alu_control = ALU_SLT; alu_src_a = 32'd10; alu_src_b = 32'd5; // 10 < 5 -> 0
    #1; check("slt_false_result_zero", result, 32'd0, zero, 1'b1);

    // signed comparison: -1 < 1 must be true even though -1 is a large unsigned value
    alu_control = ALU_SLT; alu_src_a = 32'hFFFFFFFF; alu_src_b = 32'd1;
    #1; check("slt_signed_negative_lt_positive", result, 32'd1, zero, 1'b0);

    alu_control = ALU_SLTU; alu_src_a = 32'd5; alu_src_b = 32'd10;
    #1; check("sltu_true", result, 32'd1, zero, 1'b0);

    // unsigned comparison: 0xFFFFFFFF is huge unsigned, so NOT less than 1
    alu_control = ALU_SLTU; alu_src_a = 32'hFFFFFFFF; alu_src_b = 32'd1;
    #1; check("sltu_unsigned_large_not_lt", result, 32'd0, zero, 1'b1);

    $display("\n-- LUI (pass-through) --");
    alu_control = ALU_LUI; alu_src_a = 32'hDEAD_BEEF; alu_src_b = 32'hABCDE000;
    #1; check("lui_passes_src_b_ignores_src_a", result, 32'hABCDE000, zero, 1'b0);

    alu_control = ALU_LUI; alu_src_a = 32'h0; alu_src_b = 32'h0;
    #1; check("lui_zero_immediate", result, 32'h0, zero, 1'b1);

    $display("\n-- default / unused control code --");
    alu_control = 4'b1111; alu_src_a = 32'hFFFF_FFFF; alu_src_b = 32'hFFFF_FFFF;
    #1; check("default_case_zero_output", result, 32'h0, zero, 1'b1);

    $display("\n=== Testbench complete: %0d/%0d passed ===", checks - errors, checks);
    if (errors == 0)
        $display("ALL TESTS PASSED");
    else
        $display("%0d TEST(S) FAILED", errors);

    $finish;
end

endmodule