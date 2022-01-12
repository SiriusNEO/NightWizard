# compile
iverilog ../src/ex_unit/AL_Executor.v ex_tb.v -o ../out/a.out

#run
cd ../out/
# ./a.out

# wave
vvp a.out