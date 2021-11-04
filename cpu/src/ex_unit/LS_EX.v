`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module LS_EX (
    input wire clk,
    input wire rst,
    input wire ena,
    input wire [`OPENUM_LEN - 1 : 0] openum,
    input wire [`ADDR_LEN - 1 : 0] mem_addr,
    input wire [`DATA_LEN - 1 : 0] store_value,

    // lsb
    output wire busy_to_lsb,

    // port with mc
    output reg ena_to_mc,

    output reg [`ADDR_LEN - 1 : 0] addr_to_mc,
    output reg [`DATA_LEN - 1 : 0] data_to_mc,
    output reg wr_flag_to_mc,
    output reg [2: 0] size_to_mc,
    
    input wire ok_flag_from_mc,
    input wire [`DATA_LEN - 1 : 0] data_from_mc,

    // to cdb
    output reg valid,
    output reg [`DATA_LEN - 1 : 0] result
);

parameter 
STATUS_IDLE = 0,
STATUS_LOAD = 1,
STATUS_STORE = 2;

integer status;

assign busy_to_lsb = (status != STATUS_IDLE);

// debug
integer debug_sb_data = 0;
integer debug_sb_addr = -1;
integer debug_sb_cnt = -1;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        ena_to_mc = `FALSE;
        valid = `FALSE;
        status = STATUS_IDLE;
    end
    else begin
        if (status != STATUS_IDLE) begin
            ena_to_mc <= `FALSE;    
            if (ok_flag_from_mc == `TRUE) begin
                if (status == STATUS_LOAD) begin
                    valid <= `TRUE;
                    result <= data_from_mc;
                end
                status <= STATUS_IDLE;
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
                        status <= STATUS_LOAD;
                    end
                    `OPENUM_LH: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 2;
                        status <= STATUS_LOAD;
                    end 
                    `OPENUM_LW: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 4;
                        status <= STATUS_LOAD;
                    end 
                    `OPENUM_LBU: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 2;
                        status <= STATUS_LOAD;
                    end 
                    `OPENUM_LHU: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 4;
                        status <= STATUS_LOAD;
                    end 
                    `OPENUM_SB: begin
                        addr_to_mc <= mem_addr;
                        data_to_mc <= store_value;
                        wr_flag_to_mc <= `FLAG_WRITE;
                        size_to_mc <= 1;
                        status <= STATUS_STORE;
`ifdef DEBUG
                        debug_sb_cnt <= debug_sb_cnt + 1;
                        debug_sb_data <= data_to_mc;
                        debug_sb_addr <= mem_addr;
`endif
                        
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
            end
        end
    end
end

endmodule