`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

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
    input wire commit_jump_flag_from_rob
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

// debug
integer debug_ls_openum = -1;
integer debug_ls_addr = -1;
integer debug_ls_data = -1;

always @(posedge clk) begin
    if (rst) begin
        ena_to_mc <= `FALSE;
        valid <= `FALSE;
        status <= STATUS_IDLE;
    end
    else if (~rdy) begin
    end
    else begin
        if (status != STATUS_IDLE) begin
            ena_to_mc <= `FALSE;    
            if (commit_jump_flag_from_rob && status != STATUS_STORE) begin
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
            if (ena == `FALSE || openum == `OPENUM_NOP) begin
                ena_to_mc <= `FALSE;
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

endmodule