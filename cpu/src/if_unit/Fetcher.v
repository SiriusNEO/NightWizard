`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/if_unit/ICache.v"
`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/if_unit/Predictor.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // to decoder
    output reg [`INS_TYPE] inst_to_dcd,

    // full signal
    input wire global_full,
    
    // to dsp
    output reg [`ADDR_TYPE] pc_to_dsp,
    output reg ok_flag_to_dsp,

    // port with memctrl
    // to memctrl
    output reg [`ADDR_TYPE] pc_to_mc,
    output reg ena_to_mc,
    output reg drop_flag_to_mc,
    // from memctrl
    input wire ok_flag_from_mc,
    input wire [`INS_TYPE] inst_from_mc,

    // from rob
    input wire commit_flag_from_rob,
    input wire commit_jump_flag_from_rob,
    input wire [`ADDR_TYPE] target_pc_from_rob
);

parameter 
// fetcher status
STATUS_IDLE = 0,
STATUS_FETCH = 1;

integer status;

// pc reg
reg [`ADDR_TYPE] pc, mem_pc;

// icache
wire hit;
wire [`INS_TYPE] inst_from_icache;
reg ena_to_icache;
reg [`ADDR_TYPE] addr_to_icache;
reg [`INS_TYPE] inst_to_icache;

// predictor
wire predicted_jump;
wire [`ADDR_TYPE] predicted_target_pc;

// stall for debug
integer cnt = 0;
parameter wait_clock = 8;

ICache icache (
    // query
    .query_pc(pc),
    .hit(hit),
    .returned_inst(inst_from_icache),

    // put into icache
    .ena_from_if(ena_to_icache),
    .addr_from_if(addr_to_icache),
    .inst_from_if(inst_to_icache)
);

Predictor predictor (
    // query
    .query_pc(pc),
    .query_inst(inst_from_icache),

    // result
    .predicted_jump(predicted_jump),
    .predicted_target_pc(predicted_target_pc)
);

always @(posedge clk) begin
    if (rst == `TRUE) begin
        // internal pc
        pc <= `ZERO_ADDR;
        mem_pc <= `ZERO_ADDR;
        // status
        status <= STATUS_IDLE;
        // ena        
        ena_to_mc <= `FALSE;
        ena_to_icache <= `FALSE;
        addr_to_icache <= `ZERO_ADDR;
        inst_to_icache <= `ZERO_WORD;
        // to dcd & dsp
        pc_to_dsp <= `ZERO_ADDR;
        ok_flag_to_dsp <= `FALSE;
        inst_to_dcd <= `ZERO_WORD;
        // to mc
        pc_to_mc <= `ZERO_ADDR;
        drop_flag_to_mc <= `FALSE;
    end
    else if (commit_jump_flag_from_rob == `TRUE) begin
        ok_flag_to_dsp <= `FALSE;
        pc <= target_pc_from_rob;
        mem_pc <= target_pc_from_rob;
        status <= STATUS_IDLE;
        ena_to_mc <= `FALSE;
        ena_to_icache <= `FALSE;
        ok_flag_to_dsp <= `FALSE;
        drop_flag_to_mc <= `TRUE;
    end
    else begin
        cnt <= (cnt == wait_clock) ? 0 : cnt + 1;
        if (hit == `TRUE && global_full == `FALSE) begin
            // submit the inst to id
            pc_to_dsp <= pc;
            //pc <= (predicted_jump == `TRUE) ? predicted_target_pc : pc + `NEXT_PC;
            pc <= pc + `NEXT_PC;
            inst_to_dcd <= inst_from_icache;
            ok_flag_to_dsp <= `TRUE;
        end
        else begin
            ok_flag_to_dsp <= `FALSE;
        end

        drop_flag_to_mc <= `FALSE;
        ena_to_icache <= `FALSE;
        ena_to_mc <= `FALSE; // memctrl is woring now, so no duplicate request

        // if rdy and no components full, start working
        if (rdy == `TRUE) begin
            // fetcher is IDLE, request to memctrl
            if (status == STATUS_IDLE) begin
                ena_to_mc <= `TRUE;
                pc_to_mc <= mem_pc;
                status <= STATUS_FETCH;
            end
            else begin
                // memctrl ok
                if (ok_flag_from_mc == `TRUE) begin
                    // put into icache
                    ena_to_icache <= `TRUE;
                    addr_to_icache <= mem_pc;
                    mem_pc <= mem_pc + 4;
                    inst_to_icache <= inst_from_mc;
                    status <= STATUS_IDLE;
                end
            end
        end
    end
end

endmodule