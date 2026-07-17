// 16-Bit Arithmetic Logic Unit (ALU)
module alu_16bit (
    input  [15:0] a, b,       // 16-bit input operands
    input  [3:0]  alu_sel,     // 4-bit operation select line
    output reg [15:0] alu_out, // 16-bit output result
    output reg    carry_out,   // Carry out flag for addition/subtraction
    output        zero,        // Zero flag (1 if alu_out is 0)
    output        negative     // Negative flag (MSB of the output)
);

    // Internal 17-bit register to reliably calculate carry out
    reg [16:0] ext_result;

    // Zero flag and Negative flag assignments
    assign zero = (alu_out == 16'b0);
    assign negative = alu_out[15];

    always @(*) begin
        // Default resets to avoid latches
        carry_out = 1'b0;
        ext_result = 17'b0;
        
        case(alu_sel)
            // --- Arithmetic Operations ---
            4'b0000: begin // Addition
                ext_result = {1'b0, a} + {1'b0, b};
                alu_out   = ext_result[15:0];
                carry_out = ext_result[16];
            end
            4'b0001: begin // Subtraction
                ext_result = {1'b0, a} - {1'b0, b};
                alu_out   = ext_result[15:0];
                carry_out = ext_result[16]; // Borrows act as carry
            end
            4'b0010: alu_out = a * b;        // Multiplication (lower 16 bits)
            4'b0011: alu_out = (b != 0) ? (a / b) : 16'b0; // Division with 0 check
            4'b0100: alu_out = a + 1'b1;     // Increment A
            4'b0101: alu_out = a - 1'b1;     // Decrement A
            
            // --- Logical Operations ---
            4'b0110: alu_out = a & b;        // Bitwise AND
            4'b0111: alu_out = a | b;        // Bitwise OR
            4'b1000: alu_out = a ^ b;        // Bitwise XOR
            4'b1001: alu_out = ~(a & b);     // Bitwise NAND
            4'b1010: alu_out = ~(a | b);     // Bitwise NOR
            4'b1011: alu_out = ~(a ^ b);     // Bitwise XNOR
            4'b1100: alu_out = ~a;           // Bitwise NOT A
            
            // --- Shift Operations ---
            4'b1101: alu_out = a << 1;       // Logical Shift Left by 1
            4'b1110: alu_out = a >> 1;       // Logical Shift Right by 1
            
            // --- Comparison Operation ---
            4'b1111: alu_out = (a < b) ? 16'd1 : 16'd0; // Less Than comparison
            
            default: alu_out = 16'b0;
        endcase
    end
endmodule
