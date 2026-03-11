<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

This project implements a **Morse Code to Hex Translator** on a 7-segment display. The user enters a morse code sequence using two buttons (dot and dash), then presses confirm to decode and display the corresponding hexadecimal digit (0–F).

### Design Overview

The design is split into three Verilog modules:

- **`tt_um_morse_to_hex`** — top-level module. Handles button edge detection, a 5-bit morse input buffer, and orchestrates the decode pipeline.
- **`morseToHex`** — combinational lookup table mapping a `(count, buffer)` pair to a 4-bit hex digit and a validity flag.
- **`hexto7seg`** — combinational hex-to-7-segment encoder (active-high output, 1 = segment on), matching the TinyTapeout demo board convention.

### Input Interface (`ui_in`)

| Bit | Function |
|-----|----------|
| `[0]` | Dot button |
| `[1]` | Dash button |
| `[2]` | Confirm (decode and display current sequence) |
| `[3]` | Clear (reset buffer and display) |

All buttons use rising-edge detection so that holding a button only registers one input.

### Output Interface (`uo_out`)

| Bits    | Function                                                               |
|---------|------------------------------------------------------------------------|
| `[6:0]` | 7-segment display segments (active-high, GFEDCBA order; 1 = segment on) |
| `[7]`   | Error LED — HIGH when confirm is pressed on an unrecognised sequence   |

### Morse Buffer Encoding

Each button press shifts a new symbol into the MSB of a 5-bit shift register:
```
buffer <= {new_bit, buffer[4:1]}   // dot = 0, dash = 1
```
A 3-bit counter tracks how many symbols have been entered (max 5). The `morseToHex` module performs a combinational lookup on `{count, buffer}` to identify the morse pattern. For example:

| Digit | Morse | Count | Buffer |
|-------|-------|-------|--------|
| E | `.` | 1 | `00000` |
| A | `.-` | 2 | `10000` |
| 0 | `-----` | 5 | `11111` |
| 5 | `.....` | 5 | `00000` |

The count disambiguates patterns like E (1 dot) and 5 (5 dots) that share the same buffer bits.

### Debug Outputs (`uio_out`)

Bits `[4:0]` mirror the morse buffer and bits `[7:5]` show the current symbol count, allowing real-time inspection of the input state with a logic analyser or LEDs.

## How to test

Press the dot and/or dash buttons to enter a morse code sequence for any hex digit (0–F), then press confirm. The 7-segment display will show the decoded hex digit. If the sequence does not match any known morse code, the error LED (`uo_out[7]`) lights up. Press clear at any time to reset the buffer and start a new sequence.

**Morse code table used:**

| Digit | Morse | Digit | Morse |
|-------|-------|-------|-------|
| 0 | `-----` | 8 | `---..` |
| 1 | `.----` | 9 | `----.` |
| 2 | `..---` | A | `.-` |
| 3 | `...--` | B | `-...` |
| 4 | `....-` | C | `-.-.` |
| 5 | `.....` | D | `-..` |
| 6 | `-....` | E | `.` |
| 7 | `--...` | F | `..-.` |

## Testbench

The testbench (`test/test.py`) uses the cocotb framework to drive the DUT and verify outputs. It drives the DUT using explicit clock-cycle-level button press sequences and asserts the expected 7-segment output after each confirm.

Each button press is modelled as a one-cycle high pulse, consistent with the rising-edge detection in the design:
```python
await FallingEdge(dut.clk)
dut.ui_in.value = (1 << bit)  # assert button
await RisingEdge(dut.clk)     # edge detected, state machine acts
await FallingEdge(dut.clk)
dut.ui_in.value = 0           # deassert
await RisingEdge(dut.clk)     # prev register updates, ready for next press
```

### Test Coverage

The testbench contains **17 test cases** covering all possible valid outputs:

- **16 valid sequences** — one for each hex digit (0–F), checking the exact active-high 7-segment pattern and that the error LED is low.
- **1 invalid sequence** — four dashes (`----`), which has no morse mapping, checking that the error LED goes high.

Each test checks both the 7-segment value and the error bit. After every test the buffer is cleared with the clear button before the next sequence begins. The testbench reports pass/fail counts and raises an assertion error if any test fails, enabling automatic CI detection of regressions. The check function also gracefully handles X/Z values that may appear during gate-level simulation before outputs have fully settled.

### Why the Testbench is Sufficient

The design has a finite, fully enumerable input space: 16 valid morse sequences and the error case. The testbench exhaustively covers every valid output the decoder can produce, plus the invalid-input error path, giving 100% coverage of the output state space. The buffer encoding and 7-segment values were independently verified by hand before being hardcoded into the testbench expectations.

## External hardware

- 7-segment display connected to `uo_out[6:0]` (active-high: 1 = segment on)
- 4 pushbuttons connected to `ui_in[3:0]` (dot, dash, confirm, clear)
- Optional: error LED on `uo_out[7]`

## GenAI Tools

The project concept, morse encoding scheme, and `hexto7seg` 7-segment encoder (adapted from prior coursework in CSE 125) were created by myself. Claude (Anthropic) was used to assist with wiring the submodules together inside `tt_um_morse_to_hex`, implementing the button edge-detection and shift-register logic, and adapting the testbench template to exhaustively test every possible output of the design. Claude also assisted with the TinyTapeout submission flow, including converting the testbench to cocotb (`test.py`), fixing the `test/Makefile` to use the correct cocotb build system with the proper PDK paths for gate-level simulation, fixing the `test.yml` GitHub Actions workflow to install cocotb dependencies before running tests, and adding X/Z value handling in the testbench check function for gate-level simulation stability. I also had Claude update this document to have better formatting, improve my explanations, and add input examples.