// testbench top module file
// for simulation only

`timescale 1ns/1ps
module testbench;

reg [`INS_LEN - 1 : 0] inst;
reg clk;
reg rst;

wire [`INS_LEN - 1 : 0] inst_dsp_dcd;

wire [`OPENUM_LEN - 1 : 0] op_enum_dcd_dsp;
wire [`REG_LEN - 1 : 0] rd_dcd_dsp;
wire [`REG_LEN - 1 : 0] rs1_dcd_dsp;
wire [`REG_LEN - 1 : 0] rs2_dcd_dsp;
wire [`DATA_LEN - 1 : 0] imm_dcd_dsp;

Decoder decoder(
    .inst(inst_dsp_dcd),
    .op_enum(op_enum_dcd_dsp),
    .rd(rd_dcd_dsp),
    .rs1(rs1_dcd_dsp),
    .rs2(rs2_dcd_dsp),
    .imm(imm_dcd_dsp)
);

Dispatcher dispatcher(
    .clk(clk),
    .rst(rst), 
    .inst_from_if(inst),
    
    .inst_to_dcd(inst_dsp_dcd),

    .openum_from_dcd(op_enum_dcd_dsp),
    .rd_from_dcd(rd_dcd_dsp),
    .rs1_from_dcd(rs1_dcd_dsp),
    .rs2_from_dcd(rs2_dcd_dsp),
    .imm_from_dcd(imm_dcd_dsp)
);

Registers registers(
    .clk(clk),
    .rst(rst)
);

ReserveStation rs(
    .clk(clk),
    .rst(rst)
);

initial begin
    clk=0;
    rst=0;
    repeat(50) #1 clk=!clk;
    $finish;
end

initial begin
    inst = 32'h00020137; // lui	sp,0x20
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