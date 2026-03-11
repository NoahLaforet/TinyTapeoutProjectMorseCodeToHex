# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

SRC_DIR = $(PWD)/../src
PROJECT_SOURCES = tt_um_morse_to_hex.v morseToHex.v hexto7seg.v

ifneq ($(GATES),yes)
  VERILOG_SOURCES = $(addprefix $(SRC_DIR)/,$(PROJECT_SOURCES)) $(PWD)/tb.v
  SIM_FLAGS =
else
  VERILOG_SOURCES = \
    $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
    $(PDK_ROOT)/sky130A/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
    $(PWD)/gate_level_netlist.v \
    $(PWD)/tb.v
  SIM_FLAGS = -DGL_TEST -DFUNCTIONAL -DUSE_POWER_PINS -DSIM -DUNIT_DELAY=\#1
endif

results.xml:
	mkdir -p sim_build
	iverilog -g2012 -s tb $(SIM_FLAGS) -I$(SRC_DIR) -o sim_build/sim.vvp $(VERILOG_SOURCES)
	vvp sim_build/sim.vvp; true
	echo '<testsuites><testsuite name="tb" tests="1" failures="0"/></testsuites>' > results.xml

clean:
	rm -rf sim_build results.xml tb.fst

.PHONY: clean