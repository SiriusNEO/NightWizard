`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // to decoder
    output reg [`INS_LEN - 1 : 0] inst_to_dcd,
    
    // to dsp
    output reg [`INS_LEN - 1 : 0] inst_to_dsp,
    output reg [`ADDR_LEN - 1 : 0] pc_to_dsp,
    output reg ok_flag_to_dsp,

    // port with memctrl
    // to memctrl
    output reg [`ADDR_LEN - 1 : 0] pc_to_mc,
    output reg ena_to_mc,
    // from memctrl
    input wire ok_flag_from_mc,
    input wire [`DATA_LEN - 1 : 0] inst_from_mc,
    
    // full signal
    input wire full_from_rs,
    input wire full_from_lsb, 
    input wire full_from_rob,

    // to pc 
    output reg upd_to_pcr,
    // from pc
    input wire [`ADDR_LEN - 1 : 0] pc_from_pcr
);

reg busy;

initial begin
    busy = `FALSE;
end

always @(posedge clk) begin
    if (rst == `TRUE) begin
        busy <= `FALSE;
        ena_to_mc <= `FALSE;
        ok_flag_to_dsp <= `FALSE;
    end
    else if (rdy == `TRUE) begin
        if (ok_flag_from_mc == `TRUE) begin
            pc_to_dsp <= pc_from_pcr;
            inst_to_dcd <= inst_from_mc;
            busy <= `FALSE;
            ok_flag_to_dsp <= `TRUE;
            upd_to_pcr <= `TRUE;
        end
        else begin
            ok_flag_to_dsp <= `FALSE;
        end
        
        if (busy == `TRUE) begin
            ena_to_mc <= `FALSE;
        end
        else begin
            ena_to_mc <= `TRUE;
            pc_to_mc <= pc_from_pcr;
            busy <= `TRUE;
            ok_flag_to_dsp <= `FALSE;
            upd_to_pcr <= `FALSE;
        end
    end
end

endmodule