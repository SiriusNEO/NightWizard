//`include "../defines.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Decoder(
    input wire [`INS_LEN - 1 : 0] inst, 
    
    output reg [`OPENUM_LEN - 1 : 0] op_enum,
    output reg [`REG_LEN - 1 : 0] rd,
    output reg [`REG_LEN - 1 : 0] rs1,
    output reg [`REG_LEN - 1 : 0] rs2,
    output reg [`DATA_LEN - 1 : 0] imm
);

always @(inst) begin
    rd <= inst[`RD_RANGE];
    rs1 <= inst[`RS1_RANGE];
    rs2 <= inst[`RS2_RANGE];

    case (inst[`OPCODE_RANGE])
        `OPCODE_LUI, `OPCODE_AUIPC: begin // U-Type
            imm <= inst[31 : 12];
            if (inst[`OPCODE_RANGE] == `OPCODE_LUI)
                op_enum <= `OPENUM_LUI;
            else 
                op_enum <= `OPENUM_AUIPC;
        end

        `OPCODE_JAL: begin // J-Type
            imm <= $signed({inst[31 : 31], inst[19 : 12], inst[20 : 20], inst[30 : 21], 1'b0});
            op_enum <= `OPENUM_JAL;
        end

        `OPCODE_JALR, `OPCODE_L, `OPCODE_ARITHI: begin // I-Type
            imm <= $signed(inst[31 : 20]);
            case (inst[`OPCODE_RANGE])
                `OPCODE_JALR: op_enum <= `OPENUM_JALR;
                `OPCODE_L: begin
                    case (inst[`FUNC3_RANGE])
                        `FUNC3_LB: op_enum <= `OPENUM_LB;
                        `FUNC3_LH: op_enum <= `OPENUM_LH;
                        `FUNC3_LW: op_enum <= `OPENUM_LW;
                        `FUNC3_LBU: op_enum <= `OPENUM_LBU;
                        `FUNC3_LHU: op_enum <= `OPENUM_LHU;
                    endcase
                end    
                `OPCODE_ARITHI: begin
                    if (inst[`FUNC3_RANGE] == `FUNC3_SRAI && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                        op_enum <= `OPENUM_SRA;
                    else begin
                        case (inst[`FUNC3_RANGE])
                            `FUNC3_ADDI:  op_enum <= `OPENUM_ADDI;
                            `FUNC3_SLTI:  op_enum <= `OPENUM_SLTI;
                            `FUNC3_SLTIU: op_enum <= `OPENUM_SLTIU;
                            `FUNC3_XORI:  op_enum <= `OPENUM_XORI;
                            `FUNC3_ORI:   op_enum <= `OPENUM_ORI;
                            `FUNC3_ANDI:  op_enum <= `OPENUM_ANDI;
                            `FUNC3_SLLI:  op_enum <= `OPENUM_SLLI;
                            `FUNC3_SRLI:  op_enum <= `OPENUM_SRLI;
                        endcase
                    end    
                end 
            endcase
        end

        `OPCODE_BR: begin // B-Type
            imm <= $signed({inst[31 : 31], inst[30 : 25], inst[11 : 8], inst[7 : 7]});
            case (inst[`FUNC3_RANGE])
                `FUNC3_BEQ:  op_enum <= `OPENUM_BEQ;
                `FUNC3_BNE:  op_enum <= `OPENUM_BNE;
                `FUNC3_BLT:  op_enum <= `OPENUM_BLT;
                `FUNC3_BGE:  op_enum <= `OPENUM_BGE;
                `FUNC3_BLTU: op_enum <= `OPENUM_BLTU;
                `FUNC3_BGEU: op_enum <= `OPENUM_BGEU;
            endcase
        end

        `OPCODE_S: begin // S-Type
            imm <= $signed({inst[31 : 25], inst[`RD_RANGE]});
            case (inst[`FUNC3_RANGE])
                `FUNC3_SB:  op_enum <= `OPENUM_SB;
                `FUNC3_SH:  op_enum <= `OPENUM_SH;
                `FUNC3_SW:  op_enum <= `OPENUM_SW;
            endcase
        end

        `OPCODE_ARITH: begin // R-Type
            if (inst[`FUNC3_RANGE] == `FUNC3_SUB && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                op_enum <= `OPENUM_SUB;
            else if (inst[`FUNC3_RANGE] == `FUNC3_SRAI && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                op_enum <= `OPENUM_SRA;
            else begin
                case (inst[`FUNC3_RANGE])
                    `FUNC3_ADD:  op_enum <= `OPENUM_ADD;
                    `FUNC3_SLT:  op_enum <= `OPENUM_SLT;
                    `FUNC3_SLTU: op_enum <= `OPENUM_SLTU;
                    `FUNC3_XOR:  op_enum <= `OPENUM_XOR;
                    `FUNC3_OR:   op_enum <= `OPENUM_OR;
                    `FUNC3_AND:  op_enum <= `OPENUM_AND;
                    `FUNC3_SLL:  op_enum <= `OPENUM_SLL;
                    `FUNC3_SRL:  op_enum <= `OPENUM_SRL;
                endcase
            end
        end 

        default begin
            op_enum <= `OPENUM_NOP;
            imm <= `ZERO_WORD;
        end    
    endcase
end

endmodule