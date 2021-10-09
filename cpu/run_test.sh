#!/bin/sh
# build testcase
./build_test.sh $@
# copy test input
if [ -f ./testcase/$@.in ]; then cp ./testcase/$@.in ./test/test.in; fi
# copy test output
if [ -f ./testcase/$@.ans ]; then cp ./testcase/$@.ans ./test/test.ans; fi
# add your own test script here
# Example:
# - iverilog/gtkwave/vivado
# - diff ./test/test.ans ./test/test.out

# compile
iverilog src/cpu.v src/ram.v src/riscv_top.v src/hci.v src/common/*/*.v sim/testbench.v -o out/a.out
cd out

# diff
# ./a.out > test.out
# diff test.out ../test/test.ans

# wave
vvp a.out
