`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RS_EX(
    input wire ena,
    input wire [`OPENUM_LEN - 1 : 0] openum,
    input wire [`DATA_LEN - 1 : 0] V1,
    input wire [`DATA_LEN - 1 : 0] V2,
    input wire [`DATA_LEN - 1 : 0] imm,
    input wire [`ADDR_LEN - 1 : 0] pc,

    output reg [`DATA_LEN - 1 : 0] result,
    output reg [`ADDR_LEN - 1 : 0] target_pc,
    output reg jump_flag,
    output reg valid
);

always @(*) begin
    if (openum == `OPENUM_NOP) begin
        valid <= `FALSE;
    end
    else begin
        valid <= `TRUE;
    end
    case (openum)
        `OPENUM_LUI: begin
            result <= imm;
            jump_flag <= `FALSE;
        end
        `OPENUM_AUIPC: begin
            result <= pc + imm;
            jump_flag <= `FALSE;
        end
        `OPENUM_JAL: begin
            target_pc <= pc + imm;
            result <= pc + 4;
            jump_flag <= `TRUE;
        end    
        `OPENUM_JALR: begin
            target_pc <= (V1 + imm) & ~1;
            result <= pc + 4;
            jump_flag <= `TRUE;
        end
        `OPENUM_BEQ: begin
            target_pc <= pc + imm;
            jump_flag <= (V1 == V2);
        end    
        `OPENUM_BNE: begin
            target_pc <= pc + imm;
            jump_flag <= (V1 != V2);   
        end     
        `OPENUM_BLT: begin
            target_pc <= pc + imm;
            jump_flag <= ($signed(V1) < $signed(V2));
        end    
        `OPENUM_BGE: begin
            target_pc <= pc + imm;
            jump_flag <= ($signed(V1) >= $signed(V2));
        end    
        `OPENUM_BLTU: begin
            target_pc <= pc + imm;
            jump_flag <= ($signed(V1) < $signed(V2));
        end    
        `OPENUM_BGEU: begin
            target_pc <= pc + imm;
            jump_flag <= ($signed(V1) >= $signed(V2));
        end    
        `OPENUM_ADD: begin
            result <= V1 + V2;
            jump_flag <= `FALSE;
        end
        `OPENUM_SUB: begin
            result <= V1 - V2;
            jump_flag <= `FALSE;
        end
        `OPENUM_SLL: begin
            result <= (V1 << V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_SLT: begin
            result <= ($signed(V1) < $signed(V2));
            jump_flag <= `FALSE;
        end
        `OPENUM_SLTU: begin
            result <= (V1 < V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_XOR: begin
            result <= V1 ^ V2;
            jump_flag <= `FALSE;
        end
        `OPENUM_SRL: begin
            result <= (V1 >> V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_SRA: begin
            result <= $signed(V1 >> V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_OR: begin
            result <= (V1 | V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_AND: begin
            result <= (V1 & V2);
            jump_flag <= `FALSE;
        end
        `OPENUM_ADDI: begin
            result <= V1 + imm;
            jump_flag <= `FALSE;
        end
        `OPENUM_SLLI: begin
            result <= (V1 << imm);
            jump_flag <= `FALSE;
        end
        `OPENUM_SLTI: begin
            result <= ($signed(V1) < $signed(imm));
            jump_flag <= `FALSE;
        end
        `OPENUM_SLTIU: begin
            result <= (V1 < imm);  
            jump_flag <= `FALSE;
        end
        `OPENUM_XORI: begin
            result <= V1 ^ imm;
            jump_flag <= `FALSE;
        end     
        `OPENUM_SRLI: begin
            result <= (V1 >> imm);
            jump_flag <= `FALSE;
        end
        `OPENUM_SRAI: begin  
            result <= $signed(V1 >> imm);
            jump_flag <= `FALSE;
        end
        `OPENUM_ORI: begin
            result <= (V1 | imm);
            jump_flag <= `FALSE;
        end
        `OPENUM_ANDI: begin
            result <= (V1 & imm);
            jump_flag <= `FALSE;
        end    
        default: begin
            result <= `ZERO_WORD;
            target_pc <= `ZERO_ADDR;
            jump_flag <= `FALSE;
        end 
    endcase

end

endmodule