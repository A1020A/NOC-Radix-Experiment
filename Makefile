#cocotb test make with vcs
SIM ?= vcs
TOPLEVEL_LANG ?= verilog
VERILOG_SOURCES = $(PWD)/NOC.sv $(PWD)/lib.sv
TOPLEVEL = NOC_CrossBar
MODULE = NOC_cocotb

include $(shell cocotb-config --makefiles)/Makefile.sim