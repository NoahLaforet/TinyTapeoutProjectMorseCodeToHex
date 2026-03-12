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

The testbench uses **cocotb** (the canonical TinyTapeout test framework) with `test.py` as the sole test driver. `tb.v` instantiates `tt_um_morse_to_hex` and wires all ports, providing cocotb with named signal handles and capturing waveforms to `tb.fst`. All stimulus and assertions are in `test.py`.

Each button press is modelled as a one-cycle high pulse followed by one cycle low, consistent with the rising-edge detection in the design. Because `*_rise = input & ~*_prev`, the rise is detected on the same cycle the input goes high, and cleared the following cycle when `*_prev` catches up:
```python
dut.ui_in.value = 0b00000001  # assert dot for one cycle
await RisingEdge(dut.clk)
dut.ui_in.value = 0           # deassert; prev updates, ready for next press
await RisingEdge(dut.clk)
```

Reset is held for 40 cycles to allow synthesized flip-flops to fully initialize, followed by 10 idle cycles before stimulus begins. After each confirm pulse, 5 settling cycles are waited before sampling `uo_out`.

For gate-level simulation, the Makefile passes `-DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=#1` and points to the sky130 PDK primitives. `tb.v` includes `ifdef GL_TEST` guards to connect `VPWR` and `VGND` power pins required by the synthesized netlist.

### Test Coverage

The testbench contains **17 test cases** covering all possible valid outputs:

- **16 valid sequences** — one for each hex digit (0–F), checking the exact active-high 7-segment pattern and that the error LED is low.
- **1 invalid sequence** — four dashes (`----`), which has no morse mapping, checking that the error LED goes high.

Each test checks both the 7-segment value (`uo_out[6:0]`) and the error bit (`uo_out[7]`). The buffer is cleared before each sequence via a one-cycle pulse on `ui_in[3]`. Pass/fail is reported via cocotb's standard JUnit XML output (`results.xml`), which the CI workflow checks with `! grep failure results.xml`.

### Why the Testbench is Sufficient

The design has a finite, fully enumerable input space: 16 valid morse sequences and the error case. The testbench exhaustively covers every valid output the decoder can produce, plus the invalid-input error path, giving 100% coverage of the output state space. The buffer encoding and 7-segment values were independently verified by hand before being hardcoded into the testbench expectations.

## External hardware

- 7-segment display connected to `uo_out[6:0]` (active-high: 1 = segment on)
- 4 pushbuttons connected to `ui_in[3:0]` (dot, dash, confirm, clear)
- Optional: error LED on `uo_out[7]`

## GenAI Tools

The project concept, morse encoding scheme, and `hexto7seg` 7-segment encoder (adapted from prior coursework in CSE 125) were created by myself. Claude (Anthropic) was used to assist with the following:

- Wiring the submodules together inside `tt_um_morse_to_hex`, implementing the button edge-detection and shift-register logic
- Adapting the testbench template to exhaustively test every possible output of the design
- Converting the test infrastructure to the TinyTapeout CI flow, including fixing the `test/Makefile` to use the correct PDK paths for gate-level simulation
- Debugging the cocotb/tb.v conflict where both were driving the DUT simultaneously, causing race conditions and `$fatal` kills
- Iterating through multiple testbench approaches (pure iverilog/vvp, then reverting to canonical cocotb) to resolve GL test exit code failures
- Restoring the canonical TinyTapeout `tb.v` structure (DUT instantiation with `ifdef GL_TEST` power pin guards) and confirming it resolves the `tb contains no child object named clk` cocotb error
- Restoring the original TinyTapeout `test.yml` workflow, which correctly uses `! grep failure results.xml` to determine pass/fail rather than the make exit code
- Updating this document to reflect all infrastructure changes with accurate formatting and descriptions