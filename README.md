# ORCs
**O**pen-source **R**ISC-V **C**ores
This project aims to create a collection of _harts_ complaint to the RISC-V ISA. Unlike other projects, this one does not seek to create the smallest risc-v implementation but rather experiment on implementations the risc-v ISA on accessible or popular FPGA dev boards focusing on performance first and resource cost second.

## ORC R32I

### Abstract
RV32I un-privileged hart implementation directory. Contains the source code, simulation files and examples for synthesis and place-and-route.

This project is currently under progress. It uses previous work from the DarkRISCV project (https://github.com/darklife/darkriscv) as a starting reference.  Kept the concept of having two copies of the general purpose register for a faster access. The instruction interface was swap from a streaming interface to a memory interface(Wishbone pipeline). The counter and decoder have change so much the look very different now.

The ORC_R32I/source folder contains more on the specifications and the verilog code. For resource cost see the results in ORC_R32I/build/ 

## Goal 

A 32-bit RISC-V ISA integer (I) extensions implementation.

### Current State

It is complete but optimizations from the ORC_R32IMAZicsr will be flown down eventually. This core is no longer the priority.

### Performance

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

_*minimum_

_**Note:**_ The fetch of the instruction is included in the table, unlike the literature of other projects out there since it can actually impact the overall performance(that is why some implementations in the wild have look-ahead fetching or fetch two instructions at a time, to give some examples).

#### Simulation Waveform Output 

##### This is a waveform snippet for reference 

 ![ORC_R32IM_Wave](wave.png)

### Current State

**_Under Progress_**


#### To Do

1.  Add more documentation 


_**Note:**_ 

To synthesize the code for the Sipeed PriMER ANLOGIC FPGA BOARD simply set the parameter `P_IS_ANLOGIC` to 1. When using yosys or Xilinx using Vivado set the parameter to 0. This parameter is declared at the top level wrapper, ORC_R32I.v.

Sadly the division uses more DSP blocks than what the Lattice 5k has to offer and the ANLOGIC FPGA in the SiPEED board only has enough DSP block for a pipelined division. I will create a faster non-pipeline division module for larger fpgas like the A7 or S7 found in the Arty boards. Also Vivado results show the most critical timing path is associated to the DSP blocks, therefore there is a risk of having to reduce the clock rate for a non-pipelined version.

## Future Work

After the ORC_R32IMAZicsr I will probably target a low resource costs implementation.
