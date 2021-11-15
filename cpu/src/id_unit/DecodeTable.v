// a table for decoding instruction

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