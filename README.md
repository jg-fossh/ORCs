
## ORC_R32I

### Abstract

A 32-bit RISC-V ISA I instructions implementation.

### Resource Costs

#### Sipeed_PriMER (Anlogic Eagle FPGA)

_These results should be considered experimental as work is still under progress and this only accounts for I and M instructions. Remember to set P_IS_ANLOGIC = 1 in the ORC_R32I module_


|Utilization Statistics|     |                  |       |
| :------------------ | ---: | :--------------: | ----: |
| #lut                | 1995 |   out of  19600  | 10.18%|
| #reg                |  286 |   out of  19600  |  1.46%|
| #le                 | 2057 |          -       |     - |
|   #lut only         | 1771 |   out of   2908  | 86.10%|
|   #reg only         |   62 |   out of   2908  |  3.01%|
|   #lut&reg          |  224 |   out of   2908  | 10.89%|
| #dsp                |    0 |   out of     29  |  0.00%|
| #bram               |    0 |   out of     64  |  0.00%|
|   #bram9k           |    0 |        -         |  -    |
|   #fifo9k           |    0 |        -         |   -   |
| #bram32k            |    0 |   out of     16  |  0.00%|
| #pad                |  204 |   out of    188  |108.51%|
|   #ireg             |    8 |        -         |   -   |
|   #oreg             |    0 |        -         |   -   |
|   #treg             |    0 |        -         |   -   |
| #pll                |    0 |   out of      4  |  0.00%|



|Report Hierarchy Area: |     |       |       | |
:-------- | :-------- | :---- |:------| :---- |
| Instance | Module   | le    | lut   | seq   |
| top      | ORC_R32I | 2057  | 1995  | 286   |


#### Yosys Synthesis 
 Yosys version: `Yosys 0.9+3755 (git sha1 442d19f6, gcc 10.2.0-13ubuntu1 -fPIC -Os)`

 Yosys script: `syn_ice40.ys`

| Resource                  | Usage Count | 
| :------------------------ | ----------: |
| Number of  wire           |        2043 |
| Number of wire bits       |       10015 |
| Number of public wires    |        2043 |
| Number of public wire bits|       10015 |
| Number of memories        |           0 |
| Number of memory bits     |           0 |
| Number of processes       |           0 |
| Number of cells<br> --- SB_CARRY <br> --- SB_DFF <br> --- SB_DFFE <br> --- SB_DFFESR  <br> --- SB_DFFESS <br> --- SB_DFFSR <br> --- SB_DFFSS <br> --- SB_LUT4 |               5176<br>393<br>16<br>1028<br>171<br>2<br>104<br>1<br>3461|


### Performance

#### Dhrystone Benchmark (Version 2.1)

No two Dhrystone benchmark are the same since this is a compiler/core benchmark. Therefore a third party core was benchmarked and included for comparison.

Dhrystone test bench found in the picorv32 repo (https://github.com/cliffordwolf/picorv32/tree/master/dhrystone) was used and the same compiled code (hex file) on all cores for comparison.
Implementation           | CFLAGS (-march=) | Runs |         User Time         | Cycles/Instruction | Dhrystones/Sec/MHz | DMIPS/MHz
:----------------------- | :--------------: | :--: | :-----------------------: | :----------------: | :----------------: | :-------:
ORC_R32I (bypass) <br> Average Expected ->  <br> Theoretical Maximums -> |       rv32i      | 100  | <br> 58072 cycles,  29036 insn <br> 39858 cycles, 29036 insn | <br> 2.000 <br> 1.372| <br> 1722 <br> 2508 | <br> 0.980 <br> 1.427
picorv32                 |       rv32i      | 100  | 113154 cycles, 29036 insn |       3.897        |        883         |   0.502
picorv32 (no look ahead) |       rv32i      | 100  | 153707 cycles, 29036 insn |       5.293        |        650         |   0.369


    Note: The Average expected performance is the value expected by the Instruction interface working synchronously with minimal back pressure. Theoretical Maximums are obtained by simulating a prefect instruction cache.

#### Simulation Waveform Output 

##### This is a waveform snippet for reference 

 ![ORC_R32IM_Wave](wave.png)

