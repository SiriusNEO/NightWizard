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
// memctrl status
STATUS_IDLE = 0,
STATUS_LOAD = 1,
STATUS_STORE = 2;

integer status;

assign busy_to_lsb = (status != STATUS_IDLE);

always @(posedge clk) begin
    if (rst == `TRUE) begin
        ena_to_mc = `FALSE;
        valid = `FALSE;
        status = STATUS_IDLE;
    end
    else begin
        if (status != STATUS_IDLE) begin
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
                    end
                    `OPENUM_LH: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 2;
                    end 
                    `OPENUM_LW: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 4;
                    end 
                    `OPENUM_LBU: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 2;
                    end 
                    `OPENUM_LHU: begin
                        addr_to_mc <= mem_addr;
                        wr_flag_to_mc <= `FLAG_READ;
                        size_to_mc <= 4;
                    end 
                    `OPENUM_SB: begin
                        addr_to_mc <= mem_addr;
                        data_to_mc <= store_value;
                        wr_flag_to_mc <= `FLAG_WRITE;
                        size_to_mc <= 1;
                    end 
                    `OPENUM_SH: begin
                        addr_to_mc <= mem_addr;
                        data_to_mc <= store_value;
                        wr_flag_to_mc <= `FLAG_WRITE;
                        size_to_mc <= 2;
                    end 
                    `OPENUM_SW: begin
                        addr_to_mc <= mem_addr;
                        data_to_mc <= store_value;
                        wr_flag_to_mc <= `FLAG_WRITE;
                        size_to_mc <= 4;
                    end
                endcase
            end
        end
    end
end

endmodule