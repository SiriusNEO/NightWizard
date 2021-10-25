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
    output reg full_to_if,

    // to ls ex
    output reg [`OPENUM_LEN - 1 : 0] openum_to_ex,
    output reg [`DATA_LEN - 1 : 0] V1_to_ex,
    output reg [`DATA_LEN - 1 : 0] V2_to_ex
);

reg [`LSB_LEN - 1 : 0] head;
reg [`LSB_LEN - 1 : 0] tail;
reg [`LSB_LEN - 1 : 0] next_tail;

reg busy [`LSB_SIZE - 1 : 0];
reg [`OPENUM_LEN - 1 : 0] openum [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] imm [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V1 [`LSB_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q1 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q2 [`LSB_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] rob_id [`LSB_SIZE - 1 : 0];

// index
integer i;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        for (i = 0; i < `LSB_SIZE; i++) begin
            busy[i] <= `FALSE;
            openum[i] <= `OPENUM_NOP;
            imm[i] <= `ZERO_WORD;
            V1[i] <= `ZERO_WORD;
            V2[i] <= `ZERO_WORD;
            Q1[i] <= `ZERO_ROB;
            Q2[i] <= `ZERO_ROB;
            rob_id[i] <= `ZERO_ROB;
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
                busy[next_tail] <= `TRUE;
                openum[next_tail] <= openum_from_dsp;
                V1[next_tail] <= V1_from_dsp;
                V2[next_tail] <= V2_from_dsp;
                Q1[next_tail] <= Q1_from_dsp;
                Q2[next_tail] <= Q2_from_dsp;
                rob_id[next_tail] <= rob_id_from_dsp;
            end
        end
    end
end

endmodule