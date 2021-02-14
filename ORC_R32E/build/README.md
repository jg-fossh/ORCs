# Build Examples (Core only)

## Lattice_UP5K
 This design does not fit in the UP5K but the synthesis script is quick and provides a good estimate of resource comsuption for 4-input LUT based technologies.

## Sipeed_PriMER
# Results : Resources and Timing Estimates
_These results should be considered experimental as work is still under progress and this only accounts for I and M instructions. Remember to set P_IS_ANLOGIC = 1 in the ORC_R32E module_

## TD Workflow (uses BRAMs)

### Synthesis and Mapping

| IO Statistics |           |
| :------------ | --------: |
| #IO           |       204 |
|   #input      |        69 |
|   #output     |       135 |
|   #inout      |         0 |


|Utilization Statistics|     |                  |       |
| :------------------ | ---: | :--------------: | ----: |
| #lut                | 1532 |   out of  19600  |  7.82%|
| #reg                |  112 |   out of  19600  |  0.57%|
| #le                 | 1532 |          -       |     - |
|   #lut only         | 1420 |   out of   2908  | 92.69%|
|   #reg only         |    0 |   out of   2908  |  0.00%|
|   #lut&reg          |  112 |   out of   2908  |  7.31%|
| #dsp                |    0 |   out of     29  |  0.00%|
| #bram               |    0 |   out of     64  |  0.00%|
|   #bram9k           |    0 |        -         |  -    |
|   #fifo9k           |    0 |        -         |   -   |
| #bram32k            |    0 |   out of     16  |  0.00%|
| #pad                |  204 |   out of    188  |108.51%|
|   #ireg             |    4 |        -         |   -   |
|   #oreg             |    0 |        -         |   -   |
|   #treg             |    0 |        -         |   -   |
| #pll                |    0 |   out of      4  |  0.00%|



|Report Hierarchy Area: |  | | | |
:-------- | :-------- | :---- |:------| :---- |
| Instance | Module   | le    | lut   | seq   |
| top      | ORC_R32E | 1532  | 1532  | 112   |
