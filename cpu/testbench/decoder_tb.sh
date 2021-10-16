# compile
iverilog ../src/Registers.v ../src/ex_unit/*.v ../src/id_unit/*.v ../src/defines.v decoder_tb.v -o ../out/a.out

#run
cd ../out/
# ./a.out

# wave
vvp a.out