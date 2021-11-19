`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Predictor (
    input wire clk,
    input wire rst,

    // query
    input wire [`ADDR_TYPE] query_pc,
    input wire [`INS_TYPE] query_inst,

    // result
    output wire predicted_jump,
    output wire [`ADDR_TYPE] predicted_target_pc
);

localparam
localparam

assign predicted_jump = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL);
assign predicted_target_pc = JImm;

wire [`DATA_TYPE] JImm = {{12{query_inst[31]}}, query_inst[19:12], query_inst[20], query_inst[30:21], 1'b0};
wire [`DATA_TYPE] BImm = {{20{query_inst[31]}}, query_inst[7:7], query_inst[30:25], query_inst[11:8], 1'b0};

reg [`ADDR_TYPE] last_predicted_pc;


always @(posedge clk) begin
    if (rst) begin
        last_predicted_pc <= `ZERO_ADDR;
    end
end

endmodule