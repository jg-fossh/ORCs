# ![orc2.gif](orc2.gif) ORC R32IM Synthesizable Unit Specification

Document        | Metadata
:-------------- | :------------------
_Version_       | v0.0.2
_Prepared by_   | Jose R Garcia
_Created_       | 2020/12/25 13:39:12
_Last modified_ | 2021/01/07 00:52:39
_Project_       | ORCs

## Overview

The ORC R32IM is an implementation of the RISC-V 32-bit I and M extensions. It is a single issue, 3 stage pipeline, _hart_ .

## Table Of Contents

<!-- TOC depthFrom:1 depthTo:6 withLinks:1 updateOnSave:1 orderedList:0 --> - [ORC_R32IM Synthesizable Unit Specification](#orcr32im-synthesizable-unit-specification)
  - [Overview](#overview)
  - [Table Of Contents](#table-of-contents)
  - [1 Syntax and Abbreviations](#1-syntax-and-abbreviations)
  - [2 Design](#2-design)
  - [3 Clocks and Resets](#3-clocks-and-resets)
  - [4 Interfaces](#4-interfaces)
    - [4.1 Instruction HBI Master Read](#41-instruction-hbi-master-read)
    - [4.2 Memory and I/O HBI Master Read](#42-memory-and-io-hbi-master-read)
    - [4.3 Memory and I/O HBI Master Write](#43-memory-and-io-hbi-master-write)
  - [5 Generic Parameters](#5-generic-parameters)
  - [6 Register Space](#6-register-space)
    - [6.1 General Register _n_](#61-general-register-n)
  - [7 Directory Structure](#7-directory-structure)
  - [8 Simulation](#8-simulation)
  - [9 Synthesis](#9-synthesis)
  - [10 Build](#10-build)<!-- /TOC -->

 ## 1 Syntax and Abbreviations

Term        | Definition
:---------- | :---------------------------------------------
0b0         | Binary number syntax
0x0000_0000 | Hexadecimal number syntax
bit         | Single binary digit (0 or 1)
BYTE        | 8-bits wide data unit
DWORD       | 32-bits wide data unit
FPGA        | Field Programmable Gate Array
GID         | Goldschmidt Integer Divider
HART        | Hardware Thread
ISA         | Instruction Set Architecture
LSB         | Least Significant bit
MSB         | Most Significant bit
WB          | Wishbone Interface


## 2 Design

The ORC_R32IM uses a Harvard architecture, separating the interface used to access the instructions from the interface used to access external devices. The general purpose register are implemented in LUTRAMs while the CSRs are implemented in BRAMs. The MUL Processor infers generic DSP blocks. The integer divider also infers its own set of DSP blocks.

|      ![Top_Level](Top.gif)
| :------------------------------------:
| Figure 1 : Top Level Diagram


### 2.1 HART Core

The Program Counter process fetches the instructions by asserting the instruction interface strobe signal, thus validating the address signal and waits for the acknowledge to be asserted in response which validates the data signal.


### 2.2 Integer Multiplier

TBD

#### 2.3 Goldschmidt Integer Divider

The Goldschmidt division is an special application of the Newton-Raphson method. This iterative divider computes:

    d(i) = d[i-1].(2-d[i-1])
             and
    D(i) = D[i-1].(2-d[i-1])

were 'd' is the divisor; 'D' is the dividend; 'i' is the step. D converges toward the quotient and d converges toward 1 at a quadratic rate. For the divisor to converge to 1 it must obviously be less than 2 therefore integers greater than 2 must be multiplied by 10 to the negative powers to shift the decimal point. Consider the following example:

Step  | D                | d                 | 2-d
----: | :--------------- | :---------------- | :---------------
.     | 16	             | 4                 | 1.6
0     | 1.6	             | 0.4               | 1.36
1     | 2.56             | 0.64              | 1.1296
2     | 3.4816           | 0.8704            | 1.01679616
3     | 3.93281536       | 0.98320384        | 1.00028211099075
4     | 3.99887155603702 | 0.999717889009254 | 1.00000007958661
5     | 3.99999968165356 | 0.999999920413389 | 1.00000000000001
6     | 3.99999968165356 | 0.999999920413389 | 1.00000000000001
7     | 3.99999999999997 | 0.999999999999994 | 1
8     | 4                | 1                 | 1

The code implementation compares the size of the divisor against 2*10^_n_ were _n_ is a natural number. The result of the comparison indicates against which 10^_m_, were _m_ is a negative integer, to multiply the divisor. Then the Goldschmidt division is performed until the divisor converges to degree indicated by `P_GCD_ACCURACY`. The quotient returned is the rounded up value to which the dividend converged to. Each Goldschmidt step is performed in to two half steps in order use only one multiplier and save resources.

The remainder calculation requires an extra which is why the address tag is used to make the decision on whether to do the calculation or skip it. The calculation simply take the value after the decimal point of the quotient a multiplies it by the divisor.

### 2.3 General Registers Access Controller

TBD

## 3 Clocks and Resets

Signals        | Initial State | Direction | Definition
:------------- | :-----------: | :-------: | :--------------------------------------------------------------------
`i_clk`        |      N/A      |    In     | Input clock. Streaming interface fall within the domain of this clock
`i_reset_sync` |      N/A      |    In     | Synchronous reset. Used to reset this unit.

## 4 Interfaces

The ORC_R32IM employs independent interfaces for reading the memory containing the instructions to be decoded and reading and writing to other devices such as memories and I/O devices.

### 4.1 Instruction WB Master Read

Signals            | Initial State | Dimension | Direction | Definition
:----------------- | :-----------: | :-------: | :-------: | :-----------------------
`o_inst_read_stb`  |      0b0      |   1-bit   |    Out    | Read request signal.
`i_inst_read_ack`  |      N/A      |   1-bit   |    In     | Read acknowledge signal.
`o_inst_read_addr` |  0x0000_0000  | `[31:0]`  |    Out    | Read Address signal.
`i_inst_read_data` |      N/A      | `[31:0]`  |    In     | Read response data.


The unit consumes instructions as portrayed by Figure 2.

|      ![Pipeline](inst_waved.png)
| :------------------------------------:
| Figure 2 : Instruction HBI Read Timing


### 4.2 Memory and I/O WB Master Read

Signals              | Initial State | Dimension | Direction | Definition
:------------------- | :-----------: | :-------: | :-------: | :-----------------------
`o_master_read_stb`  |      0b0      |   1-bit   |    Out    | Read request signal.
`i_master_read_ack`  |      N/A      |   1-bit   |    In     | Read acknowledge signal.
`o_master_read_addr` |  0x0000_0000  | `[31:0]`  |    Out    | Read Address signal.
`i_master_read_data` |      N/A      | `[31:0]`  |    In     | Read response data.

### 4.3 Memory and I/O WB Master Write

Signals                | Initial State | Dimension | Direction | Definition
:--------------------- | :-----------: | :-------: | :-------: | :------------------------
`o_master_write_stb`   |      0b0      |   1-bit   |    Out    | Write request signal.
`i_master_write_ack`   |      N/A      |   1-bit   |    In     | Write acknowledge signal.
`o_master_write_addr`  |  0x0000_0000  | `[31:0]`  |    Out    | Write Address signal.
`i_master_read_data`   |      N/A      | `[31:0]`  |    In     | Write response data.
`o_master_write_sel`   |      0x0      |  `[3:0]`  |    Out    | Write byte enable

## 5 Configurable Parameters

Parameters              |   Default  | Description
:---------------------- | :--------: | :---------------------------------------------------
`P_FETCH_COUNTER_RESET` |      0     | Initial address fetched by the Instruction WB Read.
`P_MEMORY_ADDR_MSB`     |      4     | Log2(Number_Of_Total_Register)-1
`P_MEMORY_DEPTH`        |     32     | Memory space depth.
`P_DIV_ACCURACY`        |     12     | Divisor Convergence Threshold. How close to one does it get to accept the result. These are the 32bits after the decimal point, 0.XXXXXXXX expressed as an integer. The default value represent the 999 part of a 64bit binary fractional number equal to 0.999.
`P_IS_ANLOGIC`          |      0     | When '0' it generates generic BRAM and multiplier. When '1' it generates ANLOGIC BRAMs and DSPs targeting the SiPEED board.

## 6 Memory Map

| Memory Space | Address Range | Description
|:-----------: | :-----------: | :-----------------
| mem0         |     [0:31]    | General Registers.
| mem1         |     [0:31]    | General Registers.

### 6.1 General Register, mem0 and mem1

|          Address          | Bits | Access |    Reset    | Description
|:------------------------: | :--: | :----: | :---------: | :----------------
| [0x0000_0000:0x0000_001F] | 31:0 |   RW   | 0x0000_0000 | General registers. [1]

## 7 Resource Cost



## 8 Peformance


Implementation                                                | Runs |         User Time         | Cycles/Instruction | Dhrystones/Sec/MHz | DMIPS/MHz
:------------------------------------------------------------ | :--: | :-----------------------: | :----------------: | :----------------: | :-------:
ORC_R32IMAZicsr (aggressive div*) <br> Theoretical Maximums ->| 100  | 53261 cycles,  26125 insn <br> 38150 cycles, 26125 insn | 2.038 <br> 1.460 | 1876 <br> 2620 | 1.068 <br> 1.501
ORC_R32IMAZicsr (accurate div**) <br> Theoretical Maximums -> | 100  | 53472 cycles,  26136 insn <br> 38360 cycles, 26136 insn | 2.045 <br> 1.467 | 1870 <br> 2606 | 1.064 <br> 1.483

## 9 Directory Structure

- `build` _contains build scripts, synthesis scripts, build constraints, build outputs and bitstreams_
- `sim` _contains simulation scripts and test bench files_
- `source` _contains source code files (*.v)_

## 10 Simulation

Simulation scripts assumes _Icarus Verilog_ (iverilog) as the simulation tool. From the /sim directory run make. Options available are

Command       | Description
:------------ | :--------------------------------------------------------------------
`make`        | cleans, compiles and runs the test bench, then it loads the waveform.
`make clean`  | cleans all the compile and simulation products

## 11 Synthesis

Synthesis scripts assume _Yosys_ as the tool for synthesizing code and _Lattice ICE UP5K_ as the target FPGA device.

Command              | Description
:------------------- | :----------------------
`yosys syn_ice40.ys` | runs synthesis scripts.

## 12 Build

Build scripts are written for the Icestorm tool-chain. The target device is the up5k sold by Lattice.

Command    | Description
:--------- | :-----------------------------------------------------
`make all` | cleans, compiles and runs synthesis and build scripts.
