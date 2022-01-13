/*******************************

    data_ram: seperated from instruction ram
    bandwidth: 32bit (for speeding)
    total cost: 2**14 * 32 bits = 2**16 bytes = 64KB

    notice: use [15:2] to index the ram

    input/output:
        clk:        clock
        wr_flag:    write/read flag (1 for write)
        addr_in:    addr pass to ram (read or write)
        data_in:    data written to ram
        data_out:   data read from ram
    
    
    By SiriusNEO

*******************************/

module data_ram 
#(
  parameter ADDR_WIDTH = 16,
  parameter DATA_WIDTH = 32
)

(
    input clk,
    input rst,
    input ena,
    input wr_flag, 
    input [ADDR_WIDTH-1 : 0] addr_in,
    input [DATA_WIDTH-1 : 0] data_in,
    output [DATA_WIDTH-1 : 0] data_out
);

wire bram_wr_flag;

single_port_ram_sync #(.ADDR_WIDTH(ADDR_WIDTH-2),
                       .DATA_WIDTH(DATA_WIDTH),
                       .IS_INST_RAM(1'b0)
                       ) bram(
  .clk(clk),
  .we(bram_wr_flag),
  .addr_a(addr_in[ADDR_WIDTH-1 : 2]),
  .din_a(data_in),
  .dout_a(data_out)
);

assign bram_wr_flag = (ena) ? wr_flag : 1'b0;

/*
always @(*) begin
    if (~wr_flag) begin
        data_out <= 32'h0;
        case (mode)
            2'b00: begin
                case (addr_in[1:0])
                    2'b00: data_out[7:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][7:0];
                    2'b01: data_out[7:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][15:8];
                    2'b10: data_out[7:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][23:16];
                    2'b11: data_out[7:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][31:24];
                endcase
            end
            2'b01: begin
                case (addr_in[1:0])
                    2'b00: data_out[15:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][15:0];
                    2'b10: data_out[15:0] <= ram[addr_in[ADDR_WIDTH-1 : 2]][31:16];
                endcase
            end
            2'b10: begin
                data_out <= ram[addr_in[ADDR_WIDTH-1 : 2]];
            end
        endcase
    end
end

always @(posedge clk) begin
    if (rst) begin
    end
    else if (ena) begin
        
        // ram write
        if (wr_flag) begin
            case (mode)
                2'b00: begin
                    case (addr_in[1:0])
                        2'b00: ram[addr_in[ADDR_WIDTH-1 : 2]][7:0] <= data_in[7:0];
                        2'b01: ram[addr_in[ADDR_WIDTH-1 : 2]][15:8] <= data_in[7:0];
                        2'b10: ram[addr_in[ADDR_WIDTH-1 : 2]][23:16] <= data_in[7:0];
                        2'b11: ram[addr_in[ADDR_WIDTH-1 : 2]][31:24] <= data_in[7:0];
                    endcase
                end
                2'b01: begin
                    case (addr_in[1:0])
                        2'b00: ram[addr_in[ADDR_WIDTH-1 : 2]][15:0] <= data_in[15:0];
                        2'b10: ram[addr_in[ADDR_WIDTH-1 : 2]][31:16] <= data_in[15:0];
                    endcase
                end
                2'b10: begin
                    ram[addr_in[ADDR_WIDTH-1 : 2]] <= data_in;
                end
            endcase
        end
    end
end
*/

endmodule