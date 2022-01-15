`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

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
    input wire rollback_flag_from_rob,
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
integer dbg_cmupd_rd = -1;
integer dbg_cmupd_Q = -1;
integer dbg_cmupd_V = -1;

// shadow
reg shadow_jump_flag_from_rob, shadow_commit_Q_elim; 
reg [`ROB_ID_TYPE] shadow_Q_from_dsp;
reg [`REG_POS_TYPE] shadow_rd_from_dsp, shadow_rd_from_rob;
reg [`DATA_TYPE] shadow_V_from_rob;

assign Q1_to_dsp = (shadow_rd_from_rob == rs1_from_dsp && shadow_commit_Q_elim) ? `ZERO_ROB : 
                   (shadow_rd_from_dsp == rs1_from_dsp ? shadow_Q_from_dsp : 
                   (shadow_jump_flag_from_rob ? `ZERO_ROB : Q[rs1_from_dsp]));
assign Q2_to_dsp = (shadow_rd_from_rob == rs2_from_dsp && shadow_commit_Q_elim) ? `ZERO_ROB : 
                   (shadow_rd_from_dsp == rs2_from_dsp ? shadow_Q_from_dsp : 
                   (shadow_jump_flag_from_rob ? `ZERO_ROB : Q[rs2_from_dsp]));
assign V1_to_dsp = (shadow_rd_from_rob == rs1_from_dsp) ? shadow_V_from_rob : V[rs1_from_dsp];
assign V2_to_dsp = (shadow_rd_from_rob == rs2_from_dsp) ? shadow_V_from_rob : V[rs2_from_dsp];

always @(*) begin
    shadow_jump_flag_from_rob = `FALSE;

    shadow_rd_from_dsp = `ZERO_REG;
    shadow_Q_from_dsp = `ZERO_ROB;

    shadow_rd_from_rob = `ZERO_REG;
    shadow_commit_Q_elim = `FALSE;
    shadow_V_from_rob = `ZERO_WORD;
    
    if (rollback_flag_from_rob) begin
        shadow_jump_flag_from_rob = `TRUE;
    end
    else if (ena_from_dsp == `TRUE && rd_from_dsp != `ZERO_REG) begin
        shadow_rd_from_dsp = rd_from_dsp;
        shadow_Q_from_dsp = Q_from_dsp;
    end

    if (commit_flag_from_rob) begin
        if (rd_from_rob != `ZERO_REG) begin
            shadow_rd_from_rob = rd_from_rob; 
            shadow_V_from_rob = V_from_rob;
            if (ena_from_dsp && (rd_from_rob == rd_from_dsp)) begin
                if (shadow_Q_from_dsp == Q_from_rob) shadow_commit_Q_elim = `TRUE;
            end
            else if (Q[rd_from_rob] == Q_from_rob) shadow_commit_Q_elim = `TRUE;
        end
`ifdef DEBUG
        dbg_cmupd_V = V_from_rob;
        dbg_cmupd_Q = Q_from_rob;
        dbg_cmupd_rd = rd_from_rob;
`endif
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
        if (shadow_jump_flag_from_rob) begin
            for (i = 0; i < `REG_SIZE; i=i+1) begin
                Q[i] <= `ZERO_ROB;
            end
        end
        else if (shadow_rd_from_dsp != `ZERO_REG) begin
            Q[shadow_rd_from_dsp] <= shadow_Q_from_dsp;
        end

        if (shadow_rd_from_rob != `ZERO_REG) begin
            V[shadow_rd_from_rob] <= shadow_V_from_rob;
            if (shadow_commit_Q_elim) Q[shadow_rd_from_rob] <= `ZERO_ROB;
        end
    end
end   

endmodule