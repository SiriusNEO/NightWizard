`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"
`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu1/src/pub_unit/Matcher.v"

module RS (
    input wire clk,
    input wire rst,
    input wire rdy,

    // from dsp
    input wire ena_from_dsp,
    input wire [`OPENUM_TYPE] openum_from_dsp,
    input wire [`DATA_TYPE] V1_from_dsp,
    input wire [`DATA_TYPE] V2_from_dsp,
    input wire [`ROB_ID_TYPE] Q1_from_dsp,
    input wire [`ROB_ID_TYPE] Q2_from_dsp,
    input wire [`ADDR_TYPE] pc_from_dsp,
    input wire [`DATA_TYPE] imm_from_dsp,
    input wire [`ROB_ID_TYPE] rob_id_from_dsp,
    // to dsp

    output wire full_to_if,

    // to ex1
    output reg [`OPENUM_TYPE] openum_to_ex1,
    output reg [`DATA_TYPE] V1_to_ex1,
    output reg [`DATA_TYPE] V2_to_ex1,
    output reg [`DATA_TYPE] pc_to_ex1,
    output reg [`DATA_TYPE] imm_to_ex1,

    // to ex2
    output reg [`OPENUM_TYPE] openum_to_ex2,
    output reg [`DATA_TYPE] V1_to_ex2,
    output reg [`DATA_TYPE] V2_to_ex2,
    output reg [`DATA_TYPE] pc_to_ex2,
    output reg [`DATA_TYPE] imm_to_ex2,

    // to cdb
    output reg [`ROB_ID_TYPE] rob_id_to_cdb1,
    output reg [`ROB_ID_TYPE] rob_id_to_cdb2,

    // from rs cdb
    input wire valid_from_rs_cdb1,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb1,
    input wire [`DATA_TYPE] result_from_rs_cdb1,

    input wire valid_from_rs_cdb2,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb2,
    input wire [`DATA_TYPE] result_from_rs_cdb2,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_cdb,
    input wire [`DATA_TYPE] result_from_ls_cdb,

    // jump_flag
    input wire rollback_flag_from_rob
);

// rs store
// RS Node: busy, pc, openum, V1, V2, Q1, Q2, ROB_id
// RS[0] left for invalid
reg [`RS_SIZE - 1 : 0] busy;
reg [`ADDR_TYPE] pc [`RS_SIZE - 1 : 0]; 
reg [`OPENUM_TYPE] openum [`RS_SIZE - 1 : 0];
reg [`DATA_TYPE] imm [`RS_SIZE - 1 : 0];
reg [`DATA_TYPE] V1 [`RS_SIZE - 1 : 0];
reg [`DATA_TYPE] V2 [`RS_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q1 [`RS_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q2 [`RS_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] rob_id [`RS_SIZE - 1 : 0];

// index
integer i;
wire [`RS_ID_TYPE] free_index;
reg [`RS_ID_TYPE] exec_index1, exec_index2;

// signal
wire full_signal = (free_index == `INVALID_RS);

assign full_to_if = full_signal;

// debug
integer dbg_update_index_from_rs = -1;
integer dbg_update_result = -1;

integer dbg_insert_openum = -1;
integer dbg_insert_Q1 = -1;
integer dbg_insert_Q2 = -1;
integer dbg_insert_V1 = -1;
integer dbg_insert_V2 = -1;

// update immediately by cdb

wire Q1_match, Q2_match;
wire [`DATA_TYPE] Q1_matched_V, Q2_matched_V;

Matcher Q1_matcher (
    .Q(Q1_from_dsp),

    .valid1(valid_from_rs_cdb1),
    .rob_id1(rob_id_from_rs_cdb1),
    .value1(result_from_rs_cdb1),
    
    .valid2(valid_from_rs_cdb2),
    .rob_id2(rob_id_from_rs_cdb2),
    .value2(result_from_rs_cdb2),
    
    .valid3(valid_from_ls_cdb),
    .rob_id3(rob_id_from_ls_cdb),
    .value3(result_from_ls_cdb),

    .match(Q1_match),
    .matched_V(Q1_matched_V)
);

Matcher Q2_matcher (
    .Q(Q2_from_dsp),

    .valid1(valid_from_rs_cdb1),
    .rob_id1(rob_id_from_rs_cdb1),
    .value1(result_from_rs_cdb1),
    
    .valid2(valid_from_rs_cdb2),
    .rob_id2(rob_id_from_rs_cdb2),
    .value2(result_from_rs_cdb2),
    
    .valid3(valid_from_ls_cdb),
    .rob_id3(rob_id_from_ls_cdb),
    .value3(result_from_ls_cdb),

    .match(Q2_match),
    .matched_V(Q2_matched_V)
);

wire [`ROB_ID_TYPE] real_Q1 = (Q1_match ? `ZERO_ROB : Q1_from_dsp);
wire [`ROB_ID_TYPE] real_Q2 = (Q2_match ? `ZERO_ROB : Q2_from_dsp);
wire [`DATA_TYPE] real_V1 = (Q1_match ? Q1_matched_V : V1_from_dsp);
wire [`DATA_TYPE] real_V2 = (Q2_match ? Q2_matched_V : V2_from_dsp);

assign free_index = ~busy[0] ? 0 :
                    (~busy[1] ? 1 :
                    (~busy[2] ? 2 :
                    (~busy[3] ? 3 :
                    (~busy[4] ? 4 :
                    (~busy[5] ? 5 :
                    (~busy[6] ? 6 :
                    (~busy[7] ? 7 :
                    (~busy[8] ? 8 :
                    (~busy[9] ? 9 :
                    (~busy[10] ? 10 :
                    (~busy[11] ? 11 :
                    (~busy[12] ? 12 :
                    (~busy[13] ? 13 :
                    (~busy[14] ? 14 :
                    (~busy[15] ? 15 :
                    `INVALID_RS)))))))))))))));

always @(*) begin
    exec_index1 = `INVALID_RS;
    exec_index2 = `INVALID_RS;
    for (i = 0; i < `RS_SIZE; i=i+1) begin
        if (busy[i] && Q1[i] == `ZERO_ROB && Q2[i] == `ZERO_ROB) begin
            if (exec_index1 == `INVALID_RS) exec_index1 = i;
            else if (exec_index2 == `INVALID_RS) exec_index2 = i;
        end
    end
end             

always @(posedge clk) begin
    if (rst || rollback_flag_from_rob) begin
        openum_to_ex1 <= `OPENUM_NOP;
        openum_to_ex2 <= `OPENUM_NOP;

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
    else if (~rdy) begin
    end
    else begin
        // exec
        // dual exec, first issue to ex1 then ex2 (if there is)

        openum_to_ex1 <= `OPENUM_NOP;
        if (exec_index1 != `INVALID_RS) begin
            busy[exec_index1] <= `FALSE; 
            openum_to_ex1 <= openum[exec_index1];
            V1_to_ex1 <= V1[exec_index1];
            V2_to_ex1 <= V2[exec_index1];
            pc_to_ex1 <= pc[exec_index1];
            imm_to_ex1 <= imm[exec_index1];
            // cdb
            rob_id_to_cdb1 <= rob_id[exec_index1];
        end
        
        openum_to_ex2 <= `OPENUM_NOP;
        if (exec_index2 != `INVALID_RS) begin
            busy[exec_index2] <= `FALSE; 
            openum_to_ex2 <= openum[exec_index2];
            V1_to_ex2 <= V1[exec_index2];
            V2_to_ex2 <= V2[exec_index2];
            pc_to_ex2 <= pc[exec_index2];
            imm_to_ex2 <= imm[exec_index2];
            // cdb
            rob_id_to_cdb2 <= rob_id[exec_index2];
        end

        // update
        if (valid_from_rs_cdb1 == `TRUE) begin
            for (i = 0; i < `RS_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_rs_cdb1) begin
                    V1[i] <= result_from_rs_cdb1;
                    Q1[i] <= `ZERO_ROB;
                end
                if (Q2[i] == rob_id_from_rs_cdb1) begin
                    V2[i] <= result_from_rs_cdb1;
                    Q2[i] <= `ZERO_ROB;
                end
            end
        end
        if (valid_from_rs_cdb2 == `TRUE) begin
            for (i = 0; i < `RS_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_rs_cdb2) begin
                    V1[i] <= result_from_rs_cdb2;
                    Q1[i] <= `ZERO_ROB;
                end
                if (Q2[i] == rob_id_from_rs_cdb2) begin
                    V2[i] <= result_from_rs_cdb2;
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

        if (ena_from_dsp == `TRUE && free_index != `INVALID_RS) begin
            // insert to rs
            busy[free_index]  <= `TRUE;
            openum[free_index] <= openum_from_dsp;  
            Q1[free_index] <= real_Q1;
            Q2[free_index] <= real_Q2;
            V1[free_index] <= real_V1;
            V2[free_index] <= real_V2;
            pc[free_index] <= pc_from_dsp;
            imm[free_index] <= imm_from_dsp;
            rob_id[free_index] <= rob_id_from_dsp;
`ifdef DEBUG
            dbg_insert_Q1 <= real_Q1;
            dbg_insert_Q2 <= real_Q2;
            dbg_insert_V1 <= real_V1;
            dbg_insert_V2 <= real_V2;
                
`endif
        end
    end        
end    

endmodule