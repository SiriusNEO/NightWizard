`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

module InstQueue (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire global_full,

    // fetcher
    input wire ok_flag_from_if,
    input wire [`INS_TYPE] inst_from_if,
    input wire [`ADDR_TYPE] pc_from_if,
    input wire [`ADDR_TYPE] rollback_pc_from_if,
    input wire predicted_jump_from_if,

    // rollback
    input wire rollback_flag_from_rob,

    // full
    output wire full_to_if,
    
    // to dsp
    output reg ok_flag_to_dsp,
    output reg [`INS_TYPE] inst_to_dsp,
    output reg [`ADDR_TYPE] pc_to_dsp,
    output reg [`ADDR_TYPE] rollback_pc_to_dsp,
    output reg predicted_jump_to_dsp
);

reg valid [`IQ_SIZE - 1 : 0];
reg [`INS_TYPE] inst [`IQ_SIZE - 1 : 0];
reg [`ADDR_TYPE] pc [`IQ_SIZE - 1 : 0];
reg [`ADDR_TYPE] rollback_pc [`IQ_SIZE - 1 : 0];
reg predicted_jump [`IQ_SIZE - 1 : 0];

reg [`IQ_ID_TYPE] head, tail;
wire [`IQ_ID_TYPE] next_head = (head == `IQ_SIZE - 1) ? 0 : head + 1, 
next_tail = (tail == `IQ_SIZE - 1) ? 0 : tail + 1;

reg [`IQ_POS_TYPE] iq_element_cnt;
wire full_signal = (iq_element_cnt >= `IQ_SIZE - `IQ_FULL_WARNING);
assign full_to_if = full_signal;

wire [`INT_TYPE] insert_cnt = (ok_flag_from_if ? 1 : 0);
wire [`INT_TYPE] dispatch_cnt = ((valid[head] == `TRUE && global_full == `FALSE) ? -1 : 0);

// index
integer i;

always @(posedge clk) begin
    if (rst || rollback_flag_from_rob) begin
        head <= `ZERO_IQ;
        tail <= `ZERO_IQ;
        iq_element_cnt <= `ZERO_WORD;
        ok_flag_to_dsp <= `FALSE;
        for (i = 0; i < `IQ_SIZE; i = i+1) begin
            valid[i] <= `FALSE;
        end
    end
    else if (~rdy) begin
    end
    else begin
        iq_element_cnt <= iq_element_cnt + insert_cnt + dispatch_cnt;

        if (ok_flag_from_if) begin
            inst[tail] <= inst_from_if;
            pc[tail] <= pc_from_if;
            rollback_pc[tail] <= rollback_pc_from_if;
            predicted_jump[tail] <= predicted_jump_from_if;

            valid[tail] <= `TRUE;
            tail <= next_tail;
        end

        ok_flag_to_dsp <= `FALSE;
        if (valid[head] == `TRUE && global_full == `FALSE) begin
            ok_flag_to_dsp <= `TRUE;

            inst_to_dsp <= inst[head];
            pc_to_dsp <= pc[head];
            rollback_pc_to_dsp <= rollback_pc[head];
            predicted_jump_to_dsp <= predicted_jump[head];
            
            valid[head] <= `FALSE;
            head <= next_head;
        end
    end
end

endmodule