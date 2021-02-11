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
| #lut                | 3095 |   out of  19600  | 15.79%|
| #reg                |  430 |   out of  19600  |  2.19%|
| #le                 | 3103 |          -       |     - |
|   #lut only         | 2673 |   out of   3103  | 86.14%|
|   #reg only         |    8 |   out of   3103  |  0.26%|
|   #lut&reg          |  422 |   out of   3103  | 13.60%|
| #dsp                |   15 |   out of     29  | 51.72%|
| #bram               |    4 |   out of     64  |  6.25%|
|   #bram9k           |    4 |        -         |  -    |
|   #fifo9k           |    0 |        -         |   -   |
| #bram32k            |    0 |   out of     16  |  0.00%|
| #pad                |  204 |   out of    188  |108.51%|
|   #ireg             |    0 |        -         |   -   |
|   #oreg             |    0 |        -         |   -   |
|   #treg             |    0 |        -         |   -   |
| #pll                |    0 |   out of      4  |  0.00%|

               

|Report Hierarchy Area: |  | | | |
:-------- | :-------- | :---- |:------| :---- |
| Instance | Module   | le    | lut   | seq   |
| top      | ORC_R32I | 3103  | 3095  | 430   |