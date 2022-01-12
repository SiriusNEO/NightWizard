`timescale 1ns / 1ps

`ifndef DEF
`define DEF

// debug macro
`define DEBUG

// flag: protocol with ram.v
`define FLAG_READ 1'b0
`define FLAG_WRITE 1'b1

// specifications port
`define RAM_IO_PORT 32'h30000
`define PROGRAM_END 32'h30004

// constant
`define FALSE 1'b0
`define TRUE 1'b1

`define NEXT_PC 32'h4

`define ZERO_ADDR 32'h0
`define ZERO_WORD 32'h0
`define ZERO_REG 5'h0
`define ZERO_RS 5'h0
`define INVALID_RS 5'h10
`define ZERO_LSB 5'h0
`define INVALID_LSB 5'h10
`define ZERO_ROB 4'h0
`define ZERO_IQ 5'h0

`define FULL_WARNING 6
`define IQ_FULL_WARNING 2

// vec type
`define STATUS_TYPE 2:0
`define INT_TYPE 31:0
`define MEMPORT_TYPE 7:0
`define INS_TYPE 31:0
`define ADDR_TYPE 31:0
`define DATA_TYPE 31:0
`define OPENUM_TYPE 5:0

// notice: ID_TYPE always 1-bit wider than POS_TYPE
`define REG_POS_TYPE 4:0
`define ROB_POS_TYPE 3:0
`define LSB_POS_TYPE 3:0
`define IQ_POS_TYPE 3:0

`define RS_ID_TYPE 4:0
`define ROB_ID_TYPE 4:0
`define LSB_ID_TYPE 4:0
`define IQ_ID_TYPE 4:0

// components size
`define REG_SIZE 32
`define RS_SIZE  16
`define LSB_SIZE 16
`define ROB_SIZE 16
`define IQ_SIZE 16

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

// Decode Table: a table for decoding instruction

// range
`define OPCODE_RANGE 6:0
`define FUNC3_RANGE 14:12
`define FUNC7_RANGE 31:25
`define RD_RANGE 11:7
`define RS1_RANGE 19:15
`define RS2_RANGE 24:20

// opcode
`define OPCODE_LUI 7'b0110111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_JAL 7'b1101111
`define OPCODE_JALR 7'b1100111
`define OPCODE_BR 7'b1100011
`define OPCODE_L 7'b0000011
`define OPCODE_S 7'b0100011
`define OPCODE_ARITHI 7'b0010011
`define OPCODE_ARITH 7'b0110011

// func3
`define FUNC3_JALR 3'b000

`define FUNC3_BEQ  3'b000
`define FUNC3_BNE  3'b001
`define FUNC3_BLT  3'b100
`define FUNC3_BGE  3'b101
`define FUNC3_BLTU 3'b110
`define FUNC3_BGEU 3'b111

`define FUNC3_LB 3'b000
`define FUNC3_LH 3'b001
`define FUNC3_LW 3'b010
`define FUNC3_LBU 3'b100
`define FUNC3_LHU 3'b101

`define FUNC3_SB 3'b000
`define FUNC3_SH 3'b001
`define FUNC3_SW 3'b010

`define FUNC3_ADDI  3'b000
`define FUNC3_SLTI  3'b010
`define FUNC3_SLTIU 3'b011
`define FUNC3_XORI  3'b100
`define FUNC3_ORI   3'b110
`define FUNC3_ANDI  3'b111
`define FUNC3_SLLI  3'b001
`define FUNC3_SRLI  3'b101
`define FUNC3_SRAI  3'b101

`define FUNC3_ADD 3'b000
`define FUNC3_SUB 3'b000
`define FUNC3_SLL 3'b001
`define FUNC3_SLT 3'b010
`define FUNC3_SLTU 3'b011
`define FUNC3_XOR 3'b100
`define FUNC3_SRL 3'b101
`define FUNC3_SRA 3'b101
`define FUNC3_OR 3'b110
`define FUNC3_AND 3'b111

// func7 
`define FUNC7_NORM 7'b0000000
`define FUNC7_SPEC 7'b0100000

`endif