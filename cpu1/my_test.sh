# --- build ---

#!/bin/sh
set -e
prefix='/opt/riscv'
rpath=$prefix/bin/
# clearing test dir
rm -rf ./test
mkdir ./test
# compiling rom
${rpath}riscv32-unknown-elf-as -o ./sys/rom.o -march=rv32i ./sys/rom.s
# compiling testcase
cp ./testcase_selfmade/${1%.*}.c ./test/test.c
${rpath}riscv32-unknown-elf-gcc -o ./test/test.o -I ./sys -c ./test/test.c -O2 -march=rv32i -mabi=ilp32 -Wall
# linking
${rpath}riscv32-unknown-elf-ld -T ./sys/memory.ld ./sys/rom.o ./test/test.o -L $prefix/riscv32-unknown-elf/lib/ -L $prefix/lib/gcc/riscv32-unknown-elf/10.2.0/ -lc -lgcc -lm -lnosys -o ./test/test.om
# converting to verilog format
${rpath}riscv32-unknown-elf-objcopy -O verilog ./test/test.om ./test/test.data
# converting to binary format(for ram uploading)
${rpath}riscv32-unknown-elf-objcopy -O binary ./test/test.om ./test/test.bin
# decompile (for debugging)
${rpath}riscv32-unknown-elf-objdump -D ./test/test.om > ./test/test.dump



# --- run ---

#!/bin/sh
# copy test input
if [ -f ./testcase_selfmade/$@.in ]; then cp ./testcase_selfmade/$@.in ./test/test.in; fi
# copy test output
if [ -f ./testcase_selfmade/$@.ans ]; then cp ./testcase_selfmade/$@.ans ./test/test.ans; fi
# add your own test script here
# Example:
# - iverilog/gtkwave/vivado
# - diff ./test/test.ans ./test/test.out

# compile
iverilog src/cpu.v src/ram.v src/data_ram.v src/riscv_top.v src/hci.v src/common/*/*.v sim/testbench.v -o out/a.out
cd out

# diff
# ./a.out > test.out
# diff test.out ../test/test.ans

# wave
vvp a.out
