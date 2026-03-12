# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def reset_dut(dut):
    dut.rst_n.value = 0
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    for _ in range(40):
        await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    for _ in range(10):
        await RisingEdge(dut.clk)

async def send_morse(dut, pattern):
    # clear first
    dut.ui_in.value = 0b00001000
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)
    # send each symbol
    for sym in pattern:
        dut.ui_in.value = 0b00000001 if sym == '.' else 0b00000010
        await RisingEdge(dut.clk)
        dut.ui_in.value = 0
        await RisingEdge(dut.clk)
    # confirm
    dut.ui_in.value = 0b00000100
    await RisingEdge(dut.clk)
    dut.ui_in.value = 0
    # settling cycles
    for _ in range(5):
        await RisingEdge(dut.clk)

@cocotb.test()
async def test_morse(dut):
    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    await reset_dut(dut)

    tests = [
        ("E", ".",      0b1111001, 0),
        ("A", ".-",     0b1110111, 0),
        ("D", "-..",    0b1011110, 0),
        ("B", "-...",   0b1111100, 0),
        ("C", "-.-.",   0b0111001, 0),
        ("F", "..-.",   0b1110001, 0),
        ("0", "-----",  0b0111111, 0),
        ("1", ".----",  0b0000110, 0),
        ("2", "..---",  0b1011011, 0),
        ("3", "...--",  0b1001111, 0),
        ("4", "....-",  0b1100110, 0),
        ("5", ".....",  0b1101101, 0),
        ("6", "-....",  0b1111101, 0),
        ("7", "--...",  0b0000111, 0),
        ("8", "---..",  0b1111111, 0),
        ("9", "----.",  0b1100111, 0),
        ("?", "----",   0b0111111, 1),
    ]

    for char, pattern, exp_ssd, exp_err in tests:
        await send_morse(dut, pattern)
        raw = dut.uo_out.value
        dut._log.info(f"{char} | raw uo_out = {raw}")
        try:
            ssd = int(raw) & 0x7F
            err = (int(raw) >> 7) & 1
        except ValueError:
            dut._log.warning(f"FAIL {char}: uo_out contains X/Z: {raw}")
            raise
        assert ssd == exp_ssd, f"FAIL {char}: got ssd={ssd:#09b} expected {exp_ssd:#09b}"
        assert err == exp_err, f"FAIL {char}: got err={err} expected {exp_err}"
        dut._log.info(f"PASS {char} | {pattern} | ssd={ssd:07b} err={err}")