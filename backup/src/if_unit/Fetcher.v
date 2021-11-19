`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // to decoder
    output reg [`INS_TYPE] inst_to_dsp,

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

reg [`STATUS_TYPE] status;

// pc reg
reg [`ADDR_TYPE] pc, mem_pc;

// predictor
wire predicted_jump;
wire [`ADDR_TYPE] predicted_target_pc;

// icache
integer i;

`define ICACHE_SIZE 64
`define INDEX_RANGE 7:2

reg valid [`ICACHE_SIZE - 1 : 0];
reg [`ADDR_TYPE] tag_store [`ICACHE_SIZE - 1 : 0];
reg [`INS_TYPE] data_store [`ICACHE_SIZE - 1 : 0];

wire hit = valid[pc[`INDEX_RANGE]] && (tag_store[pc[`INDEX_RANGE]] == pc);
wire [`INS_TYPE] returned_inst = (hit) ? data_store[pc[`INDEX_RANGE]] : `ZERO_WORD;

// stall for debug
integer cnt = 0;
parameter wait_clock = 8;

always @(posedge clk) begin
    if (rst) begin
        // internal pc
        pc <= `ZERO_ADDR;
        mem_pc <= `ZERO_ADDR;
        // status
        status <= STATUS_IDLE;
        // ena        
        ena_to_mc <= `FALSE;
        // to dsp
        pc_to_dsp <= `ZERO_ADDR;
        ok_flag_to_dsp <= `FALSE;
        inst_to_dsp <= `ZERO_WORD;
        // to mc
        pc_to_mc <= `ZERO_ADDR;
        drop_flag_to_mc <= `FALSE;
        // icache
        for (i = 0; i < `ICACHE_SIZE; i=i+1) begin
            valid[i] <= `FALSE;
            tag_store[i] <= `ZERO_ADDR;
            data_store[i] <= `ZERO_WORD;
        end
    end
    else if (~rdy) begin
    end
    else if (commit_jump_flag_from_rob) begin
        ok_flag_to_dsp <= `FALSE;
        pc <= target_pc_from_rob;
        mem_pc <= target_pc_from_rob;
        status <= STATUS_IDLE;
        ena_to_mc <= `FALSE;
        ok_flag_to_dsp <= `FALSE;
        drop_flag_to_mc <= `TRUE;
    end
    else begin
        cnt <= (cnt == wait_clock) ? 0 : cnt + 1;
        if (hit && global_full == `FALSE && (cnt == wait_clock - 1)) begin
            // submit the inst to id
            pc_to_dsp <= pc;
            //pc <= (predicted_jump) ? predicted_target_pc : pc + `NEXT_PC;
            pc <= pc + `NEXT_PC;
            inst_to_dsp <= returned_inst;
            ok_flag_to_dsp <= `TRUE;
        end
        else begin
            ok_flag_to_dsp <= `FALSE;
        end

        drop_flag_to_mc <= `FALSE;
        ena_to_mc <= `FALSE; // memctrl is woring now, so no duplicate request

        // if rdy and no components full, start working
        // fetcher is IDLE, request to memctrl
        if (status == STATUS_IDLE) begin
            ena_to_mc <= `TRUE;
            pc_to_mc <= mem_pc;
            status <= STATUS_FETCH;
        end
        else begin
            // memctrl ok
            if (ok_flag_from_mc) begin
                // put into icache
                mem_pc <= mem_pc + `NEXT_PC;
                status <= STATUS_IDLE;
                valid[mem_pc[`INDEX_RANGE]] <= `TRUE;
                tag_store[mem_pc[`INDEX_RANGE]] <= mem_pc;
                data_store[mem_pc[`INDEX_RANGE]] <= inst_from_mc;
            end
        end
    end
end

endmodule