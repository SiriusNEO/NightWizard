`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
module ReserveStation (
    input wire clk,
    input wire rst,

    // from dsp
    input wire [`OPENUM_LEN - 1 : 0] openum_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V1_from_dsp,
    input wire [`DATA_LEN - 1 : 0] V2_from_dsp,
    input wire [`ROB_LEN - 1 : 0] Q1_from_dsp,
    input wire [`ROB_LEN - 1 : 0] Q2_from_dsp,
    input wire [`ADDR_LEN - 1 : 0] pc_from_dsp,
    input wire [`DATA_LEN - 1 : 0] imm_from_dsp,
    // to dsp
    output reg full_to_dsp,

    // to al ex
    output reg [`OPENUM_LEN - 1 : 0] openum_to_al,
    output reg [`DATA_LEN - 1 : 0] oprand1_to_al,
    output reg [`DATA_LEN - 1 : 0] oprand2_to_al,

    // to br ex
    output reg [`OPENUM_LEN - 1 : 0] openum_to_br,
    output reg [`DATA_LEN - 1 : 0] oprand1_to_br,
    output reg [`DATA_LEN - 1 : 0] oprand2_to_br,
    output reg [`DATA_LEN - 1 : 0] pc_to_br,
    output reg [`DATA_LEN - 1 : 0] offset_to_br
);

// rs store
// ARI RS Node: busy, pc, openum, V1, V2, Q1, Q2, ROB_id
// RS[0] left for invalid
reg busy [`RS_SIZE - 1 : 0];
reg [`ADDR_LEN - 1 : 0] pc [`RS_SIZE - 1 : 0]; 
reg [`OPENUM_LEN - 1 : 0] openum [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] imm [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V1 [`RS_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V2 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q1 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] Q2 [`RS_SIZE - 1 : 0];
reg [`ROB_LEN - 1 : 0] ROB_id [`RS_SIZE - 1 : 0];

// signal

integer i;
integer free_index;
integer issue_index;

always @(posedge clk) begin
    if (rst == `TRUE) begin
    end else begin

        free_index = -1;
        issue_index = -1;

        for (i = `RS_SIZE - 1; free_index >= 0 && i >= 0; i--) begin
            if (busy[i] == `FALSE) free_index = i;
        end    

        full_to_dsp = (free_index == -1); 

        for (i = `RS_SIZE - 1; issue_index >= 0 && i >= 0; i--) begin
            if (busy[i] == `TRUE && Q1[i] == 0 && Q2[i] == 0) issue_index = i;
        end     
        
        // insert to rs
        if (free_index >= 0) begin
            busy[free_index]  = `TRUE;
            openum[free_index] = openum_from_dsp;
            V1[free_index] = V1_from_dsp;
            V2[free_index] = V2_from_dsp;
            Q1[free_index] = Q1_from_dsp;
            Q2[free_index] = Q2_from_dsp;
            pc[free_index] = pc_from_dsp;
            imm[free_index] = imm_from_dsp;
        end

        // issue
        if (openum[issue_index] >= `OPENUM_BEQ && openum[issue_index] <= `OPENUM_BGEU) begin
            openum_to_al <= openum[issue_index];
            oprand1_to_al <= V1[issue_index];
            if (openum[issue_index] >= `OPENUM_ADDI) begin
                oprand2_to_al <= imm[issue_index];
            end else begin
                oprand2_to_al <= V2[issue_index];
            end
        end else begin
            openum_to_br <= openum[issue_index];
            oprand1_to_br <= V1[issue_index];
            oprand2_to_br <= V2[issue_index];
            pc_to_br <= pc[issue_index];
            offset_to_br <= imm[issue_index];
        end        
    end        
end    

endmodule