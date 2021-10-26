`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
module PcReg (
    input wire clk,
    input wire rst,

    input wire upd_flag_from_if,
    input wire commit_flag_from_rob,
    input wire [`ADDR_LEN - 1 : 0] target_pc_from_rob, 

    output reg [`ADDR_LEN - 1 : 0] pc
);

reg [`ADDR_LEN - 1 : 0] next_pc;

initial begin
    pc = `ZERO_ADDR;
    next_pc = `ZERO_ADDR + 4;
end

always @(posedge clk) begin
    if (rst == `TRUE) begin
        // pc = `ZERO_ADDR;
        // next_pc = `ZERO_ADDR + 4;
        pc = 32'h11d8;
        next_pc = 32'h11dc;
    end
    else begin
        if (commit_flag_from_rob == `TRUE) begin
            pc = target_pc_from_rob;
            next_pc = pc + 4;
        end
        else
        if (upd_flag_from_if == `TRUE) begin
            pc = next_pc;
            next_pc = pc + 4;
        end
    end
end

endmodule