`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module MemCtrl (
    input wire clk,
    input wire rst,
    input wire rdy,

    // port with ram
    input wire uart_full_from_ram,
    output reg wr_flag_to_ram,

    output reg [`ADDR_TYPE] addr_to_ram,

    input wire [`MEMPORT_TYPE] data_i_from_ram,
    output reg [`MEMPORT_TYPE] data_o_to_ram,

    // port with fetcher
    input wire [`ADDR_TYPE] pc_from_if,
    input wire ena_from_if,
    input wire drop_flag_from_if,
    output reg ok_flag_to_if,
    output reg [`INS_TYPE] inst_to_if,

    // port with ls_ex
    input wire [`ADDR_TYPE] addr_from_lsex,
    input wire [`DATA_TYPE] write_data_from_lsex,
    input wire ena_from_lsex,
    input wire wr_flag_from_lsex,
    input wire [2: 0] size_from_lsex,
    output reg ok_flag_to_lsex,
    output reg [`DATA_TYPE] load_data_to_lsex
);

// memctrl status
parameter 
STATUS_IDLE = 0,
STATUS_FETCH = 1,
STATUS_LOAD = 2,
STATUS_STORE = 3;

// bufferred request
// because fetch and lsbuffer are sequential, buffer 1 request
reg buffered_fetch_valid;
reg [`ADDR_TYPE] buffered_pc;

reg buffered_ls_valid;
reg buffered_wr_flag;
reg [2: 0] buffered_size;
reg [`ADDR_TYPE] buffered_addr;
reg [`ADDR_TYPE] buffered_write_data;

// working status para
integer status;
integer ram_access_counter, ram_access_stop;
reg [`ADDR_TYPE] ram_access_pc;
reg [`DATA_TYPE] writing_data;

always @(posedge drop_flag_from_if) begin
    if (status == STATUS_FETCH || status == STATUS_LOAD) begin
        status <= STATUS_IDLE;
        ram_access_pc <= `ZERO_ADDR;
        ram_access_counter <= 0;
    end
    buffered_fetch_valid <= `FALSE;
    if (buffered_ls_valid == `TRUE && buffered_wr_flag == `FLAG_READ)
        buffered_ls_valid <= `FALSE;
end

always @(posedge clk) begin
    if (rst == `TRUE) begin
        status <= STATUS_IDLE;
        ram_access_counter <= 0;
        ram_access_stop <= 0;
        ram_access_pc <= `ZERO_ADDR;
        buffered_fetch_valid <= `FALSE;
        buffered_ls_valid <= `FALSE;
        inst_to_if <= `ZERO_ADDR;
        load_data_to_lsex <= `ZERO_WORD;
    end
    else if (rdy == `TRUE) begin
        if (status != STATUS_IDLE || (ena_from_lsex && ena_from_if)) begin
            // memctrl is busy, so bufferred the query
            if (ena_from_if == `FALSE && ena_from_lsex == `TRUE) begin
                buffered_ls_valid <= `TRUE;
                buffered_wr_flag <= wr_flag_from_lsex;
                buffered_addr <= addr_from_lsex;
                buffered_write_data <= write_data_from_lsex;
                buffered_size <= size_from_lsex;
            end
            else if (ena_from_if == `TRUE) begin
                buffered_fetch_valid <= `TRUE;
                buffered_pc <= pc_from_if;
            end
        end

        if (status == STATUS_IDLE) begin 
            // idle, clear work cookie
            ok_flag_to_if <= `FALSE;
            ok_flag_to_lsex <= `FALSE;
            inst_to_if <= `ZERO_ADDR;
            load_data_to_lsex <= `ZERO_WORD;

            // idle
            if (ena_from_lsex == `TRUE) begin
                if (wr_flag_from_lsex == `FLAG_WRITE) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsex;
                    writing_data <= write_data_from_lsex;
                    addr_to_ram <= `ZERO_ADDR;
                    ram_access_pc <= addr_from_lsex;
                    wr_flag_to_ram <= `FLAG_WRITE;
                    status <= STATUS_STORE;
                end
                else if (wr_flag_from_lsex == `FLAG_READ) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= size_from_lsex;
                    addr_to_ram <= addr_from_lsex;
                    ram_access_pc <= addr_from_lsex + 1;
                    wr_flag_to_ram <= `FLAG_READ;
                    status <= STATUS_LOAD;
                end
            end
            // if there is buffered request
            else if (buffered_ls_valid == `TRUE) begin
                if (buffered_wr_flag == `FLAG_WRITE) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffered_size;
                    writing_data <= buffered_write_data;
                    addr_to_ram <= `ZERO_ADDR;
                    ram_access_pc <= buffered_addr;
                    wr_flag_to_ram <= `FLAG_WRITE;
                    status <= STATUS_STORE;
                end    
                else if (buffered_wr_flag == `FLAG_READ) begin
                    ram_access_counter <= 0;
                    ram_access_stop <= buffered_size;
                    addr_to_ram <= buffered_addr;
                    ram_access_pc <= buffered_addr + 1;
                    wr_flag_to_ram <= `FLAG_READ;
                    status <= STATUS_LOAD;
                end
                buffered_ls_valid <= `FALSE;
            end
            else if (ena_from_if == `TRUE) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= pc_from_if;
                ram_access_pc <= pc_from_if + 1;
                wr_flag_to_ram <= `FLAG_READ;
                status <= STATUS_FETCH;
            end
            else if (buffered_fetch_valid == `TRUE) begin
                ram_access_counter <= 0;
                ram_access_stop <= 4;
                addr_to_ram <= buffered_pc;
                ram_access_pc <= buffered_pc + 1;
                wr_flag_to_ram <= `FLAG_READ;
                status <= STATUS_FETCH;
                buffered_fetch_valid <= `FALSE;
            end
        end
        // busy
        else begin
            // work
            if (uart_full_from_ram == `FALSE) begin
                if (status == STATUS_FETCH) begin
                    // fetch inst
                    addr_to_ram <= ram_access_pc;
                    wr_flag_to_ram <= `FLAG_READ;
                    case (ram_access_counter)
                        1:  inst_to_if[7:0] <= data_i_from_ram;
                        2:  inst_to_if[15:8] <= data_i_from_ram;
                        3:  inst_to_if[23:16] <= data_i_from_ram;
                        4:  inst_to_if[31:24] <= data_i_from_ram;
                    endcase
                    ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? `ZERO_ADDR : ram_access_pc + 1;
                    // stop
                    if (ram_access_counter == ram_access_stop) begin
                        ok_flag_to_if <= `TRUE;
                        status <= STATUS_IDLE;
                        ram_access_pc <= `ZERO_ADDR;
                        ram_access_counter <= 0;
                    end
                    else begin
                        ram_access_counter <= ram_access_counter + 1;
                    end
                end
                else if (status == STATUS_LOAD) begin
                    // load
                    addr_to_ram <= ram_access_pc;
                    wr_flag_to_ram <= `FLAG_READ;
                    case (ram_access_counter)
                        1:  load_data_to_lsex[7:0] <= data_i_from_ram;
                        2:  load_data_to_lsex[15:8] <= data_i_from_ram;
                        3:  load_data_to_lsex[23:16] <= data_i_from_ram;
                        4:  load_data_to_lsex[31:24] <= data_i_from_ram;
                    endcase
                    ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? `ZERO_ADDR : ram_access_pc + 1;

                    if (ram_access_counter == ram_access_stop) begin
                        ok_flag_to_lsex <= `TRUE;
                        status <= STATUS_IDLE;
                        ram_access_pc <= `ZERO_ADDR;
                        ram_access_counter <= 0;
                    end
                    else begin
                        ram_access_counter <= ram_access_counter + 1;
                    end
                end
                else if (status == STATUS_STORE) begin
                    //store
                    addr_to_ram <= ram_access_pc;
                    wr_flag_to_ram <= `FLAG_WRITE;
                    case (ram_access_counter)
                        0:  data_o_to_ram <= writing_data[7:0];
                        1:  data_o_to_ram <= writing_data[15:8];
                        2:  data_o_to_ram <= writing_data[23:16];
                        3:  data_o_to_ram <= writing_data[31:24];
                    endcase
                    ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? `ZERO_ADDR : ram_access_pc + 1;

                    if (ram_access_counter == ram_access_stop) begin
                        ok_flag_to_lsex <= `TRUE;
                        status <= STATUS_IDLE;
                        ram_access_pc <= `ZERO_ADDR;
                        ram_access_counter <= 0;
                        addr_to_ram <= `ZERO_ADDR;
                        wr_flag_to_ram <= `FLAG_READ;
                    end
                    else  begin
                        ram_access_counter <= ram_access_counter + 1;
                    end
                end
            end
        end
    end
    else begin
        ok_flag_to_if <= `FALSE;
        ok_flag_to_lsex <= `FALSE;
    end
end

endmodule