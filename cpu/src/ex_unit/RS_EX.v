`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RS_EX(
    input wire [`OPENUM_LEN - 1 : 0] openum,
    input wire [`DATA_LEN - 1 : 0] V1,
    input wire [`DATA_LEN - 1 : 0] V2,
    input wire [`DATA_LEN - 1 : 0] imm,
    input wire [`ADDR_LEN - 1 : 0] pc,

    output reg [`DATA_LEN - 1 : 0] result,
    output reg [`ADDR_LEN - 1 : 0] target_pc
);

always @(*) begin
    case (openum)
        `OPENUM_LUI:
            result <= imm;
        `OPENUM_AUIPC:
            result <= pc + imm;
        `OPENUM_JAL: begin
            target_pc <= pc + imm;
            result <= pc + 4;
        end    
        `OPENUM_JALR: begin
            target_pc <= (V1 + imm) & ~1;
            result <= pc + 4;
        end
        `OPENUM_BEQ: begin
            target_pc <= pc + imm;
            result <= (V1 == V2);
        end    
        `OPENUM_BNE: begin
            target_pc <= pc + imm;
            result <= (V1 != V2);   
        end     
        `OPENUM_BLT: begin
            target_pc <= pc + imm;
            result <= ($signed(V1) < $signed(V2));
        end    
        `OPENUM_BGE: begin
            target_pc <= pc + imm;
            result <= ($signed(V1) >= $signed(V2));
        end    
        `OPENUM_BLTU: begin
            target_pc <= pc + imm;
            result <= ($signed(V1) < $signed(V2));
        end    
        `OPENUM_BGEU: begin
            target_pc <= pc + imm;
            result <= ($signed(V1) >= $signed(V2));
        end    
        `OPENUM_ADD: 
            result <= V1 + V2;
        `OPENUM_SUB: 
            result <= V1 - V2;
        `OPENUM_SLL: 
            result <= (V1 << V2);
        `OPENUM_SLT: 
            result <= ($signed(V1) < $signed(V2));
        `OPENUM_SLTU: 
            result <= (V1 < V2);
        `OPENUM_XOR: 
            result <= V1 ^ V2;
        `OPENUM_SRL: 
            result <= (V1 >> V2);
        `OPENUM_SRA: 
            result <= $signed(V1 >> V2);
        `OPENUM_OR: 
            result <= (V1 | V2);
        `OPENUM_AND: 
            result <= (V1 & V2);
        `OPENUM_ADDI:
            result <= V1 + imm;
        `OPENUM_SLLI:
            result <= (V1 << imm);
        `OPENUM_SLTI: 
            result <= ($signed(V1) < $signed(imm));
        `OPENUM_SLTIU:
            result <= (V1 < imm);  
        `OPENUM_XORI:
            result <= V1 ^ imm;     
        `OPENUM_SRLI:
            result <= (V1 >> imm);
        `OPENUM_SRAI:  
            result <= $signed(V1 >> imm);  
        `OPENUM_ORI:
            result <= (V1 | imm);
        `OPENUM_ANDI:
            result <= (V1 & imm);    
        default: result <= `ZERO_WORD; 
    endcase

end

endmodule