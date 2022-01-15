`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Fetcher(
    input wire clk,
    input wire rst,
    input wire rdy,
    
    // to decoder
    output reg [`INS_TYPE] inst_to_dsp,

    // full signal
    input wire global_full,
    
    // with pdc
    output wire [`ADDR_TYPE] query_pc_to_pdc,
    output wire [`INS_TYPE] query_inst_to_pdc,
    input wire predicted_jump_from_pdc,
    input wire [`ADDR_TYPE] predicted_imm_from_pdc,

    // to dsp
    output reg [`ADDR_TYPE] pc_to_dsp,
    output reg [`ADDR_TYPE] rollback_pc_to_dsp,
    output reg predicted_jump_to_dsp,
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
    input wire rollback_flag_from_rob,
    input wire [`ADDR_TYPE] target_pc_from_rob
);

parameter 
// fetcher status
STATUS_IDLE = 0,
STATUS_FETCH = 1;

reg [`STATUS_TYPE] status;

// pc reg
reg [`ADDR_TYPE] pc, mem_pc;

// index
integer i;

// direct mapped icache
`define ICACHE_SIZE 256
`define INDEX_RANGE 9:2
`define TAG_RANGE 31:10

reg valid [`ICACHE_SIZE - 1 : 0];
reg [`TAG_RANGE] tag_store [`ICACHE_SIZE - 1 : 0];
reg [`INS_TYPE] data_store [`ICACHE_SIZE - 1 : 0];

wire hit = valid[pc[`INDEX_RANGE]] && (tag_store[pc[`INDEX_RANGE]] == pc[`TAG_RANGE]);
wire [`INS_TYPE] returned_inst = (hit) ? data_store[pc[`INDEX_RANGE]] : `ZERO_WORD;

// predictor port
assign query_pc_to_pdc = pc;
assign query_inst_to_pdc = returned_inst;

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
    else if (rollback_flag_from_rob) begin
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
        if (hit && global_full == `FALSE) begin
            // submit the inst to id
            pc_to_dsp <= pc;
            predicted_jump_to_dsp <= predicted_jump_from_pdc;
            pc <= pc + (predicted_jump_from_pdc ? predicted_imm_from_pdc : `NEXT_PC);
            // for miss and not jump rollback
            rollback_pc_to_dsp <= pc + `NEXT_PC;
            // pc <= pc + `NEXT_PC;
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
                mem_pc <= ((mem_pc == pc) ? mem_pc + `NEXT_PC : pc);
                status <= STATUS_IDLE;
                valid[mem_pc[`INDEX_RANGE]] <= `TRUE;
                tag_store[mem_pc[`INDEX_RANGE]] <= mem_pc[`TAG_RANGE];
                data_store[mem_pc[`INDEX_RANGE]] <= inst_from_mc;
            end
        end
    end
end

endmodule