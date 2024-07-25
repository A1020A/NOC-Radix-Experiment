# Makefile

# defaults
SIM ?= xcelium
TOPLEVEL_LANG ?= verilog
EXTRA_ARGS += -access +rwc -input shmdump.tcl

# COCOTB_HDL_TIMEUNIT = 1ns
# COCOTB_HDL_TIMEPRECISION = 1ps

VERILOG_SOURCES += $(PWD)/NOC.sv

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = NOC

# MODULE is the basename of the Python test file
MODULE = NOC_cocotb

# RANDOM_SEED: used to set cocotb random seeds

# DUT parameters
ADDR_WIDTH ?= 16
DATA_WIDTH ?= 32
RADIX_IN ?= 4
RADIX_OUT ?= 8
DEPTH ?= 2
NETWORK_DEPTH ?= 2
VERBOSE ?= 0

# Mem files
# I_DATA_FILE ?= ../data/i_dmem.txt
# F_DATA_FILE ?= f_dmem.txt
# I_INSTR_FILE ?= ../data/i_imem_dft64.txt
# F_INSTR_FILE ?= f_imem.txt

PLUSARGS += "+ADDR_WIDTH=$(ADDR_WIDTH)" \
			"+DATA_WIDTH=$(DATA_WIDTH)" \
			"+RADIX_IN=$(RADIX_IN)" \
			"+RADIX_OUT=$(RADIX_OUT)" \
			"+DEPTH=$(DEPTH)" \
			"+NETWORK_DEPTH=$(NETWORK_DEPTH)" \
			"+VERBOSE=$(VERBOSE)"\
			# "+I_DATA_FILE=$(I_DATA_FILE)" \
			# "+F_DATA_FILE=$(F_DATA_FILE)" \
			# "+I_INSTR_FILE=$(I_INSTR_FILE)" \
			# "+F_INSTR_FILE=$(F_INSTR_FILE)"

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
