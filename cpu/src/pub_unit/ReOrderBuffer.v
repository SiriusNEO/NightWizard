module ReOrderBuffer (
    input wire clk,
    input wire rst,

    // from reg
    input wire [`ROB_LEN - 1 : 0] Q1_from_reg,
    input wire [`ROB_LEN - 1 : 0] Q2_from_reg,
    // to reg
    output reg Q1_ready_to_reg,
    output reg Q2_ready_to_reg

    // from dsp
    // to dsp

);

// rob queue
// [0] as empty index
reg [`ROB_LEN - 1 : 0] head;
reg [`ROB_LEN - 1 : 0] tail;
reg ready [`ROB_SIZE - 1 : 0];
reg [`REG_LEN - 1 : 0] rd [`ROB_LEN - 1 : 0];
reg [`DATA_LEN - 1 : 0] data [`ROB_LEN - 1 : 0];

endmodule