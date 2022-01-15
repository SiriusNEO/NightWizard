### Version 1.0: Without ICache

PPCA ver Tomasulo —— AC is ok. Simple is best.

I waste too much time in considering how to design a elegant architecture, but I start to realize without trials these are just bullshit.


| testcase       | status         | clock    |
| -------------- | -------------- | -------- |
| array_test1    | p              |          |
| array_test2    | p              |          |
| basicopt1      | P              | 9503787  |
| bulgarian      | can't simulate |          |
| expr           | P              |          |
| gcd            | P              |          |
| hanoi          | can't simulate |          |
| heart          | can't simulate |          |
| looper         | P              |          |
| lvalue2        | P              |          |
| magic          | P              | 9473655  |
| manyarguments  | P              |          |
| multiarray     | P              |          |
| pi             | can't simulate |          |
| qsort          | P              |          |
| queens         | P              |          |
| statement_test | P              |          |
| superloop      | P              | 9332225  |
| tak            | P              | 22003201 |
| uartboom       | P              |          |



### Version 2.0: NightWizard

add:

- iCache
- Branch Predictor

do some optimizations and use more elegant design on my CPU

- [x] iCache finished
- [x] Branch Predictor

passed all testcases in FPGA board.

| testcase       | status | time (s) |
| -------------- | ------ | -------- |
| array_test1    | p      | 0.01     |
| array_test2    | p      | 0.01     |
| basicopt1      | P      | 0.02     |
| bulgarian      | P      | 1.79     |
| expr           | P      | 0.02     |
| gcd            | P      | 0.012    |
| hanoi          | P      | 3.42     |
| heart          | P      | 591.27   |
| looper         | P      | 0.042    |
| lvalue2        | P      | 0.005    |
| magic          | P      | 0.04     |
| manyarguments  | P      | 0.01     |
| multiarray     | P      | 0.02     |
| pi             | P      | 1.62     |
| qsort          | P      | 6.38     |
| queens         | P      | 3.11     |
| statement_test | P      | 0.013    |
| superloop      | P      | 0.019    |
| tak            | P      | 0.078    |
| uartboom       | P      | 0.78     |



### Version 3.0: MegaWizard

- [x] Instruction Queue (removed)
- [x] DCache (not efficient as I expected, removed)
- [x] Multi EX (two EXs, issue in one cycle)
- [ ] ~~Multi Dispatch (no so helpful)~~
- [x] Two Rams, 32bit-bus in ram1 (LW/SW in 1 cycle)

Simulation (compared with version 2.0):

| testcase  | clock (2.0) | clock (3.0) |
| --------- | ----------- | ----------- |
| superloop | 1786289     | 1376519     |
| basicopt1 | 2143659     | 1650793     |
| magic     | 5683183     | 1909529     |

On Board:

| testcase       | status | time (s) |
| -------------- | ------ | -------- |
| pi             | P      | 1.49     |
| supersuperloop | P      | 1.88     |
| ls             | P      | 4.49     |

#### Notice

- not always stable in 100MHz, sometimes get stuck

- because the data in BSS is loaded into ram0, the first load in BSS should be dispatched to ram0 (not ram1) !

  My solution is not perfect, so there are some problems if the code has too many global variables!

- Byte and Half Word will be dispatched to ram0 because of the bus width.  

