`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module RegFile (
    input wire clk,
    input wire rst,

    // call-back
    // from dsp
    input wire [`REG_LEN - 1 : 0] rs1_from_dsp,
    input wire [`REG_LEN - 1 : 0] rs2_from_dsp,
    // to dsp
    output wire [`DATA_LEN - 1 : 0] V1_to_dsp,
    output wire [`DATA_LEN - 1 : 0] V2_to_dsp,
    output wire [`ROB_LEN : 0] Q1_to_dsp,
    output wire [`ROB_LEN : 0] Q2_to_dsp,

    // commit from rob
    input wire commit_flag_from_rob,
    input wire [`REG_LEN - 1 : 0] rd_from_rob,
    input wire [`ROB_LEN : 0] Q_from_rob,
    input wire [`DATA_LEN - 1 : 0] V_from_rob,

    // debug port
    input wire debug_flag
);

// reg store
reg [`ROB_LEN - 1 : 0] Q [`REG_SIZE - 1 : 0];
reg [`DATA_LEN - 1 : 0] V [`REG_SIZE - 1 : 0];

// index
integer i;

assign Q1_to_dsp = Q[rs1_from_dsp];
assign Q2_to_dsp = Q[rs2_from_dsp];
assign V1_to_dsp = V[rs1_from_dsp];
assign V2_to_dsp = V[rs2_from_dsp];

always @(posedge clk) begin
    if (rst == `TRUE) begin
        for (i = 0; i < `REG_SIZE; i++) begin
            Q[i] = `ZERO_ROB;
            V[i] = `ZERO_WORD;
        end
    end
    else begin
        if (commit_flag_from_rob == `TRUE) begin
            V[rd_from_rob] = V_from_rob;
            if (Q[rd_from_rob] == Q_from_rob)
                Q[rd_from_rob] = `ZERO_ROB;
            if (debug_flag == `TRUE) begin
                $display("Q", Q[0], Q[1], Q[2], Q[3], Q[4], Q[5], Q[6], Q[7], Q[8], Q[9], Q[10], Q[11], Q[12], Q[13], Q[14], V[15]);
                $display("V", V[0], V[1], V[2], V[3], V[4], V[5], V[6], V[7], V[8], V[9], V[10], V[11], V[12], V[13], V[14], V[15]);
            end
        end
    end
end   

endmodule