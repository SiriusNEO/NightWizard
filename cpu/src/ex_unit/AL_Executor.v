`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module AL_Executor(
    input wire [`OPENUM_LEN - 1 : 0] openum,
    input wire [`DATA_LEN - 1 : 0] oprand1,
    input wire [`DATA_LEN - 1 : 0] oprand2,

    output reg [`DATA_LEN - 1 : 0] result
);

always @(*) begin
    
    case (openum)
        `OPENUM_ADD, `OPENUM_ADDI: 
            result = oprand1 + oprand2;
        `OPENUM_SUB: 
            result = oprand1 - oprand2;
        `OPENUM_SLL, `OPENUM_SLLI: 
            result = (oprand1 << oprand2);
        `OPENUM_SLT, `OPENUM_SLTI: 
            result = ($signed(oprand1) < $signed(oprand2));
        `OPENUM_SLTU, `OPENUM_SLTIU: 
            result = (oprand1 < oprand2);
        `OPENUM_XOR, `OPENUM_XORI: 
            result = oprand1 ^ oprand2;
        `OPENUM_SRL, `OPENUM_SRLI: 
            result = (oprand1 >> oprand2);
        `OPENUM_SRA, `OPENUM_SRAI: 
            result = $signed(oprand1 >> oprand2);
        `OPENUM_OR, `OPENUM_ORI: 
            result = (oprand1 | oprand2);
        `OPENUM_AND, `OPENUM_ANDI: 
            result = (oprand1 & oprand2);
        default: result = `ZERO_WORD; 
    endcase

end

endmodule