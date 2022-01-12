`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/pub_unit/Matcher.v"

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
    input wire [`ROB_ID_TYPE] head_io_rob_id_from_rob,

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

    // to rob: notify io
    output wire [`ROB_ID_TYPE] io_rob_id_to_rob,

    // jump_flag
    input wire rollback_flag_from_rob
);

reg [`LSB_ID_TYPE] head, tail, store_tail;
wire [`LSB_ID_TYPE] next_head = (head == `LSB_SIZE - 1) ? 0 : head + 1, 
next_tail = (tail == `LSB_SIZE - 1) ? 0 : tail + 1;

reg [`LSB_SIZE - 1 : 0] busy;
reg [`OPENUM_TYPE] openum [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] imm [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] V1 [`LSB_SIZE - 1 : 0];
reg [`DATA_TYPE] V2 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q1 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] Q2 [`LSB_SIZE - 1 : 0];
reg [`ROB_ID_TYPE] rob_id [`LSB_SIZE - 1 : 0];
reg is_committed [`LSB_SIZE - 1 : 0];
// store should wait to be commited

wire [`ADDR_TYPE] head_addr = V1[head] + imm[head];
assign io_rob_id_to_rob = (head_addr == `RAM_IO_PORT) ? rob_id[head] : `ZERO_ROB;

reg [`LSB_POS_TYPE] lsb_element_cnt;
wire full_signal = (lsb_element_cnt >= `LSB_SIZE - `FULL_WARNING);
wire [`INT_TYPE] insert_cnt = (ena_from_dsp ? 1 : 0);
wire [`INT_TYPE] issue_cnt = ((
(busy[head] && busy_from_ex == `FALSE && Q1[head] == `ZERO_ROB && Q2[head] == `ZERO_ROB) 
&& ((openum[head] <= `OPENUM_LHU && (head_addr != `RAM_IO_PORT || head_io_rob_id_from_rob == rob_id[head]))
|| (is_committed[head]))
) ? -1 : 0);
assign full_to_if = full_signal;

// index
integer i;

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

// debug
integer dbg_insert_openum = -1;
integer dbg_insert_Q1 = -1;
integer dbg_insert_Q2 = -1;

integer dbg_update_index_from_rs = -1;
integer dbg_update_result = -1;

always @(posedge clk) begin
    if (rst || (rollback_flag_from_rob && store_tail == `INVALID_LSB)) begin
        lsb_element_cnt <= `ZERO_WORD;
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
    end
    else if (~rdy) begin
    end
    else if (rollback_flag_from_rob) begin
        tail <= (store_tail == `LSB_SIZE - 1) ? 0 : store_tail + 1;
        lsb_element_cnt <= ((store_tail > head) ? store_tail - head + 1 : `LSB_SIZE - head + store_tail + 1);
        for (i = 0; i < `LSB_SIZE; i = i+1)
            if (is_committed[i] == `FALSE || openum[i] <= `OPENUM_LHU) 
                busy[i] <= `FALSE;
    end
    else begin
        ena_to_ex <= `FALSE;
        lsb_element_cnt <= lsb_element_cnt + insert_cnt + issue_cnt;

        // exec
        if (busy[head] && busy_from_ex == `FALSE && Q1[head] == `ZERO_ROB && Q2[head] == `ZERO_ROB) begin
            // load
            if (openum[head] <= `OPENUM_LHU) begin
                if (head_addr != `RAM_IO_PORT || head_io_rob_id_from_rob == rob_id[head]) begin
                    busy[head] <= `FALSE;
                    rob_id[head] <= `ZERO_ROB; 
                    is_committed[head] <= `FALSE;
                    ena_to_ex <= `TRUE;
                    openum_to_ex <= openum[head];
                    mem_addr_to_ex <= head_addr;
                    rob_id_to_cdb <= rob_id[head];
                    head <= next_head;
                end
            end
            // store
            else begin
                if (is_committed[head]) begin
                    busy[head] <= `FALSE;
                    rob_id[head] <= `ZERO_ROB;
                    is_committed[head] <= `FALSE;
                    ena_to_ex <= `TRUE;
                    openum_to_ex <= openum[head];
                    mem_addr_to_ex <= head_addr;
                    store_value_to_ex <= V2[head];
                    rob_id_to_cdb <= rob_id[head];
                    head <= next_head;
                    if (store_tail == head)
                        store_tail <= `INVALID_LSB;
                end 
            end
        end
        
        // update when commit
        if (commit_flag_from_rob) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
                if (busy[i] && rob_id[i] == rob_id_from_rob && !is_committed[i]) begin
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
        if (valid_from_rs_cdb1) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
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
        if (valid_from_rs_cdb2) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
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
        if (valid_from_ls_cdb) begin
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
        
        // insert
        if (ena_from_dsp) begin
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