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
    output reg [`ROB_LEN : 0] store_rob_id_to_rob
);

reg [`LSB_LEN - 1 : 0] head;
reg [`LSB_LEN - 1 : 0] tail;
reg [`LSB_LEN - 1 : 0] next_tail;

wire empty_signal = (head == tail);
wire full_signal = (next_tail == head);

assign full_to_if = full_signal;

reg busy [`LSB_SIZE - 1 : 0];
reg [`OPENUM_LEN - 1 : 0] openum [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] imm [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V1 [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q1 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] rob_id [`LSB_SIZE - 1 : 0];

// store should wait to be commited

reg is_committed [`LSB_SIZE - 1 : 0];

// index
integer i;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        head <= 0;
        tail <= 0;
        next_tail <= 0;
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
    end
    else begin
        if (tail == `LSB_SIZE - 1) next_tail = 0;
        else next_tail = tail + 1;

        // exec
        ena_to_ex = `FALSE;
        store_rob_id_to_rob = `ZERO_ROB;
        if (empty_signal == `FALSE && busy_from_ex == `FALSE && Q1[head] == `ZERO_ROB && Q2[head] == `ZERO_ROB) begin
            // load
            if (`OPENUM_LHU >= openum[head]) begin
                is_committed[rob_id[head]] = `FALSE;
                ena_to_ex = `TRUE;
                openum_to_ex = openum[head];
                mem_addr_to_ex = V1[head] + imm[head];
                rob_id_to_cdb = rob_id[head];
                head = (head == `LSB_SIZE-1) ? 0 : head + 1;
            end
            // store: commit first
            else begin
                if (is_committed[head] == `TRUE) begin
                    is_committed[head] = `FALSE;
                    ena_to_ex = `TRUE;
                    openum_to_ex = openum[head];
                    mem_addr_to_ex = V1[head] + imm[head];
                    store_value_to_ex = V2[head];
                    rob_id_to_cdb = rob_id[head];
                    head = (head == `LSB_SIZE-1) ? 0 : head + 1;
                end
                else begin
                    store_rob_id_to_rob = rob_id[head];
                end
            end
        end

        if (commit_flag_from_rob == `TRUE) begin
            for (i = 0; i < `LSB_SIZE-1; i=i+1) begin
                if (rob_id[i] == rob_id_from_rob) begin
                    is_committed[i] = `TRUE;
                end
            end
        end

        // update
        if (valid_from_rs_cdb == `TRUE) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_rs_cdb) begin
                    V1[i] = result_from_rs_cdb;
                    Q1[i] = `ZERO_ROB;
                end
                else if (Q2[i] == rob_id_from_rs_cdb) begin
                    V2[i] = result_from_rs_cdb;
                    Q2[i] = `ZERO_ROB;
                end
            end
        end
        if (valid_from_ls_cdb == `TRUE) begin
            for (i = 0; i < `LSB_SIZE; i=i+1) begin
                if (Q1[i] == rob_id_from_ls_cdb) begin
                    V1[i] = result_from_ls_cdb;
                    Q1[i] = `ZERO_ROB;
                end
                else if (Q2[i] == rob_id_from_ls_cdb) begin
                    V2[i] = result_from_ls_cdb;
                    Q2[i] = `ZERO_ROB;
                end
            end
        end

        if (ena_from_dsp == `TRUE) begin
            // insert
            if (full_to_if == `FALSE) begin
                busy[tail] = `TRUE;
                openum[tail] = openum_from_dsp;
                V1[tail] = V1_from_dsp;
                V2[tail] = V2_from_dsp;
                Q1[tail] = Q1_from_dsp;
                Q2[tail] = Q2_from_dsp;
                rob_id[tail] = rob_id_from_dsp;
                tail = next_tail;
`ifdef DEBUG
                $display("lsb insert... openum:", openum_from_dsp);
                $display("lsb Q1: ", Q1[0], Q1[1], Q1[2], Q1[3], Q1[4], Q1[5], Q1[6], Q1[7], Q1[8], Q1[9], Q1[10], Q1[11], Q1[12], Q1[13], Q1[14], Q1[15]);
                $display("lsb V1: ", V1[0], V1[1], V1[2], V1[3], V1[4], V1[5], V1[6], V1[7], V1[8], V1[9], V1[10], V1[11], V1[12], V1[13], V1[14], V1[15]);
                $display("lsb Q2: ", Q2[0], Q2[1], Q2[2], Q2[3], Q2[4], Q2[5], Q2[6], Q2[7], Q2[8], Q2[9], Q2[10], Q2[11], Q2[12], Q2[13], Q2[14], Q2[15]);
                $display("lsb V2: ", V2[0], V2[1], V2[2], V2[3], V2[4], V2[5], V2[6], V2[7], V2[8], V2[9], V2[10], V2[11], V2[12], V2[13], V2[14], V2[15]);
                $display("lsb rob_id: ", rob_id[0], rob_id[1], rob_id[2], rob_id[3], rob_id[4], rob_id[5], rob_id[6], rob_id[7], rob_id[8], rob_id[9], rob_id[10], rob_id[11], rob_id[12], rob_id[13], rob_id[14], rob_id[15]);
`endif
            end
        end
    end
end

endmodule