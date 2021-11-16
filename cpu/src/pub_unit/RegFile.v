`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RegFile (
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

assign Q1_to_dsp = Q[rs1_from_dsp];
assign Q2_to_dsp = Q[rs2_from_dsp];
assign V1_to_dsp = V[rs1_from_dsp];
assign V2_to_dsp = V[rs2_from_dsp];

// debug
integer dbg_cmupd_index = -1;
integer dbg_cmupd_Q = -1;
integer dbg_cmupd_V = -1;

always @(*) begin
    if (rst == `TRUE) begin
        for (i = 0; i < `REG_SIZE; i=i+1) begin
            Q[i] = `ZERO_ROB;
            V[i] = `ZERO_WORD;
        end
    end
    else if (commit_jump_flag_from_rob == `TRUE) begin
        for (i = 0; i < `REG_SIZE; i=i+1) begin
            Q[i] = `ZERO_ROB;
        end
    end
    else if (ena_from_dsp == `TRUE) begin
        if (rd_from_dsp != `ZERO_REG) begin
            Q[rd_from_dsp] = Q_from_dsp;
        end
    end

    // update when commit
    if (commit_flag_from_rob == `TRUE) begin
        // zero reg is immutable
        if (rd_from_rob != `ZERO_REG) begin
            V[rd_from_rob] = V_from_rob;
            if (Q[rd_from_rob] == Q_from_rob)
                Q[rd_from_rob] = `ZERO_ROB;
        end
`ifdef DEBUG
            dbg_cmupd_index = rd_from_rob;
            dbg_cmupd_Q = Q_from_rob;
            dbg_cmupd_V = V_from_rob;
`endif
    end
end   

endmodule