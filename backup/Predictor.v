`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

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

localparam ADDR_CUT_LEN = 8, BHT_SIZE = 1024, PHT_SIZE = 256, BIT = 2, PATTERN_LEN = 2;
`define ADDR_CUT 9:2
`define PATTERN_TYPE 11:2
localparam STRONG_NOT_TAKEN = 2'b00,
           WEAKLY_NOT_TAKEN = 2'b01,
           WEAKLY_TAKEN = 2'b10,
           STRONG_TAKEN = 2'b11;

wire [`DATA_TYPE] JImm = {{12{query_inst[31]}}, query_inst[19:12], query_inst[20], query_inst[30:21], 1'b0};
wire [`DATA_TYPE] BImm = {{20{query_inst[31]}}, query_inst[7:7], query_inst[30:25], query_inst[11:8], 1'b0};

reg [BIT - 1 : 0] bht [BHT_SIZE - 1 : 0];
reg [PATTERN_LEN - 1 : 0] pht [PHT_SIZE - 1 : 0];

wire [`PATTERN_TYPE] upd_pos = (pc_from_rob[`ADDR_CUT] << PATTERN_LEN) + pht[pc_from_rob[`ADDR_CUT]];

// index
integer i;

// predict port. JALR always not taken


assign predicted_jump = (query_inst[`OPCODE_RANGE] == `OPCODE_JAL) ? `TRUE :
                (query_inst[`OPCODE_RANGE] == `OPCODE_BR ? bht[(query_pc[`ADDR_CUT] << PATTERN_LEN) + pht[query_pc[`ADDR_CUT]]][1] : `FALSE);

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
            bht[i] <= WEAKLY_TAKEN;
        end
        for (i = 0; i < PHT_SIZE; i=i+1) begin
            pht[i] <= 0;
        end
    end
    else if (ena_from_rob) begin
        // update
        bht[upd_pos] <= bht[upd_pos] + 
        ((hit_from_rob) ? 
        // hit 
        (bht[upd_pos] == STRONG_TAKEN ? 0 : 1) : 
        // miss 
        (bht[upd_pos] == STRONG_NOT_TAKEN ? 0 : -1));

        pht[pc_from_rob[`ADDR_CUT]] <= ((pht[pc_from_rob[`ADDR_CUT]] << 1) | hit_from_rob); 
    end
end

endmodule