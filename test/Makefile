SRC_DIR = $(PWD)/../src
PDK_ROOT ?= $(HOME)/.volare/sky130A

# RTL sources (used by default)
RTL_SOURCES = \
	$(SRC_DIR)/tt_um_morse_to_hex.v \
	$(SRC_DIR)/morseToHex.v \
	$(SRC_DIR)/hexto7seg.v \
	$(PWD)/tb.v

# Gate-level sources (used when GATES=yes)
# Copy your hardened netlist from runs/wokwi/results/final/verilog/gl/ to gate_level_netlist.v
GL_SOURCES = \
	$(PWD)/gate_level_netlist.v \
	$(PDK_ROOT)/libs.ref/sky130_fd_sc_hd/verilog/primitives.v \
	$(PDK_ROOT)/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v \
	$(PWD)/tb.v

.PHONY: all clean

ifeq ($(GATES), yes)
SOURCES = $(GL_SOURCES)
IVFLAGS = -g2005-sv -DFUNCTIONAL -DUNIT_DELAY=\#1 -DUSE_POWER_PINS
else
SOURCES = $(RTL_SOURCES)
IVFLAGS = -g2001
endif

all: sim
	vvp sim

sim: $(SOURCES)
	iverilog $(IVFLAGS) -o sim $(SOURCES)

clean:
	rm -f sim tb.fst
