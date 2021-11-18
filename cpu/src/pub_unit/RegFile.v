`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RegFile (
    input wire clk,
    input wire rst,

    // call-back
    // from dsp
    input wire [`REG_POS_TYPE] rs1_from_dsp,
    input wire [`REG_POS_TYPE] rs2_from_dsp,
    // to dsp
    output wire [`DATA_TYPE] V1_to_dsp,
    output wire [`DATA_TYPE] V2_to_dsp,
    output wire [`ROB_ID_TYPE] Q1_to_dsp,
    output wire [`ROB_ID_TYPE] Q2_to_dsp,

    // alloc from dsp
    input wire ena_from_dsp,
    input wire [`REG_POS_TYPE] rd_from_dsp,
    input wire [`ROB_ID_TYPE] Q_from_dsp,

    // commit from rob
    input wire commit_flag_from_rob,
    input wire commit_jump_flag_from_rob,
    input wire [`REG_POS_TYPE] rd_from_rob,
    input wire [`ROB_ID_TYPE] Q_from_rob,
    input wire [`DATA_TYPE] V_from_rob
);

// reg store
reg [`ROB_ID_TYPE] Q [`REG_SIZE - 1 : 0];
reg [`DATA_TYPE] V [`REG_SIZE - 1 : 0];

// index
integer i;

// debug
integer dbg_cmupd_index = -1;
integer dbg_cmupd_Q = -1;
integer dbg_cmupd_V = -1;

// shadow reg
reg ena_shadow_Q [`REG_SIZE - 1 : 0];
reg ena_shadow_V [`REG_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] shadow_Q [`REG_SIZE - 1 : 0];
reg [`DATA_TYPE] shadow_V [`REG_SIZE - 1 : 0];

assign Q1_to_dsp = ena_shadow_Q[rs1_from_dsp] ? shadow_Q[rs1_from_dsp] : Q[rs1_from_dsp];
assign Q2_to_dsp = ena_shadow_Q[rs2_from_dsp] ? shadow_Q[rs2_from_dsp] : Q[rs2_from_dsp];
assign V1_to_dsp = ena_shadow_V[rs1_from_dsp] ? shadow_V[rs1_from_dsp] : V[rs1_from_dsp];
assign V2_to_dsp = ena_shadow_V[rs2_from_dsp] ? shadow_V[rs2_from_dsp] : V[rs2_from_dsp];

always @(*) begin
    for (i = 0; i < `REG_SIZE; i=i+1) begin
            ena_shadow_Q[i] = `FALSE;
            ena_shadow_V[i] = `FALSE;
            shadow_Q[i] = `ZERO_ROB;
            shadow_V[i] = `ZERO_WORD;
    end
    
    if (commit_jump_flag_from_rob == `TRUE) begin
        for (i = 0; i < `REG_SIZE; i=i+1) begin
            shadow_Q[i] = `ZERO_ROB;
            ena_shadow_Q[i] = `TRUE;
        end
    end
    else if (ena_from_dsp == `TRUE) begin
        if (rd_from_dsp != `ZERO_REG) begin
            shadow_Q[rd_from_dsp] = Q_from_dsp;
            ena_shadow_Q[rd_from_dsp] = `TRUE;
        end
    end

    // update when commit
    if (commit_flag_from_rob == `TRUE) begin
        // zero reg is immutable
        if (rd_from_rob != `ZERO_REG) begin
            shadow_V[rd_from_rob] = V_from_rob;
            ena_shadow_V[rd_from_rob] = `TRUE;
            if ((ena_shadow_Q[rd_from_rob] ? shadow_Q[rd_from_rob] : Q[rd_from_rob]) == Q_from_rob) begin
                shadow_Q[rd_from_rob] = `ZERO_ROB;
                ena_shadow_Q[rd_from_rob] = `TRUE;
            end
        end
    end
end   

always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < `REG_SIZE; i=i+1) begin
            Q[i] <= `ZERO_ROB;
            V[i] <= `ZERO_WORD;
        end
    end
    else begin
        for (i = 0; i < `REG_SIZE; i=i+1) begin
            if (ena_shadow_Q[i]) Q[i] <= shadow_Q[i];
            if (ena_shadow_V[i]) V[i] <= shadow_V[i];
        end
    end
end   

endmodule