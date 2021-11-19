`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module ICache(
    input wire rst,

    // query
    input wire [`ADDR_TYPE] query_pc,
    output wire hit,
    output wire [`INS_TYPE] returned_inst,

    // put into icache
    input wire ena_from_if,
    input wire [`ADDR_TYPE] addr_from_if,
    input wire [`INS_TYPE] inst_from_if
);

// para
localparam ICACHE_SIZE = 256;
`define INDEX_RANGE 9:2
`define TAG_RANGE 31:10

// direct mapped icache
reg valid [ICACHE_SIZE - 1 : 0];
reg [`TAG_RANGE] tag_store [ICACHE_SIZE - 1 : 0];
reg [`INS_TYPE] data_store [ICACHE_SIZE - 1 : 0];

assign hit = valid[query_pc[`INDEX_RANGE]] && (tag_store[query_pc[`INDEX_RANGE]] == query_pc[`TAG_RANGE]);
assign returned_inst = (hit) ? data_store[query_pc[`INDEX_RANGE]] : `ZERO_WORD;

// index
integer i;

always @(negedge rst or posedge ena_from_if) begin
    if (~ena_from_if) begin
        for (i = 0; i < ICACHE_SIZE; i=i+1) begin
            valid[i] <= `FALSE;
            tag_store[i] <= `ZERO_ADDR;
            data_store[i] <= `ZERO_WORD;
        end
    end
    else begin
        valid[addr_from_if[`INDEX_RANGE]] <= `TRUE;
        tag_store[addr_from_if[`INDEX_RANGE]] <= addr_from_if[`TAG_RANGE];
        data_store[addr_from_if[`INDEX_RANGE]] <= inst_from_if;
    end
end

endmodule