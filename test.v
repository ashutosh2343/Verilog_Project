`timescale 1ns / 1ps

module tb_alu_16bit;
    // Testbench inputs (declared as regs)
    reg [15:0] a;
    reg [15:0] b;
    reg [3:0]  alu_sel;

    // Testbench outputs (declared as wires)
    wire [15:0] alu_out;
    wire carry_out;
    wire zero;
    wire negative;

    // Instantiate the Unit Under Test (UUT)
    alu_16bit uut (
        .a(a), 
        .b(b), 
        .alu_sel(alu_sel), 
        .alu_out(alu_out), 
        .carry_out(carry_out), 
        .zero(zero), 
        .negative(negative)
    );

    initial begin
        // Monitor window for console logging
        $monitor("Time=%0dns | Sel=%b | A=%d, B=%d | Out=%d | Flags: C=%b Z=%b N=%b", 
                 $time, alu_sel, a, b, alu_out, carry_out, zero, negative);
        
        // Initialize Inputs
        a = 16'd45; b = 16'd15; alu_sel = 4'b0000; #10; // Test Add (45 + 15 = 60)
        alu_sel = 4'b0001; #10;                        // Test Sub (45 - 15 = 30)
        alu_sel = 4'b0010; #10;                        // Test Mul (45 * 15 = 675)
        alu_sel = 4'b0011; #10;                        // Test Div (45 / 15 = 3)
        
        a = 16'hFFFF; b = 16'h0001;
        alu_sel = 4'b0000; #10;                        // Test Add Overflow/Carry Rollover
        
        a = 16'h5555; b = 16'hAAAA;
        alu_sel = 4'b0110; #10;                        // Test Bitwise AND (Result should be 0, checking Zero Flag)
        alu_sel = 4'b0111; #10;                        // Test Bitwise OR
        
        a = 16'd10; b = 16'd20;
        alu_sel = 4'b1111; #10;                        // Test Less Than Comparison (10 < 20 = 1)
        
        $finish; // End simulation
    end
endmodule
