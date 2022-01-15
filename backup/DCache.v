`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

module LS_EX (
    input wire clk,
    input wire rst,
    input wire rdy,

    input wire ena,
    input wire [`OPENUM_TYPE] openum,
    input wire [`ADDR_TYPE] mem_addr,
    input wire [`DATA_TYPE] store_value,

    // lsb
    output wire busy_to_lsb,

    // port with mc
    output reg ena_to_mc,

    output reg [`ADDR_TYPE] addr_to_mc,
    output reg [`DATA_TYPE] data_to_mc,
    output reg wr_flag_to_mc,
    output reg [2: 0] size_to_mc,
    
    input wire ok_flag_from_mc,
    input wire [`DATA_TYPE] data_from_mc,

    // to cdb
    output reg valid,
    output reg [`DATA_TYPE] result,

    // jump
    input wire rollback_flag_from_rob
);

parameter 
STATUS_IDLE = 0,
STATUS_LB = 1,
STATUS_LH = 2,
STATUS_LW = 3,
STATUS_LBU = 4,
STATUS_LHU = 5,
STATUS_STORE = 6;

reg [`STATUS_TYPE] status;

assign busy_to_lsb = (status != STATUS_IDLE || ena);

// direct mapped dcache
`define DCACHE_SIZE 64
`define INDEX_RANGE 7:2
`define TAG_RANGE 31:8

reg cache_valid [`DCACHE_SIZE - 1 : 0];
reg [`TAG_RANGE] tag_store [`DCACHE_SIZE - 1 : 0];
reg [`DATA_TYPE] data_store [`DCACHE_SIZE - 1 : 0];

wire write_hit = (openum >= `OPENUM_SB && openum <= `OPENUM_SW) && ((cache_valid[mem_addr[`INDEX_RANGE]] == `FALSE) || (tag_store[mem_addr[`INDEX_RANGE]] == mem_addr[`TAG_RANGE]));
wire read_hit = (openum >= `OPENUM_LB && openum <= `OPENUM_LHU) && ((cache_valid[mem_addr[`INDEX_RANGE]] == `TRUE) && (tag_store[mem_addr[`INDEX_RANGE]] == mem_addr[`TAG_RANGE]));
wire [`DATA_TYPE] read_data = (read_hit ? data_store[mem_addr[`INDEX_RANGE]] : `ZERO_WORD);

// debug
integer debug_ls_openum = -1;
integer debug_ls_addr = -1;
integer debug_ls_data = -1;

// index
integer i;

always @(posedge clk) begin
    if (rst) begin
        ena_to_mc <= `FALSE;
        valid <= `FALSE;
        status <= STATUS_IDLE;
        // dcache
        for (i = 0; i < `DCACHE_SIZE; i=i+1) begin
            cache_valid[i] <= `FALSE;
            tag_store[i] <= `ZERO_ADDR;
            data_store[i] <= `ZERO_WORD;
        end
    end
    else if (~rdy) begin
    end
    else begin
        if (status != STATUS_IDLE) begin
            ena_to_mc <= `FALSE;    
            if (rollback_flag_from_rob && status != STATUS_STORE) begin
                status <= STATUS_IDLE;
            end
            else begin
                if (ok_flag_from_mc) begin
                    if (status != STATUS_STORE) begin
                        valid <= `TRUE;
                        case (status)
                            STATUS_LB: result <= {{25{data_from_mc[7]}}, data_from_mc[6:0]};
                            STATUS_LH: result <= {{17{data_from_mc[15]}}, data_from_mc[14:0]};
                            STATUS_LW: result <= data_from_mc;
                            STATUS_LBU: result <= {24'b0, data_from_mc[7:0]};
                            STATUS_LHU: result <= {16'b0, data_from_mc[15:0]};
                        endcase
                    end
                    status <= STATUS_IDLE;
                end
            end
        end
        else begin
            valid <= `FALSE;
            ena_to_mc <= `FALSE;
            if (ena == `FALSE || openum == `OPENUM_NOP) begin
            end
            else begin
                if (mem_addr != `RAM_IO_PORT && mem_addr != `PROGRAM_END && (write_hit || read_hit)) begin
                    if (write_hit) begin
                        cache_valid[mem_addr[`INDEX_RANGE]] <= `TRUE;
                        tag_store[mem_addr[`INDEX_RANGE]] <= mem_addr[`TAG_RANGE];
                        // data_store[mem_addr[`INDEX_RANGE]] <= store_value;
                        case (openum)
                            `OPENUM_SB: begin
                                case (mem_addr[1:0])
                                    2'b00: data_store[mem_addr[`INDEX_RANGE]][7:0] <= store_value[7:0];
                                    2'b01: data_store[mem_addr[`INDEX_RANGE]][15:8] <= store_value[7:0];
                                    2'b10: data_store[mem_addr[`INDEX_RANGE]][23:16] <= store_value[7:0];
                                    2'b11: data_store[mem_addr[`INDEX_RANGE]][31:24] <= store_value[7:0];
                                endcase
                            end
                            `OPENUM_SH: 
                                case (mem_addr[1:0])
                                    2'b00: data_store[mem_addr[`INDEX_RANGE]][15:0] <= store_value[15:0];
                                    2'b10: data_store[mem_addr[`INDEX_RANGE]][31:16] <= store_value[15:0];
                                endcase
                            // data_store[mem_addr[`INDEX_RANGE]][15:0] <= store_value[15:0];
                            `OPENUM_SW: data_store[mem_addr[`INDEX_RANGE]] <= store_value;
                        endcase
                    end
                    else if (read_hit) begin
                        valid <= `TRUE;
                        case (openum)
                            `OPENUM_LB: begin
                                case (mem_addr[1:0])
                                    2'b00: result <= {{25{read_data[7]}}, read_data[6:0]};
                                    2'b01: result <= {{25{read_data[15]}}, read_data[14:8]};
                                    2'b10: result <= {{25{read_data[23]}}, read_data[22:16]};
                                    2'b11: result <= {{25{read_data[31]}}, read_data[30:24]};
                                endcase
                            end
                            // result <= {{25{read_data[7]}}, read_data[6:0]};
                            `OPENUM_LH: 
                                case (mem_addr[1:0])
                                    2'b00: result <= {{17{read_data[15]}}, read_data[14:0]};
                                    2'b10: result <= {{17{read_data[31]}}, read_data[30:16]};
                                endcase
                            // result <= {{17{read_data[15]}}, read_data[14:0]};
                            `OPENUM_LW: result <= read_data;
                            `OPENUM_LBU: begin
                                case (mem_addr[1:0])
                                    2'b00: result <= {24'b0, read_data[7:0]};
                                    2'b01: result <= {24'b0, read_data[15:8]};
                                    2'b10: result <= {24'b0, read_data[23:16]};
                                    2'b11: result <= {24'b0, read_data[31:24]};
                                endcase
                            end
                            // result <= {24'b0, read_data[7:0]};
                            `OPENUM_LHU: 
                                case (mem_addr[1:0])
                                    2'b00: result <= {16'b0, read_data[15:0]};
                                    2'b10: result <= {16'b0, read_data[31:16]};
                                endcase
                            // result <= {16'b0, read_data[15:0]};
                        endcase
                    end
                end
                else begin
                    ena_to_mc <= `TRUE;
                    case (openum)
                        `OPENUM_LB: begin
                            addr_to_mc <= mem_addr;
                            wr_flag_to_mc <= `FLAG_READ;
                            size_to_mc <= 1;
                            status <= STATUS_LB;
                        end
                        `OPENUM_LH: begin
                            addr_to_mc <= mem_addr;
                            wr_flag_to_mc <= `FLAG_READ;
                            size_to_mc <= 2;
                            status <= STATUS_LH;
                        end 
                        `OPENUM_LW: begin
                            addr_to_mc <= mem_addr;
                            wr_flag_to_mc <= `FLAG_READ;
                            size_to_mc <= 4;
                            status <= STATUS_LW;
                        end 
                        `OPENUM_LBU: begin
                            addr_to_mc <= mem_addr;
                            wr_flag_to_mc <= `FLAG_READ;
                            size_to_mc <= 2;
                            status <= STATUS_LBU;
                        end 
                        `OPENUM_LHU: begin
                            addr_to_mc <= mem_addr;
                            wr_flag_to_mc <= `FLAG_READ;
                            size_to_mc <= 4;
                            status <= STATUS_LHU;
                        end 
                        `OPENUM_SB: begin
                            addr_to_mc <= mem_addr;
                            data_to_mc <= store_value;
                            wr_flag_to_mc <= `FLAG_WRITE;
                            size_to_mc <= 1;
                            status <= STATUS_STORE;
                        end 
                        `OPENUM_SH: begin
                            addr_to_mc <= mem_addr;
                            data_to_mc <= store_value;
                            wr_flag_to_mc <= `FLAG_WRITE;
                            size_to_mc <= 2;
                            status <= STATUS_STORE;
                        end 
                        `OPENUM_SW: begin
                            addr_to_mc <= mem_addr;
                            data_to_mc <= store_value;
                            wr_flag_to_mc <= `FLAG_WRITE;
                            size_to_mc <= 4;
                            status <= STATUS_STORE;
                        end
                    endcase
    `ifdef DEBUG
                        debug_ls_openum <= openum;
                        debug_ls_data <= store_value;
                        debug_ls_addr <= mem_addr;
    `endif
                end
            end
        end
    end
end

endmodule