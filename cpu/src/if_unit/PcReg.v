`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
module PcReg (
    input wire rst,
    input wire update,
    output reg [`ADDR_LEN - 1 : 0] pc
);

reg [`ADDR_LEN - 1 : 0] next_pc;

initial begin
    pc = `ZERO_ADDR;
    next_pc = `ZERO_ADDR + 4;
end

always @(posedge update or posedge rst) begin
    if (rst == `TRUE) begin
        // pc = `ZERO_ADDR;
        // next_pc = `ZERO_ADDR + 4;
        pc = 32'h1188;
        next_pc = 32'h118c;
    end
    else begin
        pc = next_pc;
        next_pc = pc + 4;
    end
end

endmodule