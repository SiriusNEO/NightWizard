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
    output reg full_to_if,

    // update rob by cdb
    // from cdb
    input wire valid_from_cdb,
    input wire [`ROB_LEN : 0] rob_id_from_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_cdb,
    input wire [`ADDR_LEN - 1 : 0] target_pc_from_cdb,
    input wire jump_flag_from_cdb,

    // commit
    output reg commit_flag_to_reg_pcr,
    // to reg
    output reg [`REG_LEN - 1 : 0] rd_to_reg,
    output reg [`ROB_LEN : 0] Q_to_reg,
    output reg [`DATA_LEN - 1 : 0] V_to_reg,
    // to pcr
    output reg jump_flag_to_pcr,
    output reg [`ADDR_LEN - 1 : 0] target_pc_to_pcr
);

// rob queue
// Q & rob_id hint:
// Q = index + 1, Q = 0: empty
// Q->index, -1 & check Q==`ZERO_ROB; index->Q, +1

// head = tail empty
// head = next_tail full
reg [`ROB_LEN - 1 : 0] head;
reg [`ROB_LEN - 1 : 0] tail;
reg [`ROB_LEN - 1 : 0] next_tail;

reg ready [`ROB_SIZE - 1 : 0];
reg [`REG_LEN - 1 : 0] rd [`ROB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] data [`ROB_SIZE - 1 : 0];
reg [`ADDR_LEN - 1 : 0] target_pc [`ROB_SIZE - 1 : 0];
reg jump_flag [`ROB_LEN - 1 : 0];

// index
integer i;

assign Q1_ready_to_dsp = (Q1_from_dsp == `ZERO_ROB) ? `TRUE : (ready[Q1_from_dsp - 1] == `TRUE);
assign Q2_ready_to_dsp = (Q2_from_dsp == `ZERO_ROB) ? `TRUE : (ready[Q2_from_dsp - 1] == `TRUE);

assign rob_id_to_dsp = tail + 1;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        head <= 0;
        tail <= 0;
        next_tail <= 0;
        for (i = 0; i < `ROB_SIZE; i++) begin
            ready[i] <= `FALSE;
            rd[i] <= `ZERO_REG;
            data[i] <= `ZERO_WORD;
            target_pc[i] <= `ZERO_ADDR;
            jump_flag[i] <= `FALSE;
        end
    end 
    else begin
        next_tail = (tail == `ROB_SIZE - 1) ? 0 : tail + 1;
        
        // full signal
        full_to_if = (next_tail == head);

        // commit
        if (ready[head] == `TRUE) begin
            // commit to regfile
            commit_flag_to_reg_pcr = `TRUE;
            rd_to_reg = rd[head];
            Q_to_reg = head + 1;
            V_to_reg = data[head];
            if (jump_flag[head] == `TRUE) begin
                jump_flag_to_pcr = `TRUE;
                target_pc_to_pcr = target_pc[head];
            end
            head = (head == `ROB_SIZE-1) ? 0 : head + 1;
        end
        else begin
            commit_flag_to_reg_pcr = `FALSE;
        end

        // update
        if (valid_from_cdb == `TRUE) begin
            ready[rob_id_from_cdb - 1] <= `TRUE;
            data[rob_id_from_cdb - 1] <= result_from_cdb;
            target_pc[rob_id_from_cdb - 1] <= target_pc_from_cdb;
            jump_flag[rob_id_from_cdb - 1] <= jump_flag_from_cdb;
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
            end    
        end
    end 
end

endmodule