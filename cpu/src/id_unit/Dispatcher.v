`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Dispatcher(
    input wire clk,
    input wire rst,

    // from fetcher
    input wire [`INS_LEN - 1 : 0] inst_from_if,

    // to decoder
    output reg [`INS_LEN - 1 : 0] inst_to_dcd,
    // from decoder
    input wire [`OPENUM_LEN - 1 : 0] openum_from_dcd,
    input wire [`REG_LEN - 1 : 0] rd_from_dcd,
    input wire [`REG_LEN - 1 : 0] rs1_from_dcd,
    input wire [`REG_LEN - 1 : 0] rs2_from_dcd,
    input wire [`DATA_LEN - 1 : 0] imm_from_dcd,

    // to reg
    output reg [`REG_LEN - 1 : 0] rs1_to_reg,
    output reg [`REG_LEN - 1 : 0] rs2_to_reg, 
    // from reg
    input wire [`DATA_LEN -1 : 0] V1_from_reg,
    input wire [`DATA_LEN -1 : 0] V2_from_reg,
    input wire [`ROB_LEN -1 : 0] Q1_from_reg,
    input wire [`ROB_LEN -1 : 0] Q2_from_reg,

    // to rs
    output reg [`OPENUM_LEN - 1 : 0] openum_to_rs,
    output reg [`DATA_LEN -1 : 0] V1_to_rs,
    output reg [`DATA_LEN -1 : 0] V2_to_rs,
    output reg [`ROB_LEN -1 : 0] Q1_to_rs,
    output reg [`ROB_LEN -1 : 0] Q2_to_rs,
    output reg [`ADDR_LEN -1 : 0] pc_to_rs,
    output reg [`ADDR_LEN -1 : 0] imm_to_rs,
    // from rs
    input wire full_from_rs,

    // to lsq
    output reg [`OPENUM_LEN - 1 : 0] openum_to_lsq,
    output reg [`DATA_LEN -1 : 0] oprand1_to_lsq,
    output reg [`DATA_LEN -1 : 0] oprand2_to_lsq
);

always @(posedge clk, posedge rst) begin
   
   if (rst == `TRUE) begin
   end else begin
        // call dcd
        inst_to_dcd = inst_from_if;

        // call reg
        rs1_to_reg = rs1_from_dcd;
        rs2_to_reg = rs2_from_dcd; 

        // to lsq
        if (openum_from_dcd >= `OPENUM_LB && openum_from_dcd <= `OPENUM_SW) begin
            
        end 
        // to rs
        else if (openum_from_dcd != `OPENUM_NOP) begin
            openum_to_rs <= openum_from_dcd;
            V1_to_rs <= V1_from_reg;
            V1_to_rs <= V2_from_reg;
            Q1_to_rs <= Q1_from_reg;
            Q2_to_rs <= Q2_from_reg;
            imm_to_rs <= imm_from_dcd;
        end
   end    

end    

endmodule