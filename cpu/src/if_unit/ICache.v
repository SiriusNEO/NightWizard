`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

// para
`define ICACHE_SIZE 512
`define ICACHE_BITLEN 9
`define INDEX_RANGE 10:2

module ICache(
    // query
    input wire [`ADDR_TYPE] query_pc,
    output wire hit,
    output wire [`INS_TYPE] returned_inst,

    // put into icache
    input wire ena_from_if,
    input wire [`ADDR_TYPE] addr_from_if,
    input wire [`INS_TYPE] inst_from_if
);

// use total 32bit as the tag

reg valid [`ICACHE_SIZE - 1 : 0];
reg [`ADDR_TYPE] tag_store [`ICACHE_SIZE - 1 : 0];
reg [`INS_TYPE] data_store [`ICACHE_SIZE - 1 : 0];

wire [`ICACHE_BITLEN - 1 : 0] index = query_pc[`INDEX_RANGE];
assign hit = (valid[index] == `TRUE) && (tag_store[index] == query_pc);
assign returned_inst = (hit) ? data_store[index] : `ZERO_WORD;

// debug

reg [`ADDR_TYPE] dbg_tag_store;
reg [`INS_TYPE] dbg_data_store;

always @(posedge ena_from_if) begin
    valid[addr_from_if[`INDEX_RANGE]] = `TRUE;
    tag_store[addr_from_if[`INDEX_RANGE]] = addr_from_if;
    data_store[addr_from_if[`INDEX_RANGE]] = inst_from_if;

    dbg_tag_store = tag_store[addr_from_if[`INDEX_RANGE]];
    dbg_data_store = data_store[addr_from_if[`INDEX_RANGE]];
end

endmodule