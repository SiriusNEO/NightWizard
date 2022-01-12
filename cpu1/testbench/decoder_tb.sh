# compile
iverilog ../src/defines.v ../src/id_unit/decoder.v decoder_tb.v -o ../out/a.out

#run
cd ../out/
# ./a.out

# wave
vvp a.out