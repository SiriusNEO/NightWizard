// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg [`OPENUM_LEN - 1 : 0] openum;
reg [`DATA_LEN - 1 : 0] oprand1;
reg [`DATA_LEN - 1 : 0] oprand2;
wire [`DATA_LEN - 1 : 0] result;

AL_Executor al_executor(
    .openum(openum),
    .oprand1(oprand1),
    .oprand2(oprand2),
    .result(result)
);

initial begin
    openum = 6'd22;
    oprand1 = 32'd1;
    oprand2 = 32'd4294967295; // -1
    #1 $display(result);

    openum = 6'd23;
    oprand1 = 32'd1;
    oprand2 = 32'd4294967295;
    #1 $display(result);

    #10 $finish;
end

// my testbench. generate .vcd
initial begin            
    $dumpfile("wave.vcd");
    $dumpvars();
end 

endmodule