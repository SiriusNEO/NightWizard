`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
module MemCtrl (
    input wire clk,
    input wire rst,
    input wire rdy,

    // port with ram
    input wire uart_full_from_ram,
    output reg wr_flag_to_ram,

    output reg [`ADDR_LEN - 1 : 0] addr_to_ram,

    input wire [`MEMPORT_LEN - 1 : 0] data_i_from_ram,
    output reg [`MEMPORT_LEN - 1 : 0] data_o_to_ram,

    // port with fetcher
    input wire [`ADDR_LEN - 1 : 0] pc_from_if,
    input wire ena_from_if,
    output reg ok_flag_to_if,
    output reg [`INS_LEN - 1 : 0] inst_to_if
);

integer status;
integer ram_access_counter, ram_access_stop;
reg [`ADDR_LEN - 1 : 0] ram_access_pc;

initial begin
    status = `STATUS_IDLE;
    ram_access_counter = 0;
    ram_access_stop = 0;
end

always @(posedge clk) begin
    ok_flag_to_if <= `FALSE;
    if (rst == `TRUE) begin
        status <= 0;
        ram_access_counter <= 0;
        ram_access_stop <= 0;
        ram_access_pc <= `ZERO_ADDR;
    end
    else if (status == `STATUS_IDLE) begin
        if (ena_from_if == `TRUE) begin
            ram_access_counter <= 0;
            ram_access_stop <= 4;
            addr_to_ram <= pc_from_if;
            ram_access_pc <= pc_from_if + 1;
            wr_flag_to_ram <= `FLAG_READ;
            status <= `STATUS_FETCH;
        end
    end
    else if (uart_full_from_ram == `FALSE) begin
        // ram access
        if (status == `STATUS_FETCH) begin
            // FETCH
            addr_to_ram <= ram_access_pc;
            wr_flag_to_ram <= `FLAG_READ;
            case (ram_access_counter)
                1:  inst_to_if[7:0] <= data_i_from_ram;
                2:  inst_to_if[15:8] <= data_i_from_ram;
                3:  inst_to_if[23:16] <= data_i_from_ram;
                4:  inst_to_if[31:24] <= data_i_from_ram;
            endcase
            ram_access_pc <= (ram_access_counter >= ram_access_stop - 1) ? `ZERO_ADDR : ram_access_pc + 1;
            ram_access_counter <= ram_access_counter + 1;

            if (ram_access_counter == ram_access_stop) begin
                ok_flag_to_if <= `TRUE;
                status <= `STATUS_IDLE;
                ram_access_pc <= `ZERO_ADDR;
                ram_access_counter <= 0;
            end
        end
    end
end

endmodule