`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RS_EX(
    input wire [`OPENUM_TYPE] openum,
    input wire [`DATA_TYPE] V1,
    input wire [`DATA_TYPE] V2,
    input wire [`DATA_TYPE] imm,
    input wire [`ADDR_TYPE] pc,

    output reg [`DATA_TYPE] result,
    output reg [`ADDR_TYPE] target_pc,
    output reg jump_flag,
    output reg valid
);

always @(*) begin
    valid = (openum != `OPENUM_NOP);
    result = `ZERO_WORD;
    jump_flag = `FALSE;
    target_pc = `ZERO_ADDR;
    case (openum)
        `OPENUM_LUI: begin
            result = imm;
        end
        `OPENUM_AUIPC: begin
            result = pc + imm;
        end
        `OPENUM_JAL: begin
            target_pc = pc + imm;
            result = pc + 4;
            jump_flag = `TRUE;
        end    
        `OPENUM_JALR: begin
            target_pc = V1 + imm;
            result = pc + 4;
            jump_flag = `TRUE;
        end
        `OPENUM_BEQ: begin
            target_pc = pc + imm;
            jump_flag = (V1 == V2);
        end    
        `OPENUM_BNE: begin
            target_pc = pc + imm;
            jump_flag = (V1 != V2);   
        end     
        `OPENUM_BLT: begin
            target_pc = pc + imm;
            jump_flag = ($signed(V1) < $signed(V2));
        end    
        `OPENUM_BGE: begin
            target_pc = pc + imm;
            jump_flag = ($signed(V1) >= $signed(V2));
        end    
        `OPENUM_BLTU: begin
            target_pc = pc + imm;
            jump_flag = (V1 < V2);
        end    
        `OPENUM_BGEU: begin
            target_pc = pc + imm;
            jump_flag = (V1 >= V2);
        end    
        `OPENUM_ADD: begin
            result = V1 + V2;
        end
        `OPENUM_SUB: begin
            result = V1 - V2;
        end
        `OPENUM_SLL: begin
            result = (V1 << V2);
        end
        `OPENUM_SLT: begin
            result = ($signed(V1) < $signed(V2));
        end
        `OPENUM_SLTU: begin
            result = (V1 < V2);
        end
        `OPENUM_XOR: begin
            result = V1 ^ V2;
        end
        `OPENUM_SRL: begin
            result = (V1 >> V2);
        end
        `OPENUM_SRA: begin
            result = (V1 >>> V2);
        end
        `OPENUM_OR: begin
            result = (V1 | V2);
        end
        `OPENUM_AND: begin
            result = (V1 & V2);
        end
        `OPENUM_ADDI: begin
            result = V1 + imm;
        end
        `OPENUM_SLLI: begin
            result = (V1 << imm);
        end
        `OPENUM_SLTI: begin
            result = ($signed(V1) < $signed(imm));
        end
        `OPENUM_SLTIU: begin
            result = (V1 < imm);  
        end
        `OPENUM_XORI: begin
            result = V1 ^ imm;
        end     
        `OPENUM_SRLI: begin
            result = (V1 >> imm);
        end
        `OPENUM_SRAI: begin  
            result = (V1 >>> imm);
        end
        `OPENUM_ORI: begin
            result = (V1 | imm);
        end
        `OPENUM_ANDI: begin
            result = (V1 & imm);
        end
    endcase
    
    // notice: branch & store also has result for debug purpose
    // these result will be written to zero reg, so no influence
    
    if (openum >= `OPENUM_BEQ && openum <= `OPENUM_BGEU) begin
        result = jump_flag;
    end
end

endmodule