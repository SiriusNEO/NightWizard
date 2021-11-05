`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module LSBuffer (
    input wire clk,
    input wire rst,

    // from dsp
    input wire ena_from_dsp,
    input wire [`OPENUM_LEN - 1 : 0] openum_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V1_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V2_from_dsp,
    input wire [`ROB_LEN : 0] Q1_from_dsp,
    input wire [`ROB_LEN : 0] Q2_from_dsp,
    input wire [`DATA_LEN - 1 : 0] imm_from_dsp,
    input wire [`ROB_LEN : 0] rob_id_from_dsp,
    
    // to if
    output wire full_to_if,

    // to ls ex
    output reg ena_to_ex,
    output reg [`OPENUM_LEN - 1 : 0] openum_to_ex,
    output reg [`ADDR_LEN - 1 : 0] mem_addr_to_ex,
    output reg [`DATA_LEN - 1 : 0] store_value_to_ex,
    // to cdb
    output reg [`ROB_LEN : 0] rob_id_to_cdb,

    // from ls ex
    input wire busy_from_ex,

    // update when commit
    // from rob
    input wire commit_flag_from_rob,
    input wire [`ROB_LEN : 0] rob_id_from_rob,

    // from rs cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_rs_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_rs_cdb,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_ls_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_ls_cdb,

    // to rob: make store commit
    output reg [`ROB_LEN : 0] store_rob_id_to_rob,

    // jump_flag
    input wire commit_jump_flag_from_rob
);

reg [`LSB_LEN - 1 : 0] head;
reg [`LSB_LEN - 1 : 0] tail;
wire [`LSB_LEN - 1 : 0] next_tail = (tail == `LSB_SIZE - 1) ? 0 : tail + 1;

wire empty_signal = (head == tail);
wire full_signal = (next_tail == head);

assign full_to_if = full_signal;

reg busy [`LSB_SIZE - 1 : 0];
reg [`OPENUM_LEN - 1 : 0] openum [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] imm [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V1 [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN : 0] Q1 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN : 0] Q2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN : 0] rob_id [`LSB_SIZE - 1 : 0];

// store should wait to be commited

reg is_committed [`LSB_SIZE - 1 : 0];

reg store_to_rob_lock; // avoid to send twice

// index
integer i;

// debug
integer dbg_insert_openum = -1;

integer dbg_update_index_from_rs = -1;
integer dbg_update_result = -1;

always @(posedge clk) begin
    if (rst == `TRUE || commit_jump_flag_from_rob == `TRUE) begin
        head <= 0;
        tail <= 0;
        for (i = 0; i < `LSB_SIZE; i=i+1) begin
            busy[i] <= `FALSE;
            openum[i] <= `OPENUM_NOP;
            imm[i] <= `ZERO_WORD;
            V1[i] <= `ZERO_WORD;
            V2[i] <= `ZERO_WORD;
            Q1[i] <= `ZERO_ROB;
            Q2[i] <= `ZERO_ROB;
            rob_id[i] <= `ZERO_ROB;
        end
        for (i = 0; i < `ROB_SIZE; i=i+1) begin
            is_committed[i] <= `FALSE;
        end
        ena_to_ex <= `FALSE;
        store_rob_id_to_rob <= `ZERO_ROB;
        store_to_rob_lock <= `FALSE;
    end
    else begin
        
        // exec
        if (empty_signal == `FALSE && busy_from_ex == `FALSE && Q1[head] == `ZERO_ROB && Q2[head] == `ZERO_ROB) begin
            // load
            if (`OPENUM_LHU >= openum[head]) begin
                is_committed[head] <= `FALSE;
                ena_to_ex <= `TRUE;
                openum_to_ex <= openum[head];
                mem_addr_to_ex <= V1[head] + imm[head];
                rob_id_to_cdb <= rob_id[head];
                head <= (head == `LSB_SIZE-1) ? 0 : head + 1;
            end
            // store: commit first
            else begin
                if (is_committed[head] == `TRUE) begin
                    is_committed[head] <= `FALSE;
                    ena_to_ex <= `TRUE;
                    openum_to_ex <= openum[head];
                    mem_addr_to_ex <= V1[head] + imm[head];
                    store_value_to_ex <= V2[head];
                    rob_id_to_cdb <= rob_id[head];
                    head <= (head == `LSB_SIZE-1) ? 0 : head + 1;
                    store_to_rob_lock <= `FALSE;
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
                if (rob_id[i] == rob_id_from_rob) begin
                    is_committed[i] <= `TRUE;
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
            if (full_to_if == `FALSE) begin
                busy[tail] <= `TRUE;
                openum[tail] <= openum_from_dsp;
                V1[tail] <= V1_from_dsp;
                V2[tail] <= V2_from_dsp;
                Q1[tail] <= Q1_from_dsp;
                Q2[tail] <= Q2_from_dsp;
                imm[tail] <= imm_from_dsp;
                rob_id[tail] <= rob_id_from_dsp;
                tail <= next_tail;
`ifdef DEBUG
`endif
            end
        end
    end
end

endmodule