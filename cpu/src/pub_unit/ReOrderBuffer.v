`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
module ReOrderBuffer (
    input wire clk,
    input wire rst,

    // reply to reg_ready query
    // from reg
    input wire [`ROB_LEN : 0] Q1_from_reg,
    input wire [`ROB_LEN : 0] Q2_from_reg,
    // to reg
    output reg Q1_ready_to_reg,
    output reg Q2_ready_to_reg,

    // dsp allocate to rob
    // from dsp
    input wire ena_from_dsp,
    input wire [`REG_LEN - 1 : 0] rd_from_dsp,
    input wire [`ADDR_LEN - 1 : 0] pc_from_dsp,
    // to dsp
    output reg [`ROB_LEN : 0] rob_id_to_dsp,

    // to if
    output reg full_to_if,

    // update rob by cdb
    // from cdb
    input wire [`ROB_LEN : 0] rob_id_from_cdb,
    input wire [`DATA_LEN - 1 : 0] result_from_cdb,

    // commit
    // to reg
    output reg [`REG_LEN - 1 : 0] rd_to_reg,
    output reg [`ROB_LEN : 0] Q_to_reg,
    output reg [`DATA_LEN - 1 : 0] V_to_reg
);

// rob queue
// Q = index + 1, Q = 0: empty

//head = tail empty
reg [`ROB_LEN - 1 : 0] head;
reg [`ROB_LEN - 1 : 0] tail;
reg [`ROB_LEN - 1 : 0] next_tail;

reg ready [`ROB_SIZE - 1 : 0];
reg [`REG_LEN - 1 : 0] rd [`ROB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] data [`ROB_SIZE - 1 : 0];
reg [`ADDR_LEN - 1 : 0] pc [`ROB_SIZE - 1 : 0];

// index
integer i;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        head <= 0;
        tail <= 0;
        next_tail <= 0;
        for (i = 0; i < `ROB_SIZE; i++) begin
            ready[i] <= `FALSE;
            rd[i] <= `ZERO_REG;
            data[i] <= `ZERO_WORD;
            pc[i] <= `ZERO_ADDR; 
        end
    end 
    else begin
        if (tail == `ROB_SIZE - 1) next_tail = 0;
        else next_tail = tail + 1;

        // full signal
        full_to_if = (next_tail == head);

        if (ena_from_dsp == `TRUE) begin
            // insert
            if (full_to_if == `FALSE) begin
                rd[next_tail] <= rd_from_dsp;
                data[next_tail] <= `ZERO_WORD;
                pc[next_tail] <= pc_from_dsp;
                ready[next_tail] <= `FALSE;
                rob_id_to_dsp <= next_tail;
                tail <= next_tail;
            end    
        end

        // commit
        if (ready[head] == `TRUE) begin
            // commit to regfile
        end   
    end 
end    

endmodule