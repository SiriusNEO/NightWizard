# NightWizard

a RISC-V CPU.

magic.



### Version 1.0

PPCA ver Tomasulo —— AC is ok. Simple is best.

I waste too much time in considering how to design a elegant architecture, but I start to realize without trials these are just bullshit.



| testcase       | status | clock   |
| -------------- | ------ | ------- |
| array_test1    | p      |         |
| array_test2    | p      |         |
| basicopt1      | P      | 9503787 |
| bulgarian      |        |         |
| expr           | P      |         |
| gcd            | P      |         |
| hanoi          |        |         |
| heart          |        |         |
| looper         | P      |         |
| lvalue2        | P      |         |
| magic          |        |         |
| manyarguments  | P      |         |
| multiarray     | P      |         |
| pi             |        |         |
| qsort          | P      |         |
| queens         |        |         |
| statement_test | P      |         |
| superloop      | P      | 9332225 |
| tak            | P      |         |
| uartboom       |        |         |

### Version 2.0

add:

- icache
- branch predictor
- dcache（maybe）
- write buffer

do some optimizations and use more elegant design on my CPU

