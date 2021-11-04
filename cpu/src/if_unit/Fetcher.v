`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // to decoder
    output reg [`INS_LEN - 1 : 0] inst_to_dcd,
    
    // to dsp
    output reg [`ADDR_LEN - 1 : 0] pc_to_dsp,
    output reg ok_flag_to_dsp,

    // port with memctrl
    // to memctrl
    output reg [`ADDR_LEN - 1 : 0] pc_to_mc,
    output reg ena_to_mc,
    output reg drop_flag_to_mc,
    // from memctrl
    input wire ok_flag_from_mc,
    input wire [`DATA_LEN - 1 : 0] inst_from_mc,
    
    // full signal
    input wire full_from_rs, full_from_lsb, full_from_rob,

    // from rob
    input wire commit_flag_from_rob,
    input wire commit_jump_flag_from_rob,
    input wire [`ADDR_LEN - 1 : 0] target_pc_from_rob
);

parameter 
// fetcher status
STATUS_IDLE = 0,
STATUS_FETCH = 1;

integer status;

reg [`ADDR_LEN - 1 : 0] pc;
reg [`ADDR_LEN - 1 : 0] next_pc;

always @(pc or posedge commit_jump_flag_from_rob == `TRUE) begin
    if (commit_jump_flag_from_rob) begin
        next_pc = target_pc_from_rob;
    end
    else begin
        next_pc = pc + 4;
    end
end


always @(posedge clk) begin
    if (rst == `TRUE) begin
        // pc <= 32'h1188;
        pc <= `ZERO_ADDR;
        status <= STATUS_IDLE;
        ena_to_mc <= `FALSE;
        ok_flag_to_dsp <= `FALSE;
        drop_flag_to_mc <= `FALSE;
    end
    else if (commit_jump_flag_from_rob == `TRUE) begin
        ok_flag_to_dsp <= `FALSE;
        pc <= next_pc;
        status <= STATUS_IDLE;
        drop_flag_to_mc <= `TRUE;
    end
    else begin
        drop_flag_to_mc <= `FALSE;
        // if rdy and no components full, start working
        if (rdy == `TRUE && 
            full_from_rs == `FALSE && 
            full_from_lsb == `FALSE && 
            full_from_rob == `FALSE) begin
            // fetcher is IDLE, request to memctrl
            if (status == STATUS_IDLE) begin
                ena_to_mc <= `TRUE;
                pc_to_mc <= pc;
                status <= STATUS_FETCH;
                ok_flag_to_dsp <= `FALSE;
            end
            else begin
                ena_to_mc <= `FALSE; // memctrl is woring now, so no duplicate request
                
                // memctrl ok, submit the inst
                if (ok_flag_from_mc == `TRUE) begin
                    pc_to_dsp <= pc;
                    inst_to_dcd <= inst_from_mc;
                    ok_flag_to_dsp <= `TRUE;
                    pc <= next_pc;
                    status <= STATUS_IDLE;
                end
                else begin
                    // waiting memctrl
                    ok_flag_to_dsp <= `FALSE;
                end
            end
        end
        // unable to work, pause now
        else begin
            ena_to_mc <= `FALSE;
            ok_flag_to_dsp <= `FALSE;
        end
    end
end

endmodule