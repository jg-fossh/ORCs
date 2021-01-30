USE_MYSTDLIB = 0
OBJS = dhry_1.o dhry_2.o stdlib.o
CFLAGS = -MD -O3 -march=rv32i -mabi=ilp32 -DTIME -DRISCV
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
# TOOLCHAIN_PREFIX = /opt/riscv32im/bin/riscv32-unknown-elf-

ifeq ($(USE_MYSTDLIB),1)
CFLAGS += -DUSE_MYSTDLIB -ffreestanding -nostdlib
OBJS += start.o
else
OBJS += syscalls.o
endif

test: testbench.vvp
	vvp -N testbench.vvp

test_trace: testbench.vvp
	vvp -N $< +trace
	python3 ../showtrace.py testbench.trace dhry.elf > testbench.ins

test_nola: 
	iverilog -g2012 -gxtypes -o testbench_nola.iver -s testbench_nola ./testbench_nola.v ../../source/Generic_BRAM.v ../../source/Memory_Backplane.v ../../source/CSR.v ../../source/Hart_Core.v ../../source/ORC_R32I.v
	vvp -N testbench_nola.iver

timing: timing.txt
	grep '^##' timing.txt | gawk 'x != "" {print x,$$3-y;} {x=$$2;y=$$3;}' | sort | uniq -c | \
		gawk '{printf("%03d-%-7s %2d %-8s (%d)\n",$$3,$$2,$$3,$$2,$$1);}' | sort | cut -c13-

timing.txt: timing.vvp
	vvp -N timing.vvp > timing.txt

testbench.vvp: testbench.v ../../source/ORC_R32I.v
	iverilog -o testbench.vvp testbench.v ../../source/ORC_R32I.v
	chmod -x testbench.vvp

testbench_nola.vvp: testbench_nola.v ../../source/ORC_R32I.v
	iverilog -o testbench_nola.vvp testbench_nola.v ../../source/ORC_R32I.v
	chmod -x testbench_nola.vvp

timing.vvp: testbench.v ../../source/ORC_R32I.v
	iverilog -o timing.vvp -DTIMING testbench.v ../../source/ORC_R32I.v
	chmod -x timing.vvp

dhry.hex: dhry.elf
	$(TOOLCHAIN_PREFIX)objcopy -O verilog $< $@

ifeq ($(USE_MYSTDLIB),1)
dhry.elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc
	chmod -x $@
else
dhry.elf: $(OBJS)
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,../firmware/riscv.ld,-Map,dhry.map,--strip-debug -o $@ $(OBJS) -lgcc -lc
	chmod -x $@
endif

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.S
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

dhry_1.o dhry_2.o: CFLAGS += -Wno-implicit-int -Wno-implicit-function-declaration

clean:
	rm -rf *.o *.d dhry.elf dhry.map dhry.bin dhry.hex testbench.vvp testbench.vcd timing.vvp timing.txt testbench_nola.vvp

.PHONY: test clean

-include *.d

