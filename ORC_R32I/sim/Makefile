SIM = verilator
TOPLEVEL_LANG = verilog
EXTRA_ARGS += --trace --trace-structs
VERILOG_SOURCES = $(shell pwd)/../source/Integer_Multiplier.v ../source/Goldschmidt_Convergence_Division.v ../source/HCC_Arithmetic_Processor.v ../source/Memory_Backplane.v ../source/Hart_Core.v ../source/ORC_R32IMAZicsr.v ./ORC_R32IMAZicsr_TOP.v
TOPLEVEL = ORC_R32IMAZicsr_TOP
MODULE = top

include $(shell cocotb-config --makefiles)/Makefile.sim
