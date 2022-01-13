`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

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

    // port with data_ram
    output reg ena_to_ram1,
    
    output reg [`DATA_RAM_ADDR_RANGE] addr_to_ram1,
    output reg [`DATA_TYPE] data_w_to_ram1,
    output reg wr_flag_to_ram1,
    
    input wire [`DATA_TYPE] data_r_from_ram1,

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
STATUS_STORE = 6,
STATUS_RAM1_STALL = 7;

reg [`STATUS_TYPE] status;
// ram1 status
reg ram1_working;

// bss data load first time through ram0
reg [2**(`DATA_RAM_ADDR_WIDTH-2)-1 : 0] not_in_bss;

assign busy_to_lsb = (status != STATUS_IDLE || ena);

// debug
integer debug_ls_openum = -1;
integer debug_ls_addr = -1;
integer debug_ls_data = -1;

// index
integer i;

always @(posedge clk) begin
    if (rst) begin
        ena_to_mc <= `FALSE;
        ena_to_ram1 <= `FALSE;
        valid <= `FALSE;
        status <= STATUS_IDLE;
        not_in_bss <= 0;
    end
    else if (~rdy) begin
    end
    else begin
        valid <= `FALSE;
        ena_to_mc <= `FALSE;
        ena_to_ram1 <= `FALSE;

        if (status != STATUS_IDLE) begin
            // rollback interrupt
            if (rollback_flag_from_rob && status != STATUS_STORE) begin
                status <= STATUS_IDLE;
            end
            else begin
                // ram1 finish
                if (ram1_working) begin
                    if (status == STATUS_RAM1_STALL) begin
                        status <= STATUS_LW;
                    end    
                    else begin
                        if (status != STATUS_STORE) begin
                            valid <= `TRUE;
                            case (status)
                                STATUS_LB: result <= {{25{data_r_from_ram1[7]}}, data_r_from_ram1[6:0]};
                                STATUS_LH: result <= {{17{data_r_from_ram1[15]}}, data_r_from_ram1[14:0]};
                                STATUS_LW: result <= data_r_from_ram1;
                                STATUS_LBU: result <= {24'b0, data_r_from_ram1[7:0]};
                                STATUS_LHU: result <= {16'b0, data_r_from_ram1[15:0]};
                            endcase
                        end
                        ram1_working <= `FALSE;
                        status <= STATUS_IDLE;
                    end
                end
                
                // memctrl finish
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
            if (ena == `FALSE || openum == `OPENUM_NOP) begin
                ram1_working <= `FALSE;
            end
            // use the origin ram
            // 1. I/O
            // 2. PROGRAM_END 
            // 3. B/H
            // 4. load in bss (!not in bss)
            else if (mem_addr == `RAM_IO_PORT 
                    || mem_addr == `PROGRAM_END
                    || (openum != `OPENUM_LW && openum != `OPENUM_SW) 
                    || (openum == `OPENUM_LW && ~not_in_bss[mem_addr[`DATA_RAM_INDEX_RANGE]]) ) begin
                ena_to_mc <= `TRUE;
                ram1_working <= `FALSE;

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
            end
            // LW/SW: use new ram
            // promise that lw/sw and lb/sb no conflict
            else begin
                ena_to_ram1 <= `TRUE;
                ram1_working <= `TRUE;

                case (openum)
                    `OPENUM_LW: begin
                        addr_to_ram1 <= mem_addr[`DATA_RAM_ADDR_RANGE];
                        wr_flag_to_ram1 <= `FLAG_READ;
                        status <= STATUS_RAM1_STALL;
                    end
                    `OPENUM_SW: begin
                        not_in_bss[mem_addr[`DATA_RAM_INDEX_RANGE]] <= 1;
                        addr_to_ram1 <= mem_addr[`DATA_RAM_ADDR_RANGE];
                        data_w_to_ram1 <= store_value;
                        wr_flag_to_ram1 <= `FLAG_WRITE;
                        status <= STATUS_STORE;
                    end
                endcase
            end
        end
    end
end

endmodule