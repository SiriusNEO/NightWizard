`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module LSBuffer (
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
    input wire [`DATA_TYPE] imm_from_dsp,
    input wire [`ROB_ID_TYPE] rob_id_from_dsp,
    
    // to if
    output wire full_to_if,

    // to ls ex
    output reg ena_to_ex,
    output reg [`OPENUM_TYPE] openum_to_ex,
    output reg [`ADDR_TYPE] mem_addr_to_ex,
    output reg [`DATA_TYPE] store_value_to_ex,
    // to cdb
    output reg [`ROB_ID_TYPE] rob_id_to_cdb,

    // from ls ex
    input wire busy_from_ex,

    // update when commit
    // from rob
    input wire commit_flag_from_rob,
    input wire [`ROB_ID_TYPE] rob_id_from_rob,

    // from rs cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb,
    input wire [`DATA_TYPE] result_from_rs_cdb,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_cdb,
    input wire [`DATA_TYPE] result_from_ls_cdb,

    // to rob: make store commit
    output reg [`ROB_ID_TYPE] store_rob_id_to_rob,

    // jump_flag
    input wire commit_jump_flag_from_rob
);

reg [`LSB_ID_TYPE] head, tail, store_tail;
wire [`LSB_ID_TYPE] next_head = (head == `LSB_SIZE - 1) ? 0 : head + 1, 
next_tail = (tail == `LSB_SIZE - 1) ? 0 : tail + 1;

reg empty_signal;
wire full_signal = (empty_signal == `FALSE) && (head == tail);

assign full_to_if = full_signal;

reg busy [`LSB_SIZE - 1 : 0];
reg [`OPENUM_TYPE] openum [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] imm [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] V1 [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] V2 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q1 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q2 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] rob_id [`LSB_SIZE - 1 : 0];
reg is_committed [`LSB_SIZE - 1 : 0];
// store should wait to be commited

reg store_to_rob_lock; // avoid to send twice

// index
integer i;

wire [`ROB_ID_TYPE] real_Q1 = (valid_from_rs_cdb && Q1_from_dsp == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q1_from_dsp == rob_id_from_ls_cdb) ? `ZERO_ROB : Q1_from_dsp);
wire [`ROB_ID_TYPE] real_Q2 = (valid_from_rs_cdb && Q2_from_dsp == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q2_from_dsp == rob_id_from_ls_cdb) ? `ZERO_ROB : Q2_from_dsp);
wire [`DATA_TYPE] real_V1 = (valid_from_rs_cdb && Q1_from_dsp == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q1_from_dsp == rob_id_from_ls_cdb) ? result_from_ls_cdb : V1_from_dsp);
wire [`DATA_TYPE] real_V2 = (valid_from_rs_cdb && Q2_from_dsp == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q2_from_dsp == rob_id_from_ls_cdb) ? result_from_ls_cdb : V2_from_dsp);

// debug
integer dbg_insert_openum = -1;
integer dbg_insert_Q1 = -1;
integer dbg_insert_Q2 = -1;

integer dbg_update_index_from_rs = -1;
integer dbg_update_result = -1;

always @(posedge clk) begin
    if (rst == `TRUE || (commit_jump_flag_from_rob == `TRUE && store_tail == `INVALID_LSB)) begin
        empty_signal <= `TRUE;
        head <= `ZERO_LSB;
        tail <= `ZERO_LSB;
        store_tail <= `INVALID_LSB;
        for (i = 0; i < `LSB_SIZE; i=i+1) begin
            busy[i] <= `FALSE;
            openum[i] <= `OPENUM_NOP;
            imm[i] <= `ZERO_WORD;
            V1[i] <= `ZERO_WORD;
            V2[i] <= `ZERO_WORD;
            Q1[i] <= `ZERO_ROB;
            Q2[i] <= `ZERO_ROB;
            rob_id[i] <= `ZERO_ROB;
            is_committed[i] <= `FALSE;
        end
        ena_to_ex <= `FALSE;
        store_rob_id_to_rob <= `ZERO_ROB;
        store_to_rob_lock <= `FALSE;
    end
    else if (~rdy) begin
    end
    else if (commit_jump_flag_from_rob == `TRUE) begin
        tail <= (store_tail == `LSB_SIZE - 1) ? 0 : store_tail + 1;
        store_rob_id_to_rob <= `ZERO_ROB;
        store_to_rob_lock <= `FALSE;
        for (i = 0; i < `LSB_SIZE; i = i+1)
            if (is_committed[i] == `FALSE || openum[i] <= `OPENUM_LHU) 
                busy[i] <= `FALSE;
    end
    else begin
        // exec
        if (busy[head] == `TRUE && busy_from_ex == `FALSE && Q1[head] == `ZERO_ROB && Q2[head] == `ZERO_ROB) begin
            // load
            if (openum[head] <= `OPENUM_LHU) begin
                busy[head] <= `FALSE;
                rob_id[head] <= `ZERO_ROB; 
                is_committed[head] <= `FALSE;
                ena_to_ex <= `TRUE;
                openum_to_ex <= openum[head];
                mem_addr_to_ex <= V1[head] + imm[head];
                rob_id_to_cdb <= rob_id[head];
                head <= next_head;
                empty_signal <= (next_head == tail);
            end
            // store: commit first
            else begin
                if (is_committed[head] == `TRUE) begin
                    busy[head] <= `FALSE;
                    rob_id[head] <= `ZERO_ROB;
                    is_committed[head] <= `FALSE;
                    ena_to_ex <= `TRUE;
                    openum_to_ex <= openum[head];
                    mem_addr_to_ex <= V1[head] + imm[head];
                    store_value_to_ex <= V2[head];
                    rob_id_to_cdb <= rob_id[head];
                    head <= next_head;
                    empty_signal <= (next_head == tail);
                    store_to_rob_lock <= `FALSE;
                    if (store_tail == head)
                        store_tail <= `INVALID_LSB;
                end
                else begin
                    // notify rob to commit store inst first
                    ena_to_ex <= `FALSE;
                    if (store_to_rob_lock == `FALSE) begin
                        store_rob_id_to_rob <= rob_id[head];
                        store_to_rob_lock <= `TRUE;
                    end
                    else begin
                        store_rob_id_to_rob <= `ZERO_ROB;
                    end
                end
            end
        end
        else begin
            ena_to_ex <= `FALSE;
            store_rob_id_to_rob <= `ZERO_ROB;
        end
        
        // update when commit
        if (commit_flag_from_rob == `TRUE) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
                if (busy[i] == `TRUE && rob_id[i] == rob_id_from_rob) begin
                    is_committed[i] <= `TRUE;
                    if (openum[i] >= `OPENUM_SB) begin
                        store_tail <= i;
                    end
`ifdef DEBUG
//                    $display("lsb commit upd, pos: ", i);
`endif
                end
            end
        end

        // update
        if (valid_from_rs_cdb == `TRUE) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
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
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
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
                // insert
                empty_signal <= `FALSE;
                busy[tail] <= `TRUE;
                openum[tail] <= openum_from_dsp;          
                Q1[tail] <= real_Q1;
                Q2[tail] <= real_Q2;
                V1[tail] <= real_V1;
                V2[tail] <= real_V2;
                imm[tail] <= imm_from_dsp;
                rob_id[tail] <= rob_id_from_dsp;
                is_committed[tail] <= `FALSE;
                tail <= next_tail;
`ifdef DEBUG
                dbg_insert_Q1 <= real_Q1;
                dbg_insert_Q2 <= real_Q2;
`endif
        end
    end
end

endmodule