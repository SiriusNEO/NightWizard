
// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg clk;
reg rst;
reg rdy;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);
integer cnt = 0;
initial begin
  clk=0;
  rst=1;
  rdy=1;
  repeat(50) #1 clk=!clk;
  rst=0; 
  forever begin
    #1 clk=!clk;
    cnt=cnt+1;
    if (cnt%100000==0) $display(cnt);
  end
  $finish;
end

// my testbench. generate .vcd

initial begin            
    $dumpfile("wave.vcd");
    $dumpvars();
end

endmodule