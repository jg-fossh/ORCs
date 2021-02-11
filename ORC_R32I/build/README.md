# Build Examples (Core only)

## Lattice_UP5K
 This design does not fit in the UP5K but the synthesis script is quick and provides a good estimate of resource comsuption for 4-input LUT based technologies.

## Sipeed_PriMER
# Results : Resources and Timing Estimates
_These results should be considered experimental as work is still under progress and this only accounts for I and M instructions. Remember to set P_IS_ANLOGIC = 1 in the ORC_R32IMAZicsr module_

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
| #lut                | 3137 |   out of  19600  | 16.01%|
| #reg                |  615 |   out of  19600  |  3.14%|
| #le                 | 3205 |          -       |     - |
|   #lut only         | 2590 |   out of   2908  | 80.81%|
|   #reg only         |   68 |   out of   2908  |  2.12%|
|   #lut&reg          |  547 |   out of   2908  | 17.07%|
| #dsp                |   15 |   out of     29  | 51.72%|
| #bram               |    4 |   out of     64  |  6.25%|
|   #bram9k           |    4 |        -         |  -    |
|   #fifo9k           |    0 |        -         |   -   |
| #bram32k            |    0 |   out of     16  |  0.00%|
| #pad                |  204 |   out of    188  |108.51%|
|   #ireg             |    8 |        -         |   -   |
|   #oreg             |    0 |        -         |   -   |
|   #treg             |    0 |        -         |   -   |
| #pll                |    0 |   out of      4  |  0.00%|

               

|Report Hierarchy Area: |  | | | |
:-------- | :-------- | :---- |:------| :---- |
| Instance | Module   | le    | lut   | seq   |
| top      | ORC_R32I | 3205  | 3137  | 615   |

