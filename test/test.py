# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, ClockCycles


# ---------------------------------------------------------------------------
# Button press helper
# ---------------------------------------------------------------------------
# Mirrors the tb.v pattern:
#   @(negedge clk); ui_in[N]=1;   <- assert on negedge (avoids setup races)
#   @(posedge clk);                <- rising edge: state machine sees the press
#   @(negedge clk); ui_in[N]=0;   <- deassert
#   @(posedge clk);                <- _prev register clears, ready for next press
# After this coroutine returns, uo_out is fully settled.
# ---------------------------------------------------------------------------
async def press_button(dut, bit):
    await FallingEdge(dut.clk)
    dut.ui_in.value = (1 << bit)
    await RisingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.ui_in.value = 0
    await RisingEdge(dut.clk)


async def dot(dut):     await press_button(dut, 0)
async def dash(dut):    await press_button(dut, 1)
async def confirm(dut): await press_button(dut, 2)
async def clear(dut):   await press_button(dut, 3)


# ---------------------------------------------------------------------------
# Main test
# ---------------------------------------------------------------------------
@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    clock = Clock(dut.clk, 10, unit="us")
    cocotb.start_soon(clock.start())

    # Reset for 4 cycles then release
    dut.ena.value = 1
    dut.ui_in.value = 0
    dut.uio_in.value = 0
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 4)
    dut.rst_n.value = 1
    await ClockCycles(dut.clk, 1)

    pass_count = 0
    fail_count = 0

    # Expected 7-seg patterns (active-HIGH, bit order GFEDCBA):
    #   0->0111111  1->0000110  2->1011011  3->1001111
    #   4->1100110  5->1101101  6->1111101  7->0000111
    #   8->1111111  9->1100111  A->1110111  B->1111100
    #   C->0111001  D->1011110  E->1111001  F->1110001

    def check(label, morse, exp_ssd):
        """Read uo_out and compare against expected 7-seg value."""
        nonlocal pass_count, fail_count
        raw = int(dut.uo_out.value)
        got_ssd = raw & 0x7F
        got_err = (raw >> 7) & 1
        if got_ssd == exp_ssd and got_err == 0:
            dut._log.info(f"[PASS] {label} | input: {morse:8s} | ssd={got_ssd:07b} err={got_err}")
            pass_count += 1
        else:
            dut._log.error(
                f"[FAIL] {label} | input: {morse:8s} | "
                f"got ssd={got_ssd:07b} err={got_err} | "
                f"exp ssd={exp_ssd:07b} err=0"
            )
            fail_count += 1

    # ------------------------------------------------------------------
    # TEST 1: E  ->  .
    # ------------------------------------------------------------------
    await dot(dut);     await confirm(dut)
    check("E", ".",        0b1111001)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 2: A  ->  . -
    # ------------------------------------------------------------------
    await dot(dut);  await dash(dut);  await confirm(dut)
    check("A", ".-",       0b1110111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 3: D  ->  - . .
    # ------------------------------------------------------------------
    await dash(dut); await dot(dut);  await dot(dut);  await confirm(dut)
    check("D", "-..",      0b1011110)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 4: B  ->  - . . .
    # ------------------------------------------------------------------
    await dash(dut); await dot(dut);  await dot(dut);  await dot(dut);  await confirm(dut)
    check("B", "-...",     0b1111100)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 5: C  ->  - . - .
    # ------------------------------------------------------------------
    await dash(dut); await dot(dut);  await dash(dut); await dot(dut);  await confirm(dut)
    check("C", "-.-.",     0b0111001)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 6: F  ->  . . - .
    # ------------------------------------------------------------------
    await dot(dut);  await dot(dut);  await dash(dut); await dot(dut);  await confirm(dut)
    check("F", "..-.",     0b1110001)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 7: 0  ->  - - - - -
    # ------------------------------------------------------------------
    await dash(dut); await dash(dut); await dash(dut); await dash(dut); await dash(dut); await confirm(dut)
    check("0", "-----",    0b0111111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 8: 1  ->  . - - - -
    # ------------------------------------------------------------------
    await dot(dut);  await dash(dut); await dash(dut); await dash(dut); await dash(dut); await confirm(dut)
    check("1", ".----",    0b0000110)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 9: 2  ->  . . - - -
    # ------------------------------------------------------------------
    await dot(dut);  await dot(dut);  await dash(dut); await dash(dut); await dash(dut); await confirm(dut)
    check("2", "..---",    0b1011011)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 10: 3  ->  . . . - -
    # ------------------------------------------------------------------
    await dot(dut);  await dot(dut);  await dot(dut);  await dash(dut); await dash(dut); await confirm(dut)
    check("3", "...--",    0b1001111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 11: 4  ->  . . . . -
    # ------------------------------------------------------------------
    await dot(dut);  await dot(dut);  await dot(dut);  await dot(dut);  await dash(dut); await confirm(dut)
    check("4", "....-",    0b1100110)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 12: 5  ->  . . . . .
    # ------------------------------------------------------------------
    await dot(dut);  await dot(dut);  await dot(dut);  await dot(dut);  await dot(dut);  await confirm(dut)
    check("5", ".....",    0b1101101)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 13: 6  ->  - . . . .
    # ------------------------------------------------------------------
    await dash(dut); await dot(dut);  await dot(dut);  await dot(dut);  await dot(dut);  await confirm(dut)
    check("6", "-....",    0b1111101)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 14: 7  ->  - - . . .
    # ------------------------------------------------------------------
    await dash(dut); await dash(dut); await dot(dut);  await dot(dut);  await dot(dut);  await confirm(dut)
    check("7", "--...",    0b0000111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 15: 8  ->  - - - . .
    # ------------------------------------------------------------------
    await dash(dut); await dash(dut); await dash(dut); await dot(dut);  await dot(dut);  await confirm(dut)
    check("8", "---..",    0b1111111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 16: 9  ->  - - - - .
    # ------------------------------------------------------------------
    await dash(dut); await dash(dut); await dash(dut); await dash(dut); await dot(dut);  await confirm(dut)
    check("9", "----.",    0b1100111)
    await clear(dut)

    # ------------------------------------------------------------------
    # TEST 17: INVALID  ->  - - - -  (4 dashes, no morse match)
    # Only check that error LED is HIGH; 7-seg value doesn't matter.
    # ------------------------------------------------------------------
    await dash(dut); await dash(dut); await dash(dut); await dash(dut); await confirm(dut)
    raw = int(dut.uo_out.value)
    got_err = (raw >> 7) & 1
    if got_err == 1:
        dut._log.info(f"[PASS] ? | input: ----     | err={got_err} (error LED high as expected)")
        pass_count += 1
    else:
        dut._log.error(f"[FAIL] ? | input: ----     | got err={got_err} | exp err=1 (no morse match)")
        fail_count += 1
    await clear(dut)

    # ------------------------------------------------------------------
    # Summary
    # ------------------------------------------------------------------
    dut._log.info("----------------------------------------")
    dut._log.info(f"Results: {pass_count} passed, {fail_count} failed")
    assert fail_count == 0, f"Test suite failed with {fail_count} failure(s)"
