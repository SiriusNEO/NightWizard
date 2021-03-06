`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module ReOrderBuffer (
    input wire clk,
    input wire rst,
    input wire rdy,

    // reply to dsp_ready query
    // from dsp
    input wire [`ROB_ID_TYPE] Q1_from_dsp,
    input wire [`ROB_ID_TYPE] Q2_from_dsp,
    // to dsp
    output wire Q1_ready_to_dsp,
    output wire Q2_ready_to_dsp,
    output wire [`DATA_TYPE] ready_data1_to_dsp,
    output wire [`DATA_TYPE] ready_data2_to_dsp,

    // dsp allocate to rob
    // from dsp
    input wire ena_from_dsp,
    input wire [`REG_POS_TYPE] rd_from_dsp,
    // to dsp
    output wire [`ROB_ID_TYPE] rob_id_to_dsp,

    // to if
    output wire full_to_if,

    // update rob by cdb
    // from cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb,
    input wire [`DATA_TYPE] result_from_rs_cdb,
    input wire [`ADDR_TYPE] target_pc_from_rs_cdb,
    input wire jump_flag_from_rs_cdb,

    input wire valid_from_ls_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_cdb,
    input wire [`DATA_TYPE] result_from_ls_cdb,
    
    // from lsb
    input wire [`ROB_ID_TYPE] store_rob_id_from_lsb,

    // commit
    output reg commit_flag,
    // to reg
    output reg [`REG_POS_TYPE] rd_to_reg,
    output reg [`ROB_ID_TYPE] Q_to_reg,
    output reg [`DATA_TYPE] V_to_reg,
    // to if
    output reg rollback_flag,
    output reg [`ADDR_TYPE] target_pc_to_if,
    // to lsb
    output reg [`ROB_ID_TYPE] rob_id_to_lsb
);

// rob queue
// Q & rob_id hint:
// Q = index + 1, Q = 0: empty
// Q->index, -1 & check Q==`ZERO_ROB; index->Q, +1

// head = tail empty
// head = next_tail full
reg [`ROB_POS_TYPE] head, tail; 
wire [`ROB_POS_TYPE] next_head = (head == `ROB_SIZE - 1) ? 0 : head + 1,
                     next_tail = (tail == `ROB_SIZE - 1) ? 0 : tail + 1;

reg [`ROB_POS_TYPE] rob_element_cnt;
wire full_signal = (rob_element_cnt > (`ROB_SIZE >> 1));

assign full_to_if = full_signal;

reg busy [`ROB_SIZE - 1 : 0];
reg ready [`ROB_SIZE - 1 : 0];
reg [`REG_POS_TYPE] rd [`ROB_SIZE - 1 : 0];
reg [`DATA_TYPE] data [`ROB_SIZE - 1 : 0];
reg [`ADDR_TYPE] target_pc [`ROB_SIZE - 1 : 0];
reg jump_flag [`ROB_SIZE - 1 : 0];

// index
integer i;

// debug
integer dbg_update_from_rs = -1;
integer dbg_update_result_from_rs = -1;
integer dbg_update_from_rs_jump_flag = -1;

integer dbg_update_from_lsb = -1;
integer dbg_store_commit_request = -1;

integer dbg_commit = -1;
integer dbg_rollback_flag = -1;
integer dbg_commit_target_pc = -1;

integer dbg_insert_rd = -1;
integer dbg_insert_from_dsp = -1;

assign Q1_ready_to_dsp = (Q1_from_dsp == `ZERO_ROB) ? `FALSE : (ready[Q1_from_dsp - 1]);
assign Q2_ready_to_dsp = (Q2_from_dsp == `ZERO_ROB) ? `FALSE : (ready[Q2_from_dsp - 1]);
assign ready_data1_to_dsp = (Q1_from_dsp == `ZERO_ROB) ?  `ZERO_WORD : data[Q1_from_dsp - 1];
assign ready_data2_to_dsp = (Q2_from_dsp == `ZERO_ROB) ?  `ZERO_WORD : data[Q2_from_dsp - 1];

assign rob_id_to_dsp = tail + 1;

always @(posedge clk) begin
    if (rst  || rollback_flag ) begin
        rob_element_cnt <= `ZERO_ROB;
        head <= `ZERO_ROB;
        tail <= `ZERO_ROB;
        for (i = 0; i < `ROB_SIZE; i=i+1) begin
            busy[i] <= `FALSE;
            ready[i] <= `FALSE;
            rd[i] <= `ZERO_REG;
            data[i] <= `ZERO_WORD;
            target_pc[i] <= `ZERO_ADDR;
            jump_flag[i] <= `FALSE;
        end
        commit_flag <= `FALSE;
        rollback_flag <= `FALSE;
    end 
    else if (~rdy) begin
    end
    else begin
        // commit
        if (busy[head]  && ready[head] ) begin
            // commit to regfile
            commit_flag <= `TRUE;
            rd_to_reg <= rd[head];
            Q_to_reg <= head + 1;
            V_to_reg <= data[head];
            rob_id_to_lsb <= head + 1;
            if (jump_flag[head] ) begin
                rollback_flag <= `TRUE;
                target_pc_to_if <= target_pc[head];
            end
            else begin
                rollback_flag <= `FALSE;
            end
            busy[head] <= `FALSE;
            ready[head] <= `FALSE;
            head <= next_head;
            rob_element_cnt <= rob_element_cnt - 1;
`ifdef DEBUG
            dbg_commit <= head + 1;
            dbg_rollback_flag <= jump_flag[head];
            dbg_commit_target_pc <= target_pc[head];
`endif
        end
        else begin
            commit_flag <= `FALSE;
        end

        // update
        if (busy[rob_id_from_rs_cdb - 1]  && valid_from_rs_cdb ) begin
            ready[rob_id_from_rs_cdb - 1] <= `TRUE;
            data[rob_id_from_rs_cdb - 1] <= result_from_rs_cdb;
            target_pc[rob_id_from_rs_cdb - 1] <= target_pc_from_rs_cdb;
            jump_flag[rob_id_from_rs_cdb - 1] <= jump_flag_from_rs_cdb;
`ifdef DEBUG
            dbg_update_from_rs <= rob_id_from_rs_cdb;
            dbg_update_result_from_rs <= result_from_rs_cdb;
            dbg_update_from_rs_jump_flag <= jump_flag_from_rs_cdb;
`endif
        end
        
        // store commit directly
        if (busy[store_rob_id_from_lsb - 1]  && store_rob_id_from_lsb != `ZERO_ROB) begin
            ready[store_rob_id_from_lsb - 1] <= `TRUE;
`ifdef DEBUG
            dbg_store_commit_request <= store_rob_id_from_lsb;
`endif
        end

        if (busy[rob_id_from_ls_cdb - 1]  && valid_from_ls_cdb ) begin
            ready[rob_id_from_ls_cdb - 1] <= `TRUE; 
            data[rob_id_from_ls_cdb - 1] <= result_from_ls_cdb;
`ifdef DEBUG
            dbg_update_from_lsb <= rob_id_from_ls_cdb;
`endif
        end

        if (ena_from_dsp) begin
            // insert
            rob_element_cnt <= rob_element_cnt + 1;
            busy[tail] <= `TRUE;
            rd[tail] <= rd_from_dsp;
            data[tail] <= `ZERO_WORD;
            target_pc[tail] <= `ZERO_ADDR;
            ready[tail] <= `FALSE;
            jump_flag[tail] <= `FALSE;
            tail <= next_tail;
`ifdef DEBUG
            dbg_insert_rd <= rd[tail];
            dbg_insert_from_dsp <= tail;
`endif   
        end
    end 
end

endmodule