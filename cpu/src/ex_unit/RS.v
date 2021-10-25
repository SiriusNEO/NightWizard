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
    output reg full_to_if,

    // to ex
    output reg [`OPENUM_LEN - 1 : 0] openum_to_ex,
    output reg [`DATA_LEN - 1 : 0] V1_to_ex,
    output reg [`DATA_LEN - 1 : 0] V2_to_ex,
    output reg [`DATA_LEN - 1 : 0] pc_to_ex,
    output reg [`DATA_LEN - 1 : 0] imm_to_ex,

    // to cdb
    output reg [`ROB_LEN : 0] rob_id_to_cdb
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
reg [`ROB_LEN - 1 : 0] Q1 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q2 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] rob_id [`RS_SIZE - 1 : 0];

// index
integer i;
integer free_index;
integer issue_index;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        for (i = 0; i < `RS_SIZE; i++) begin
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
        free_index = -1;
        issue_index = -1;

        for (i = `RS_SIZE - 1; free_index < 0 && i >= 0; i--) begin
            if (busy[i] == `FALSE) free_index = i;
        end    

        full_to_if = (free_index == -1); 

        for (i = `RS_SIZE - 1; issue_index < 0 && i >= 0; i--) begin
            if (busy[i] == `TRUE && Q1[i] == `ZERO_ROB && Q2[i] == `ZERO_ROB) 
                issue_index = i;
        end     
        
        // exec
        openum_to_ex = openum[issue_index];
        V1_to_ex = V1[issue_index];
        V2_to_ex = V2[issue_index];
        pc_to_ex = pc[issue_index];
        imm_to_ex = imm[issue_index];

        rob_id_to_cdb = rob_id[issue_index];

        if (ena_from_dsp == `TRUE) begin
            // insert to rs - no full
            if (full_to_if == `FALSE) begin
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
        end
    end        
end    

endmodule