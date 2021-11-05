`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RS (
    input wire clk,
    input wire rst,

    // from dsp
    input wire ena_from_dsp,
    input wire [`OPENUM_LEN - 1 : 0] openum_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V1_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V2_from_dsp,
    input wire [`ROB_LEN : 0] Q1_from_dsp,
    input wire [`ROB_LEN : 0] Q2_from_dsp,
    input wire [`ADDR_LEN - 1 : 0] pc_from_dsp,
    input wire [`DATA_LEN - 1 : 0] imm_from_dsp,
    input wire [`ROB_LEN : 0] rob_id_from_dsp,
    // to dsp

    output wire full_to_if,

    // to ex
    output reg [`OPENUM_LEN - 1 : 0] openum_to_ex,
    output reg [`DATA_LEN - 1 : 0] V1_to_ex,
    output reg [`DATA_LEN - 1 : 0] V2_to_ex,
    output reg [`DATA_LEN - 1 : 0] pc_to_ex,
    output reg [`DATA_LEN - 1 : 0] imm_to_ex,

    // to cdb
    output reg [`ROB_LEN : 0] rob_id_to_cdb,

    // from rs cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_rs_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_rs_cdb,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_ls_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_ls_cdb,

    // jump_flag
    input wire commit_jump_flag_from_rob
);

// rs store
// RS Node: busy, pc, openum, V1, V2, Q1, Q2, ROB_id
// RS[0] left for invalid
reg busy [`RS_SIZE - 1 : 0];
reg [`ADDR_LEN - 1 : 0] pc [`RS_SIZE - 1 : 0]; 
reg [`OPENUM_LEN - 1 : 0] openum [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] imm [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V1 [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V2 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN : 0] Q1 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN : 0] Q2 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN : 0] rob_id [`RS_SIZE - 1 : 0];

// index
integer i;
integer free_index;
integer exec_index;

// signal
wire full_signal = (free_index == -1);

assign full_to_if = full_signal;

always @(*) begin
    free_index = -1;
    exec_index = -1;

    for (i = `RS_SIZE - 1; free_index < 0 && i >= 0; i=i-1) begin
        if (busy[i] == `FALSE) 
            free_index = i;
    end 

    for (i = `RS_SIZE - 1; exec_index < 0 && i >= 0; i=i-1) begin
        if (busy[i] == `TRUE && Q1[i] == `ZERO_ROB && Q2[i] == `ZERO_ROB) 
            exec_index = i;
    end 
end

always @(posedge clk) begin
    if (rst == `TRUE || commit_jump_flag_from_rob == `TRUE) begin
        for (i = 0; i < `RS_SIZE; i=i+1) begin
            busy[i] <= `FALSE;
            pc[i] <= `ZERO_ADDR;
            openum[i] <= `OPENUM_NOP;
            imm[i] <= `ZERO_WORD;
            V1[i] <= `ZERO_WORD;
            V2[i] <= `ZERO_WORD;
            Q1[i] <= `ZERO_ROB;
            Q2[i] <= `ZERO_ROB;
            rob_id[i] <= `ZERO_ROB;
        end
    end 
    else begin
        // exec
        if (exec_index == -1) begin
            openum_to_ex <= `OPENUM_NOP;
        end
        else begin
            busy[exec_index] <= `FALSE; 
            openum_to_ex <= openum[exec_index];
            V1_to_ex <= V1[exec_index];
            V2_to_ex <= V2[exec_index];
            pc_to_ex <= pc[exec_index];
            imm_to_ex <= imm[exec_index];
            // cdb
            rob_id_to_cdb <= rob_id[exec_index];
        end

        // update
        if (valid_from_rs_cdb == `TRUE) begin
            for (i = 0; i < `RS_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_rs_cdb) begin
                    V1[i] <= result_from_rs_cdb;
                    Q1[i] <= `ZERO_ROB;
                end
                if (Q2[i] == rob_id_from_rs_cdb) begin
                    V2[i] <= result_from_rs_cdb;
                    Q2[i] <= `ZERO_ROB;
                end
            end
        end
        if (valid_from_ls_cdb == `TRUE) begin
            for (i = 0; i < `RS_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_ls_cdb) begin
                    V1[i] <= result_from_ls_cdb;
                    Q1[i] <= `ZERO_ROB;
                end
                if (Q2[i] == rob_id_from_ls_cdb) begin
                    V2[i] <= result_from_ls_cdb;
                    Q2[i] <= `ZERO_ROB;
                end
            end
        end

        if (ena_from_dsp == `TRUE) begin
            // insert to rs - no full
            if (full_signal == `FALSE) begin
                busy[free_index]  <= `TRUE;
                openum[free_index] <= openum_from_dsp;
                V1[free_index] <= V1_from_dsp;
                V2[free_index] <= V2_from_dsp;
                Q1[free_index] <= Q1_from_dsp;
                Q2[free_index] <= Q2_from_dsp;
                pc[free_index] <= pc_from_dsp;
                imm[free_index] <= imm_from_dsp;
                rob_id[free_index] <= rob_id_from_dsp;
            end
`ifdef DEBUG
/*
                $display("rs insert... openum:", openum_from_dsp);
                $display("rs Q1: ", Q1[0], Q1[1], Q1[2], Q1[3], Q1[4], Q1[5], Q1[6], Q1[7], Q1[8], Q1[9], Q1[10], Q1[11], Q1[12], Q1[13], Q1[14], Q1[15]);
                $display("rs V1: ", V1[0], V1[1], V1[2], V1[3], V1[4], V1[5], V1[6], V1[7], V1[8], V1[9], V1[10], V1[11], V1[12], V1[13], V1[14], V1[15]);
                $display("rs Q2: ", Q2[0], Q2[1], Q2[2], Q2[3], Q2[4], Q2[5], Q2[6], Q2[7], Q2[8], Q2[9], Q2[10], Q2[11], Q2[12], Q2[13], Q2[14], Q2[15]);
                $display("rs V2: ", V2[0], V2[1], V2[2], V2[3], V2[4], V2[5], V2[6], V2[7], V2[8], V2[9], V2[10], V2[11], V2[12], V2[13], V2[14], V2[15]);
*/
`endif
        end
    end        
end    

endmodule