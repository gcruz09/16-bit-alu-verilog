`timescale 1ns/1ps

module tb_alu16;

    //inputs to ALU
    reg [15:0] a, b;
    reg [3:0] op;
    //outputs from ALU
    wire [15:0] result;
    wire zero, carry, negative, overflow;

    //plug ALU into the testbench
    alu16 dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .zero(zero),
        .carry(carry),
        .negative(negative),
        .overflow(overflow)
    );
    // Opcodes (same values as in alu16.v)
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_SLL = 4'b0101;
    localparam OP_SRL = 4'b0110;
    localparam OP_SRA = 4'b0111;

    integer pass_count;
    integer fail_count;

    task check;
        input [3:0]  t_op;
        input [15:0] t_a, t_b;
        input [15:0] exp_result;
        input        exp_zero, exp_carry, exp_neg, exp_ovf;
        begin
            op = t_op; a = t_a; b = t_b;
            #10;
            if (result === exp_result && zero === exp_zero &&
                carry === exp_carry && negative === exp_neg &&
                overflow === exp_ovf) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: op=%b a=%h b=%h", t_op, t_a, t_b);
                $display("  got      result=%h Z=%b C=%b N=%b V=%b",
                         result, zero, carry, negative, overflow);
                $display("  expected result=%h Z=%b C=%b N=%b V=%b",
                         exp_result, exp_zero, exp_carry, exp_neg, exp_ovf);
            end
        end
    endtask
    
    
    initial begin
        $dumpfile("alu16.vcd");
        $dumpvars(0, tb_alu16);
        pass_count = 0;
        fail_count = 0;

        //     op      a        b       result   Z C N V
        check(OP_ADD, 16'd5,   16'd3,   16'd8,    0,0,0,0);   // basic add
        check(OP_ADD, 16'h7FFF,16'h0001,16'h8000, 0,0,1,1);   // signed overflow
        check(OP_ADD, 16'hFFFF,16'h0001,16'h0000, 1,1,0,0);   // carry + zero
        check(OP_SUB, 16'd5,   16'd3,   16'd2,    0,1,0,0);   // no borrow -> C=1
        check(OP_SUB, 16'd3,   16'd5,   16'hFFFE, 0,0,1,0);   // borrow -> C=0, negative
        
        
        // Logic ops
        check(OP_AND, 16'hF0F0, 16'hFF00, 16'hF000, 0,0,1,0);
        check(OP_OR,  16'h00F0, 16'h0F00, 16'h0FF0, 0,0,0,0);
        check(OP_XOR, 16'hAAAA, 16'hAAAA, 16'h0000, 1,0,0,0);   // zero result
        check(OP_XOR, 16'hFFFF, 16'h0F0F, 16'hF0F0, 0,0,1,0);

        // shifts (b = shift amount)
        check(OP_SLL, 16'h0001, 16'd4,    16'h0010, 0,0,0,0);
        check(OP_SLL, 16'h8000, 16'd1,    16'h0000, 1,0,0,0);   // top bit shifted out
        check(OP_SLL, 16'h1234, 16'd0,    16'h1234, 0,0,0,0);   // shift by 0
        check(OP_SRL, 16'h8000, 16'd1,    16'h4000, 0,0,0,0);   // logical: fills with 0
        check(OP_SRA, 16'h8000, 16'd1,    16'hC000, 0,0,1,0);   // arithmetic: fills with sign bit
        check(OP_SRA, 16'h8000, 16'd15,   16'hFFFF, 0,0,1,0);

        check(OP_SRL, 16'hFFFF, 16'd4,    16'h0FFF, 0,0,0,0);
        check(OP_SRA, 16'hFFF0, 16'd4,    16'hFFFF, 0,0,1,0);
        check(OP_SUB, 16'h0000, 16'h0001, 16'hFFFF, 0,0,1,0);
        check(OP_SLL, 16'h4000, 16'd1,    16'h8000, 0,0,1,0); 

        // arithmetic edge cases
        check(OP_SUB, 16'd5,    16'd5,    16'h0000, 1,1,0,0);   // equal -> zero, no borrow
        check(OP_SUB, 16'h8000, 16'h0001, 16'h7FFF, 0,1,0,1);   // signed overflow on SUB
        check(OP_ADD, 16'h8000, 16'h8000, 16'h0000, 1,1,0,1);   // negative + negative overflows
        
        $display("Done: %0d passed, %0d failed", pass_count, fail_count);
        $finish;
    end
endmodule