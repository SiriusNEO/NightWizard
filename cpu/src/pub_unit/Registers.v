`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Registers (
    input wire clk,
    input wire rst,

    // from dsp
    input wire [`REG_LEN - 1 : 0] rs1_from_dsp,
    input wire [`REG_LEN - 1 : 0] rs2_from_dsp,

    // to dsp
    output reg [`DATA_LEN - 1 : 0] V1_to_dsp,
    output reg [`DATA_LEN - 1 : 0] V2_to_dsp,
    output reg [`ROB_LEN - 1 : 0] Q1_to_dsp,
    output reg [`ROB_LEN - 1 : 0] Q2_to_dsp,

    // to ROB
    output reg [`ROB_LEN - 1 : 0] Q1_to_rob,
    output reg [`ROB_LEN - 1 : 0] Q2_to_rob,
    
    // from ROB
    input wire Q1_ready_from_rob,
    input wire Q2_ready_from_rob
);

// reg store
reg [`ROB_LEN - 1 : 0] Q;
reg [`DATA_LEN - 1 : 0] V;

always @(posedge clk, posedge rst) begin
    
    // get rob ready
    Q1_to_rob = Q[rs1_from_dsp];
    Q2_to_rob = Q[rs2_from_dsp];

    // dsp get reg v
    if (Q[rs1_from_dsp] == `ZERO_ROB) begin
        V1_to_dsp = V[rs1_from_dsp];
    end else begin
        if (Q1_ready_from_rob == `TRUE) begin
            V1_to_dsp = V[rs1_from_dsp];
        end    
    end

    if (Q[rs2_from_dsp] == `ZERO_ROB) begin
        V2_to_dsp = V[rs2_from_dsp];
    end else begin
        if (Q2_ready_from_rob == `TRUE) begin
            V2_to_dsp = V[rs2_from_dsp];
        end    
    end       
end    

endmodule