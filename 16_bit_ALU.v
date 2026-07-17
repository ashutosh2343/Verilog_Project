// 16-Bit Pipelined Arithmetic Logic Unit (ALU)
module alu_16bit (
    input             clk,         // System Clock
    input             rst_n,       // Active-low synchronous reset
    input      [15:0] a_in,        // 16-bit input operand A
    input      [15:0] b_in,        // 16-bit input operand B
    input      [3:0]  alu_sel_in,  // 4-bit operation select line
    output reg [15:0] alu_out,     // 16-bit registered output result
    output reg        carry_out,   // Registered carry-out flag
    output reg        zero,        // Registered zero flag
    output reg        negative     // Registered negative flag (MSB)
);

    // --- STAGE 1: Input Registers (Pipeline Stage 1) ---
    reg [15:0] r1_a, r1_b;
    reg [3:0]  r1_sel;

    always @(posedge clk) begin
        if (!rst_n) begin
            r1_a   <= 16'h0000;
            r1_b   <= 16'h0000;
            r1_sel <= 4'b0000;
        end else begin
            r1_a   <= a_in;
            r1_b   <= b_in;
            r1_sel <= alu_sel_in;
        end
    end

    // --- STAGE 2: Combinational Execution Logic ---
    reg [16:0] ext_result;
    reg [15:0] exec_out;
    reg        exec_carry;

    always @(*) begin
        // Safe defaults to prevent latching
        ext_result = 17'h00000;
        exec_out   = 16'h0000;
        exec_carry = 1'b0;

        case (r1_sel)
            // --- Arithmetic Operations ---
            4'b0000: begin // Addition
                ext_result = {1'b0, r1_a} + {1'b0, r1_b};
                exec_out   = ext_result[15:0];
                exec_carry = ext_result[16];
            end
            4'b0001: begin // Subtraction (Borrow represented via carry)
                ext_result = {1'b0, r1_a} - {1'b0, r1_b};
                exec_out   = ext_result[15:0];
                exec_carry = ext_result[16]; 
            end
            4'b0010: exec_out = r1_a * r1_b; // Multiplication (Lower 16 bits)
            4'b0011: exec_out = (r1_b != 16'h0000) ? (r1_a / r1_b) : 16'h0000; // Safe Div
            4'b0100: exec_out = r1_a + 1'b1; // Increment A
            4'b0101: exec_out = r1_a - 1'b1; // Decrement A

            // --- Logical Operations ---
            4'b0110: exec_out = r1_a & r1_b;   // AND
            4'b0111: exec_out = r1_a | r1_b;   // OR
            4'b1000: exec_out = r1_a ^ r1_b;   // XOR
            4'b1001: exec_out = ~(r1_a & r1_b);// NAND
            4'b1010: exec_out = ~(r1_a | r1_b);// NOR
            4'b1011: exec_out = ~(r1_a ^ r1_b);// XNOR
            4'b1100: exec_out = ~r1_a;         // NOT A

            // --- Shift Operations ---
            4'b1101: exec_out = r1_a << 1;     // SLL
            4'b1110: exec_out = r1_a >> 1;     // SRL

            // --- Comparison ---
            4'b1111: exec_out = (r1_a < r1_b) ? 16'h0001 : 16'h0000;

            default: exec_out = 16'h0000;
        endcase
    end

    // --- STAGE 3: Output Registers (Pipeline Stage 2 Writeback) ---
    always @(posedge clk) begin
        if (!rst_n) begin
            alu_out   <= 16'h0000;
            carry_out <= 1'b0;
            zero      <= 1'b0;
            negative  <= 1'b0;
        end else begin
            alu_out   <= exec_out;
            carry_out <= exec_carry;
            zero      <= (exec_out == 16'h0000);
            negative  <= exec_out[15]; // Two's complement sign-bit tracking
        end
    end

endmodule
