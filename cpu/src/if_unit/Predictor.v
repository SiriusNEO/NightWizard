`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Predictor (
    // query
    input wire [`ADDR_TYPE] query_pc,
    input wire [`INS_TYPE] query_inst,

    // result
    output wire predicted_jump,
    output wire [`ADDR_TYPE] predicted_target_pc
);

assign predicted_jump = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL);
assign predicted_target_pc = JImm;

wire JImm = {{12{query_inst[31]}}, query_inst[19:12], query_inst[20], query_inst[30:21], 1'b0};
wire BImm = {{20{query_inst[31]}}, query_inst[7:7], query_inst[30:25], query_inst[11:8], 1'b0};

endmodule