`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

`ifndef MATCHER
`define MATCHER

// three entries matcher
module Matcher (
    input wire [`ROB_ID_TYPE] Q,

    input wire valid1,
    input wire [`ROB_ID_TYPE] rob_id1,
    input wire [`DATA_TYPE] value1,
    
    input wire valid2,
    input wire [`ROB_ID_TYPE] rob_id2,
    input wire [`DATA_TYPE] value2,
    
    input wire valid3,
    input wire [`ROB_ID_TYPE] rob_id3,
    input wire [`DATA_TYPE] value3,

    output wire match,
    output wire [`DATA_TYPE] matched_V
);

wire match1 = (valid1 && Q == rob_id1);
wire match2 = (valid2 && Q == rob_id2);
wire match3 = (valid3 && Q == rob_id3);

assign match = (match1 || match2 || match3);
assign matched_V = (match2 ? value2 : (match1 ? value1 : (match3 ? value3 : `ZERO_WORD)));

endmodule

`endif