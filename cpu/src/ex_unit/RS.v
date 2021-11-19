`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

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

    // to ex
    output reg [`OPENUM_TYPE] openum_to_ex,
    output reg [`DATA_TYPE] V1_to_ex,
    output reg [`DATA_TYPE] V2_to_ex,
    output reg [`DATA_TYPE] pc_to_ex,
    output reg [`DATA_TYPE] imm_to_ex,

    // to cdb
    output reg [`ROB_ID_TYPE] rob_id_to_cdb,

    // from rs cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb,
    input wire [`DATA_TYPE] result_from_rs_cdb,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_cdb,
    input wire [`DATA_TYPE] result_from_ls_cdb,

    // jump_flag
    input wire commit_jump_flag_from_rob
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
wire [`RS_ID_TYPE] exec_index;

// signal
wire full_signal = (free_index == -1);

assign full_to_if = full_signal;

// debug
integer dbg_update_index_from_rs = -1;
integer dbg_update_result = -1;

integer dbg_insert_openum = -1;
integer dbg_insert_Q1 = -1;
integer dbg_insert_Q2 = -1;
integer dbg_insert_V1 = -1;
integer dbg_insert_V2 = -1;

wire [`ROB_ID_TYPE] real_Q1 = (valid_from_rs_cdb && Q1_from_dsp == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q1_from_dsp == rob_id_from_ls_cdb) ? `ZERO_ROB : Q1_from_dsp);
wire [`ROB_ID_TYPE] real_Q2 = (valid_from_rs_cdb && Q2_from_dsp == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q2_from_dsp == rob_id_from_ls_cdb) ? `ZERO_ROB : Q2_from_dsp);
wire [`DATA_TYPE] real_V1 = (valid_from_rs_cdb && Q1_from_dsp == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q1_from_dsp == rob_id_from_ls_cdb) ? result_from_ls_cdb : V1_from_dsp);
wire [`DATA_TYPE] real_V2 = (valid_from_rs_cdb && Q2_from_dsp == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q2_from_dsp == rob_id_from_ls_cdb) ? result_from_ls_cdb : V2_from_dsp);

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

assign exec_index = (busy[0] && Q1[0] == `ZERO_ROB && Q2[0] == `ZERO_ROB) ? 0 :
                    ((busy[1] && Q1[1] == `ZERO_ROB && Q2[1] == `ZERO_ROB) ? 1 :
                    ((busy[2] && Q1[2] == `ZERO_ROB && Q2[2] == `ZERO_ROB) ? 2 :
                    ((busy[3] && Q1[3] == `ZERO_ROB && Q2[3] == `ZERO_ROB) ? 3 :
                    ((busy[4] && Q1[4] == `ZERO_ROB && Q2[4] == `ZERO_ROB) ? 4 :
                    ((busy[5] && Q1[5] == `ZERO_ROB && Q2[5] == `ZERO_ROB) ? 5 :
                    ((busy[6] && Q1[6] == `ZERO_ROB && Q2[6] == `ZERO_ROB) ? 6 :
                    ((busy[7] && Q1[7] == `ZERO_ROB && Q2[7] == `ZERO_ROB) ? 7 :
                    ((busy[8] && Q1[8] == `ZERO_ROB && Q2[8] == `ZERO_ROB) ? 8 :
                    ((busy[9] && Q1[9] == `ZERO_ROB && Q2[9] == `ZERO_ROB) ? 9 :
                    ((busy[10] && Q1[10] == `ZERO_ROB && Q2[10] == `ZERO_ROB) ? 10 :
                    ((busy[11] && Q1[11] == `ZERO_ROB && Q2[11] == `ZERO_ROB) ? 11 :
                    ((busy[12] && Q1[12] == `ZERO_ROB && Q2[12] == `ZERO_ROB) ? 12 :
                    ((busy[13] && Q1[13] == `ZERO_ROB && Q2[13] == `ZERO_ROB) ? 13 :
                    ((busy[14] && Q1[14] == `ZERO_ROB && Q2[14] == `ZERO_ROB) ? 14 :
                    ((busy[15] && Q1[15] == `ZERO_ROB && Q2[15] == `ZERO_ROB) ? 15 :
                    `INVALID_RS)))))))))))))));               

always @(posedge clk) begin
    if (rst || commit_jump_flag_from_rob) begin
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
        if (exec_index == `INVALID_RS) begin
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
`ifdef DEBUG
                dbg_update_index_from_rs <= i;
                dbg_update_result <= result_from_rs_cdb;
`endif
                end
                if (Q2[i] == rob_id_from_rs_cdb) begin
                    V2[i] <= result_from_rs_cdb;
                    Q2[i] <= `ZERO_ROB;
`ifdef DEBUG
                dbg_update_index_from_rs <= i;
                dbg_update_result <= result_from_rs_cdb;
`endif
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