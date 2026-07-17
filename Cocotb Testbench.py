import cocotb
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
import random

def golden_reference(a: int, b: int, sel: int) -> tuple:
    """Python behavioral model representing expected ALU output and flags"""
    out = 0
    carry = 0
    
    # Mask values to 16-bit
    a &= 0xFFFF
    b &= 0xFFFF
    
    if sel == 0:    # Add
        res = a + b
        out = res & 0xFFFF
        carry = 1 if res > 0xFFFF else 0
    elif sel == 1:  # Sub
        res = a - b
        out = res & 0xFFFF
        carry = 1 if res < 0 else 0
    elif sel == 2:  # Mul
        out = (a * b) & 0xFFFF
    elif sel == 3:  # Div
        out = (a // b) & 0xFFFF if b != 0 else 0
    elif sel == 4:  # Inc
        out = (a + 1) & 0xFFFF
    elif sel == 5:  # Dec
        out = (a - 1) & 0xFFFF
    elif sel == 6:  # AND
        out = a & b
    elif sel == 7:  # OR
        out = a | b
    elif sel == 8:  # XOR
        out = a ^ b
    elif sel == 9:  # NAND
        out = (~(a & b)) & 0xFFFF
    elif sel == 10: # NOR
        out = (~(a | b)) & 0xFFFF
    elif sel == 11: # XNOR
        out = (~(a ^ b)) & 0xFFFF
    elif sel == 12: # NOT
        out = (~a) & 0xFFFF
    elif sel == 13: # SLL
        out = (a << 1) & 0xFFFF
    elif sel == 14: # SRL
        out = (a >> 1) & 0xFFFF
    elif sel == 15: # Less Than
        out = 1 if a < b else 0
        
    zero = 1 if out == 0 else 0
    negative = 1 if (out & 0x8000) else 0
    
    return out, carry, zero, negative

@cocotb.test()
async def alu_randomized_test(dut):
    """Generates random ALU inputs and compares hardware output to the golden reference model"""
    
    # Start a 100MHz system clock
    cocotb.start_soon(Clock(dut.clk, 10, units="ns").start())
    
    # Assert Reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 3)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    pipeline_queue = []

    for _ in range(100):
        # Generate random stimulus
        a = random.randint(0, 0xFFFF)
        b = random.randint(0, 0xFFFF)
        sel = random.randint(0, 15)
        
        # Drive design inputs
        dut.a_in.value = a
        dut.b_in.value = b
        dut.alu_sel_in.value = sel
        
        # Calculate expected output for this clock cycle injection
        expected_out = golden_reference(a, b, sel)
        pipeline_queue.append(expected_out)
        
        await RisingEdge(dut.clk)
        
        # Since we have a 2-stage pipeline register process:
        # Check outcomes only once our pipeline queue has enough items inside it
        if len(pipeline_queue) > 2:
            exp_out, exp_carry, exp_zero, exp_neg = pipeline_queue.pop(0)
            
            # Assert hardware outputs match Python expectations
            assert dut.alu_out.value == exp_out, f"Out Mismatch: HW={dut.alu_out.value.integer}, Expected={exp_out}"
            assert dut.zero.value == exp_zero, f"Zero Flag Mismatch: HW={dut.zero.value.integer}, Expected={exp_zero}"
            assert dut.negative.value == exp_neg, f"Negative Flag Mismatch: HW={dut.negative.value.integer}, Expected={exp_neg}"

# Helper import required for test
from cocotb.triggers import ClockCycles
