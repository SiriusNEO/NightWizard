`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Decoder(
    input wire [`INS_TYPE] inst, 
    
    output reg is_jump,
    output reg is_store,
    output reg [`OPENUM_TYPE] openum,
    output reg [`REG_POS_TYPE] rd,
    output reg [`REG_POS_TYPE] rs1,
    output reg [`REG_POS_TYPE] rs2,
    output reg [`DATA_TYPE] imm
);

integer jalr_cnt = 0;

always @(*) begin
    openum = `OPENUM_NOP;
    rd = inst[`RD_RANGE];
    rs1 = inst[`RS1_RANGE];
    rs2 = inst[`RS2_RANGE];
    imm = `ZERO_WORD;
    is_jump = `FALSE;
    is_store = `FALSE;
    
    case (inst[`OPCODE_RANGE])
        `OPCODE_LUI, `OPCODE_AUIPC: begin // U-Type
            imm = {inst[31:12], 12'b0};
            if (inst[`OPCODE_RANGE] == `OPCODE_LUI)
                openum = `OPENUM_LUI;
            else 
                openum = `OPENUM_AUIPC;
        end

        `OPCODE_JAL: begin // J-Type
            imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
            openum = `OPENUM_JAL;
            is_jump = `TRUE;
        end

        `OPCODE_JALR, `OPCODE_L, `OPCODE_ARITHI: begin // I-Type
            imm = {{21{inst[31]}}, inst[30:20]};
            case (inst[`OPCODE_RANGE])
                `OPCODE_JALR: begin
                    openum = `OPENUM_JALR;
                    is_jump = `TRUE;
                    // jalr_cnt = jalr_cnt + 1;
                    // if (jalr_cnt % 1000 == 0) $display("jalr: ", jalr_cnt);
                end
                `OPCODE_L: begin
                    case (inst[`FUNC3_RANGE])
                        `FUNC3_LB: openum = `OPENUM_LB;
                        `FUNC3_LH: openum = `OPENUM_LH;
                        `FUNC3_LW: openum = `OPENUM_LW;
                        `FUNC3_LBU: openum = `OPENUM_LBU;
                        `FUNC3_LHU: openum = `OPENUM_LHU;
                    endcase
                end    
                `OPCODE_ARITHI: begin
                    if (inst[`FUNC3_RANGE] == `FUNC3_SRAI && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                        openum = `OPENUM_SRAI;
                    else begin
                        case (inst[`FUNC3_RANGE])
                            `FUNC3_ADDI:  openum = `OPENUM_ADDI;
                            `FUNC3_SLTI:  openum = `OPENUM_SLTI;
                            `FUNC3_SLTIU: openum = `OPENUM_SLTIU;
                            `FUNC3_XORI:  openum = `OPENUM_XORI;
                            `FUNC3_ORI:   openum = `OPENUM_ORI;
                            `FUNC3_ANDI:  openum = `OPENUM_ANDI;
                            `FUNC3_SLLI:  openum = `OPENUM_SLLI;
                            `FUNC3_SRLI:  openum = `OPENUM_SRLI;
                        endcase
                    end
                    // shamt
                    if (openum == `OPENUM_SLLI || openum == `OPENUM_SRLI || openum == `OPENUM_SRAI) begin
                        imm = imm[4:0];
                    end    
                end 
            endcase
        end

        `OPCODE_BR: begin // B-Type
            rd = `ZERO_REG; // no rd
            imm = {{20{inst[31]}}, inst[7:7], inst[30:25], inst[11:8], 1'b0};
            is_jump = `TRUE;
            case (inst[`FUNC3_RANGE])
                `FUNC3_BEQ:  openum = `OPENUM_BEQ;
                `FUNC3_BNE:  openum = `OPENUM_BNE;
                `FUNC3_BLT:  openum = `OPENUM_BLT;
                `FUNC3_BGE:  openum = `OPENUM_BGE;
                `FUNC3_BLTU: openum = `OPENUM_BLTU;
                `FUNC3_BGEU: openum = `OPENUM_BGEU;
            endcase
        end

        `OPCODE_S: begin // S-Type
            rd = `ZERO_REG; // no rd
            imm = {{21{inst[31]}}, inst[30:25], inst[`RD_RANGE]};
            is_store = `TRUE;
            case (inst[`FUNC3_RANGE])
                `FUNC3_SB:  openum = `OPENUM_SB;
                `FUNC3_SH:  openum = `OPENUM_SH;
                `FUNC3_SW:  openum = `OPENUM_SW;
            endcase
        end

        `OPCODE_ARITH: begin // R-Type
            if (inst[`FUNC3_RANGE] == `FUNC3_SUB && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                openum = `OPENUM_SUB;
            else if (inst[`FUNC3_RANGE] == `FUNC3_SRAI && inst[`FUNC7_RANGE] == `FUNC7_SPEC) 
                openum = `OPENUM_SRA;
            else begin
                case (inst[`FUNC3_RANGE])
                    `FUNC3_ADD:  openum = `OPENUM_ADD;
                    `FUNC3_SLT:  openum = `OPENUM_SLT;
                    `FUNC3_SLTU: openum = `OPENUM_SLTU;
                    `FUNC3_XOR:  openum = `OPENUM_XOR;
                    `FUNC3_OR:   openum = `OPENUM_OR;
                    `FUNC3_AND:  openum = `OPENUM_AND;
                    `FUNC3_SLL:  openum = `OPENUM_SLL;
                    `FUNC3_SRL:  openum = `OPENUM_SRL;
                endcase
            end
        end 

        default begin
            openum = `OPENUM_NOP;
            imm = `ZERO_WORD;
        end    
    endcase
end

endmodule