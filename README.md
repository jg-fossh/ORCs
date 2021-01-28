# ORCs
**O**pen-source **R**ISC-V **C**ores
This project aims to create a collection of _harts_ complaint to the RISC-V ISA. Unlike other projects, this one does not seek to create the smallest risc-v implementation but rather experiment on implementations the risc-v ISA on accessible or popular FPGA dev boards focusing on performance first and resource cost second.

## ORC_R32IMA_BRAM

### Abstract

This is an implementation of the "I" and "M" sections of the risc-v ISA. General registers are implemented using BRAMs. The only CSRs implemented are cycle and instr in order to be able to run the benchmark.

### Performance

#### Dhrystone Benchmark (Version 2.1)

No two Dhrystone benchmark are the same since this is a compiler/core benchmark. Therefore a third party core was benchmarked and included for comparison.

Using Dhrystone test bench found in the picorv32 repo (https://github.com/cliffordwolf/picorv32/tree/master/dhrystone) and the same compiled code (hex file) on both for comparison.
Implementation  | Runs | User Time | Cycles Per Instruction | Dhrystones Per Second Per MHz | DMIPS Per MHz
:-------------- | :--: | :-------: | :--------------------: | :---------------------------: | :-----------:
ORC_R32IMAZicsr | 100  | 78301 cycles, 26025 insn  | 3.099 | 1264 | 0.725
picorv32        | 100  | 145013 cycles, 26136 insn | 5.548 |  689 | 0.392

#### Clocks Per Instructions
 _________\ Pipeline Stage <br> Instruction \ ___________ | Fetch | Decode | Register | Response | Total Clocks
:---------- | :---: | :----: | :------: | :------: | :----------:
LUI         |   ✔️   |    ✔️   |          |          |      2
AUIPC       |   ✔️   |    ✔️   |          |          |      2
JAL         |   ✔️   |    ✔️   |          |          |      2
JALR        |   ✔️   |    ✔️   |     ✔️    |          |      3
BRANCH      |   ✔️   |    ✔️   |     ✔️    |          |      3
R-R         |   ✔️   |    ✔️   |     ✔️    |          |      3
R-I         |   ✔️   |    ✔️   |     ✔️    |          |      3
Load        |   ✔️   |    ✔️   |     ✔️    |    ✔️     |      4*
Store       |   ✔️   |    ✔️   |     ✔️    |    ✔️     |      4*
Multiply    |   ✔️   |    ✔️   |     ✔️    |    ✔️     |      4
Division    |   ✔️   |    ✔️   |     ✔️    |    ✔️     |      4 to 18**

_*minimum_

_**minimum, spcecial cases like dividing by one or zero or when the factors are the same. But on average the divider takes 6 Goldschmidt steps which are implemented in two half steps plus the numbers need to be conditioned for the divider. For these reasons division takes 18 clock on average._

_**Note:**_ The fetch of the instruction is included in the table, unlike the literature of other projects out there since it can actually impact the overall performance(that is why some implementations in the wild have look-ahead fetching or fetch two instructions at a time, to give some examples).

#### Simulation Waveform Output 

##### This is a waveform snippet for reference 

 ![ORC_R32IM_Wave](wave.png)


##### This is a waveform snippet of the division module.

 ![ORC_R32IM_Wave](div.png)

### Current State

**_Under Progress_**


#### To Do

1.  Add more documentation


_**Note:**_ 

To synthesize the code for the Sipeed PriMER ANLOGIC FPGA BOARD simply set the parameter `P_IS_ANLOGIC` to 1. When using yosys or Xilinx using Vivado set the parameter to 0. This parameter is declared at the top level wrapper, ORC_R32IMAZicsr.v.

Sadly the division uses more DSP blocks than what the Lattice 5k has to offer and the ANLOGIC FPGA in the SiPEED board only has enough DSP block for a pipelined division. I will create a faster non-pipeline division module for larger fpgas like the A7 or S7 found in the Arty boards. Also Vivado results show the most critical timing path is associated to the DSP blocks, therefore there is a risk of having to reduce the clock rate for a non-pipelined version.

## Future Work

After the ORC_R32IMAZicsr I will probably target a low resource costs implementation.
