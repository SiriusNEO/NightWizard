// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg [`INS_TYPE] inst;
reg clk;
reg rst;

wire [`INS_TYPE] inst_dsp_dcd;

wire [`OPENUM_TYPE] op_enum_dcd_dsp;
wire [`REG_POS_TYPE] rd_dcd_dsp;
wire [`REG_POS_TYPE] rs1_dcd_dsp;
wire [`REG_POS_TYPE] rs2_dcd_dsp;
wire [`OPENUM_TYPE] imm_dcd_dsp;

Decoder decoder(
    .inst(inst_dsp_dcd),
    .op_enum(op_enum_dcd_dsp),
    .rd(rd_dcd_dsp),
    .rs1(rs1_dcd_dsp),
    .rs2(rs2_dcd_dsp),
    .imm(imm_dcd_dsp)
);

initial begin
    clk=0;
    rst=0;
    repeat(50) #1 clk=!clk;
    $finish;
end

initial begin
    inst = 32'h0ff57513; // zext
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);

    inst = 32'h02912223; // sw	s1,36(sp)
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);

    inst = 32'hfd010113; // addi	sp,sp,-48 # 1ffd0 <__heap_start+0x1dfd0>
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);

    inst = 32'hfe891ae3; // bne	s2,s0,109c <outl+0x9c>
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);

    inst = 32'h02412483; // lw	s1,36(sp)
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);

    inst = 32'hfd3a46e3; // blt	s4,s3,1044 <outl+0x44>
    #2 $display("decode result: op_enum = %d, rd = %d, rs1 = %d, rs2 = %d, imm = %d", op_enum_dcd_dsp, rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp, imm_dcd_dsp);
end    

// my testbench. generate .vcd
initial begin            
    $dumpfile("wave.vcd");
    $dumpvars();
end 

endmodule