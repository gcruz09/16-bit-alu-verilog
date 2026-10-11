module alu16 (
    input  [15:0] a,
    input  [15:0] b,
    input  [3:0]  op,
    output reg [15:0] result,
    output reg zero,
    output reg carry,
    output reg negative,
    output reg overflow
);

    // Opcodes
    localparam OP_ADD = 4'b0000;
    localparam OP_SUB = 4'b0001;
    localparam OP_AND = 4'b0010;
    localparam OP_OR  = 4'b0011;
    localparam OP_XOR = 4'b0100;
    localparam OP_SLL = 4'b0101;
    localparam OP_SRL = 4'b0110;
    localparam OP_SRA = 4'b0111;

    // Signed view of 'a', needed for the arithmetic shift
    wire signed [15:0] a_s = a;

    // 17 bits so the carry-out has somewhere to go
    reg [16:0] tmp;

    always @* begin
        // Defaults: every output gets a value on every path
        result   = 16'b0;
        carry    = 1'b0;
        overflow = 1'b0;
        tmp      = 17'b0;

        case (op)
            OP_ADD: begin
                tmp      = {1'b0, a} + {1'b0, b};
                result   = tmp[15:0];
                carry    = tmp[16];
                overflow = (a[15] == b[15]) && (result[15] != a[15]);
            end

            OP_SUB: begin
                tmp      = {1'b0, a} + {1'b0, ~b} + 17'd1;
                result   = tmp[15:0];
                carry    = tmp[16];   // 1 = no borrow (ARM convention)
                overflow = (a[15] != b[15]) && (result[15] != a[15]);
            end

            OP_AND: result = a & b;
            OP_OR:  result = a | b;
            OP_XOR: result = a ^ b;

            OP_SLL: result = a << b[3:0];
            OP_SRL: result = a >> b[3:0];
            OP_SRA: result = a_s >>> b[3:0];

            default: result = 16'b0;
        endcase

        // Flags that depend only on the final result
        zero     = (result == 16'b0);
        negative = result[15];
    end

endmodule