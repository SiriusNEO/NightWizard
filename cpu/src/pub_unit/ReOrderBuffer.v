`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module ReOrderBuffer (
    input wire clk,
    input wire rst,

    // reply to dsp_ready query
    // from dsp
    input wire [`ROB_LEN : 0] Q1_from_dsp,
    input wire [`ROB_LEN : 0] Q2_from_dsp,
    // to dsp
    output wire Q1_ready_to_dsp,
    output wire Q2_ready_to_dsp,

    // dsp allocate to rob
    // from dsp
    input wire ena_from_dsp,
    input wire [`REG_LEN - 1 : 0] rd_from_dsp,
    // to dsp
    output wire [`ROB_LEN : 0] rob_id_to_dsp,

    // to if
    output wire full_to_if,

    // update rob by cdb
    // from cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_rs_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_rs_cdb,
    input wire [`ADDR_LEN - 1 : 0] target_pc_from_rs_cdb,
    input wire jump_flag_from_rs_cdb,

    input wire valid_from_ls_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_ls_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_ls_cdb,
    
    // from lsb
    input wire [`ROB_LEN : 0] store_rob_id_from_lsb,

    // commit
    output reg commit_flag,
    // to reg
    output reg [`REG_LEN - 1 : 0] rd_to_reg,
    output reg [`ROB_LEN : 0] Q_to_reg,
    output reg [`DATA_LEN - 1 : 0] V_to_reg,
    // to if
    output reg commit_jump_flag,
    output reg [`ADDR_LEN - 1 : 0] target_pc_to_if,
    // to lsb
    output reg [`ROB_LEN : 0] rob_id_to_lsb
);

// rob queue
// Q & rob_id hint:
// Q = index + 1, Q = 0: empty
// Q->index, -1 & check Q==`ZERO_ROB; index->Q, +1

// head = tail empty
// head = next_tail full
reg [`ROB_LEN - 1 : 0] head;
reg [`ROB_LEN - 1 : 0] tail;
wire [`ROB_LEN - 1 : 0] next_tail = (tail == `ROB_SIZE - 1) ? 0 : tail + 1;

wire empty_signal = (head == tail);
wire full_signal = (next_tail == head);

assign full_to_if = full_signal;

reg ready [`ROB_SIZE - 1 : 0];
reg [`REG_LEN - 1 : 0] rd [`ROB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] data [`ROB_SIZE - 1 : 0];
reg [`ADDR_LEN - 1 : 0] target_pc [`ROB_SIZE - 1 : 0];
reg jump_flag [`ROB_SIZE - 1 : 0];

// index
integer i;

// debug
integer dbg_update_from_rs = -1;
integer dbg_update_from_rs_jump_flag = -1;

integer dbg_update_from_lsb = -1;
integer dbg_store_commit_request = -1;

integer dbg_commit = -1;
integer dbg_commit_jump_flag = -1;
integer dbg_commit_target_pc = -1;

integer dbg_insert_rd = -1;
integer dbg_insert_from_dsp = -1;

assign Q1_ready_to_dsp = (Q1_from_dsp == `ZERO_ROB) ? `TRUE : (ready[Q1_from_dsp - 1] == `TRUE);
assign Q2_ready_to_dsp = (Q2_from_dsp == `ZERO_ROB) ? `TRUE : (ready[Q2_from_dsp - 1] == `TRUE);

assign rob_id_to_dsp = tail + 1;

always @(posedge clk) begin
    if (rst == `TRUE || commit_jump_flag == `TRUE) begin
        head <= 0;
        tail <= 0;
        for (i = 0; i < `ROB_SIZE; i=i+1) begin
            ready[i] <= `FALSE;
            rd[i] <= `ZERO_REG;
            data[i] <= `ZERO_WORD;
            target_pc[i] <= `ZERO_ADDR;
            jump_flag[i] <= `FALSE;
        end
        commit_flag <= `FALSE;
        commit_jump_flag <= `FALSE;
    end 
    else begin

        // commit
        if (ready[head] == `TRUE) begin
            // commit to regfile
            commit_flag <= `TRUE;
            rd_to_reg <= rd[head];
            Q_to_reg <= head + 1;
            V_to_reg <= data[head];
            rob_id_to_lsb <= head + 1;
            if (jump_flag[head] == `TRUE) begin
                commit_jump_flag <= `TRUE;
                target_pc_to_if <= target_pc[head];
            end
            else begin
                commit_jump_flag <= `FALSE;
            end
            ready[head] <= `FALSE;
            head <= (head == `ROB_SIZE-1) ? 0 : head + 1;
`ifdef DEBUG
            dbg_commit <= head + 1;
            dbg_commit_jump_flag <= jump_flag[head];
            dbg_commit_target_pc <= target_pc[head];
`endif
        end
        else begin
            commit_flag <= `FALSE;
        end

        // update
        if (valid_from_rs_cdb == `TRUE) begin
            ready[rob_id_from_rs_cdb - 1] <= `TRUE;
            data[rob_id_from_rs_cdb - 1] <= result_from_rs_cdb;
            target_pc[rob_id_from_rs_cdb - 1] <= target_pc_from_rs_cdb;
            jump_flag[rob_id_from_rs_cdb - 1] <= jump_flag_from_rs_cdb;
`ifdef DEBUG
            dbg_update_from_rs <= rob_id_from_rs_cdb;
            dbg_update_from_rs_jump_flag <= jump_flag_from_rs_cdb;
`endif
        end
        
        // store commit directly
        if (store_rob_id_from_lsb != `ZERO_ROB) begin
            ready[store_rob_id_from_lsb - 1] <= `TRUE;
`ifdef DEBUG
            dbg_store_commit_request <= store_rob_id_from_lsb;
`endif
        end

        if (valid_from_ls_cdb == `TRUE) begin
            ready[rob_id_from_ls_cdb - 1] <= `TRUE; 
            data[rob_id_from_ls_cdb - 1] <= result_from_ls_cdb;
`ifdef DEBUG
            dbg_update_from_lsb <= rob_id_from_ls_cdb;
`endif
        end

        if (ena_from_dsp == `TRUE) begin
            // insert
            if (full_to_if == `FALSE) begin
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
end

endmodule