`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Predictor (
    input wire clk,
    input wire rst,

    // query
    input wire [`ADDR_TYPE] query_pc,
    input wire [`INS_TYPE] query_inst,

    output wire predicted_jump,
    output wire [`ADDR_TYPE] predicted_imm,

    // update
    input wire ena_from_rob, hit_from_rob,
    input wire [`ADDR_TYPE] pc_from_rob
);

localparam ADDR_CUT_LEN = 8, BHT_SIZE = 256, BIT = 2, PATTERN_LEN = 6;
`define ADDR_CUT 9:2
localparam STRONG_NOT_TAKEN = 2'b00,
           WEAKLY_NOT_TAKEN = 2'b01,
           WEAKLY_TAKEN = 2'b10,
           STRONG_TAKEN = 2'b11;

wire [`DATA_TYPE] JImm = {{12{query_inst[31]}}, query_inst[19:12], query_inst[20], query_inst[30:21], 1'b0};
wire [`DATA_TYPE] BImm = {{20{query_inst[31]}}, query_inst[7:7], query_inst[30:25], query_inst[11:8], 1'b0};

reg [BIT - 1 : 0] branch_history_table [BHT_SIZE - 1 : 0];

wire [`ADDR_CUT] cut_pc = pc_from_rob[`ADDR_CUT];

// index
integer i;

// predict port. JALR always not taken


assign predicted_jump = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL) ? `TRUE :
                (query_inst[`OPCODE_RANGE] == `OPCODE_BR ? 
                (branch_history_table[query_pc[`ADDR_CUT]][1]) : `FALSE);

assign predicted_imm = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL ? JImm : BImm);
/*
assign predicted_jump = (
                        (query_inst[`OPCODE_RANGE] == `OPCODE_JAL || query_inst[`OPCODE_RANGE] == `OPCODE_BR) ? 
                        (query_pc + predicted_imm < query_pc ? `TRUE : `FALSE) : `FALSE
                        );
*/
// assign predicted_jump = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL);

// update port
always @(posedge clk) begin
    if (rst) begin
        for (i = 0; i < BHT_SIZE; i=i+1) begin
            branch_history_table[i] <= WEAKLY_NOT_TAKEN;
        end
    end
    else if (ena_from_rob) begin
        // update
        branch_history_table[cut_pc] <= branch_history_table[cut_pc] + 
        ((hit_from_rob) ? 
        // hit 
        (branch_history_table[cut_pc] == STRONG_TAKEN ? 0 : 1) : 
        // miss 
        (branch_history_table[cut_pc] == STRONG_NOT_TAKEN ? 0 : -1));
    end
end

endmodule