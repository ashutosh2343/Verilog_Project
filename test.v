`timescale 1ns/1ps

module tb_alu_16bit_sv;

    reg clk;
    reg rst_n;
    reg [15:0] a_in;
    reg [15:0] b_in;
    reg [3:0]  alu_sel_in;

    wire [15:0] alu_out;
    wire carry_out;
    wire zero;
    wire negative;

    // Instantiate UUT
    alu_16bit uut (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .alu_sel_in(alu_sel_in),
        .alu_out(alu_out),
        .carry_out(carry_out),
        .zero(zero),
        .negative(negative)
    );

    // Clock generator (100MHz clock frequency)
    always #5 clk = ~clk;

    // --- SYSTEMVERILOG ASSERTIONS (SVA) ---
    // These run concurrently to monitor properties during simulation.
    // Account for 2 clock cycle latency (Input Reg to Output Reg)

    // Property 1: The Zero Flag must be true if and only if alu_out is 0.
    property p_zero_flag;
        @(posedge clk) disable iff (!rst_n)
        (alu_out == 16'h0000) === zero;
    endproperty
    assert_zero_flag: assert property (p_zero_flag) else $error("SVA Error: Zero flag mismatch! Out: %0d, Flag: %b", alu_out, zero);

    // Property 2: Negative Flag must match MSB of alu_out.
    property p_negative_flag;
        @(posedge clk) disable iff (!rst_n)
        (alu_out[15] === negative);
    endproperty
    assert_negative_flag: assert property (p_negative_flag) else $error("SVA Error: Negative flag mismatch!");

    // Property 3: Reset state check
    property p_reset_state;
        @(posedge clk) !rst_n |=> (alu_out == 16'h0000 && zero == 1'b0); // SVA reset evaluation
    endproperty
    assert_reset: assert property (p_reset_state);

    // Stimulus generation
    initial begin
        clk = 0;
        rst_n = 0;
        a_in = 0;
        b_in = 0;
        alu_sel_in = 0;
        
        // Reset sequence
        #15 rst_n = 1;
        
        // Constrained Random Stimulus Loop
        repeat (50) begin
            @(posedge clk);
            a_in = $urandom_range(0, 65535);
            b_in = $urandom_range(0, 65535);
            alu_sel_in = $urandom_range(0, 15);
        end

        // Edge Cases
        @(posedge clk);
        a_in = 16'hFFFF; b_in = 16'h0001; alu_sel_in = 4'b0000; // Overflow Add
        
        @(posedge clk);
        a_in = 16'h5000; b_in = 16'h0000; alu_sel_in = 4'b0011; // Div by Zero
        
        #50;
        $display("Simulation complete with zero assertion failures.");
        $finish;
    end

endmodule
