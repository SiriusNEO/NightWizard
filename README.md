

# NightWizard

<div align="center">
	<img src="doc/assets/gengar3.jpg" width="400px">
</div>
CS2951-1 Architecture Assignment, A Verilog HDL implemented RISC-V CPU.

Running on Basys3 FPGA Board (XC7A35T-ICPG236C) with all testcases passed.

![](https://img.shields.io/badge/language-Verilog-violet)

![](https://img.shields.io/badge/simulation-passed-success)

![](https://img.shields.io/badge/FPGA-passed-success)

(Archived temporarily because I have to deal with my Compiler)

### Feature

- Tomasulo with 16 entries RS, 16 entries LSB, 16 entries ROB.
- 256 entries I-Cache.
- Branch Prediction with 256 entries history table. 
- 80~100MHz supported (100MHz not always stable).
- High performance with testcase `pi.c` finish in `1.6s`.
- Elegant design and good code style.
- Some magic.

### TO DO

Version 3.0, expecting to add:

- [ ]  Superscalar (issue two instructions in one cycle)
- [ ]  Two RS & RS_EX or have a Branch RS.
- [ ] lower the WNS, make 100MHz stable and try overclocking.

### Docs

- [Versions Info](doc/Version.md)
- [Development Log](doc/DevelopDraft.md) (where I release my mood)
- [Design](doc/Design.md) (not finished now)
- [Tutorial of this homework](doc/Tutorial.md)

### References

- The RISC-V Instruction Set Manual (riscv-spec)
- RISC-V-Reader-Chinese
- Computer Architecture A Quantitative Approach,  *John L Hennessy & David A Patterson*
- https://github.com/ZYHowell/YPU