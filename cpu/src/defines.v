`timescale 1ns / 1ps

// debug macro
`define DEBUG

// flag: protocol with ram.v
`define FLAG_READ 1'b0
`define FLAG_WRITE 1'b1

// constant
`define FALSE 1'b0
`define TRUE 1'b1
`define ZERO_ADDR 32'h0
`define ZERO_WORD 32'h0
`define ZERO_REG 5'h0
`define ZERO_RS 4'h0
`define ZERO_ROB 5'h0

// vec type
`define INT_TYPE 31:0
`define MEMPORT_TYPE 7:0
`define INS_TYPE 31:0
`define ADDR_TYPE 31:0
`define DATA_TYPE 31:0
`define OPENUM_TYPE 5:0
`define REG_POS_TYPE 4:0
`define ROB_POS_TYPE 4:0
`define ROB_ID_TYPE 5:0
`define LSB_POS_TYPE 3:0

// components size
`define REG_SIZE 32
`define RS_SIZE  16
`define LSB_SIZE 16
`define ROB_SIZE 32

// 2^6 op enum
`define OPENUM_NOP     6'd0

`define OPENUM_LUI     6'd1
`define OPENUM_AUIPC   6'd2

`define OPENUM_JAL     6'd3
`define OPENUM_JALR    6'd4

`define OPENUM_BEQ     6'd5
`define OPENUM_BNE     6'd6
`define OPENUM_BLT     6'd7 
`define OPENUM_BGE     6'd8
`define OPENUM_BLTU    6'd9 
`define OPENUM_BGEU    6'd10 

`define OPENUM_LB      6'd11 
`define OPENUM_LH      6'd12 
`define OPENUM_LW      6'd13 
`define OPENUM_LBU     6'd14 
`define OPENUM_LHU     6'd15 
`define OPENUM_SB      6'd16 
`define OPENUM_SH      6'd17 
`define OPENUM_SW      6'd18 

`define OPENUM_ADD     6'd19 
`define OPENUM_SUB     6'd20 
`define OPENUM_SLL     6'd21 
`define OPENUM_SLT     6'd22 
`define OPENUM_SLTU    6'd23 
`define OPENUM_XOR     6'd24 
`define OPENUM_SRL     6'd25 
`define OPENUM_SRA     6'd26
`define OPENUM_OR      6'd27 
`define OPENUM_AND     6'd28

`define OPENUM_ADDI    6'd29
`define OPENUM_SLTI    6'd30
`define OPENUM_SLTIU   6'd31
`define OPENUM_XORI    6'd32
`define OPENUM_ORI     6'd33
`define OPENUM_ANDI    6'd34
`define OPENUM_SLLI    6'd35
`define OPENUM_SRLI    6'd36
`define OPENUM_SRAI    6'd37 