`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from fetcher
    input wire [`ADDR_LEN - 1 : 0] pc_from_if,
    input wire ok_flag_from_if,

    // from decoder
    input wire [`OPENUM_LEN - 1 : 0] openum_from_dcd,
    input wire [`REG_LEN - 1 : 0] rd_from_dcd,
    input wire [`REG_LEN - 1 : 0] rs1_from_dcd,
    input wire [`REG_LEN - 1 : 0] rs2_from_dcd,
    input wire [`DATA_LEN - 1 : 0] imm_from_dcd,

    // query Q1 Q2 ready in rob
    // to rob
    output wire [`ROB_LEN : 0] Q1_to_rob,
    output wire [`ROB_LEN : 0] Q2_to_rob,   
    // from rob
    input wire Q1_ready_from_rob,
    input wire Q2_ready_from_rob,

    // rob alloc
    // to rob
    output reg ena_to_rob,
    output reg [`REG_LEN - 1 : 0] rd_to_rob,
    output reg [`DATA_LEN - 1 : 0] data_to_rob,
    output reg [`ADDR_LEN - 1 : 0] pc_to_rob,
    // from rob
    input wire [`ROB_LEN : 0] rob_id_from_rob,

    // query from reg
    // to reg
    output reg [`REG_LEN - 1 : 0] rs1_to_reg,
    output reg [`REG_LEN - 1 : 0] rs2_to_reg, 
    // from reg
    input wire [`DATA_LEN -1 : 0] V1_from_reg,
    input wire [`DATA_LEN -1 : 0] V2_from_reg,
    input wire [`ROB_LEN : 0] Q1_from_reg,
    input wire [`ROB_LEN : 0] Q2_from_reg,

    // reg alloc
    output reg ena_to_reg, 
    output reg [`REG_LEN - 1 : 0] rd_to_reg,
    output reg [`ROB_LEN : 0] Q_to_reg,

    // to rs
    output reg ena_to_rs,
    output reg [`OPENUM_LEN - 1 : 0] openum_to_rs,
    output reg [`DATA_LEN -1 : 0] V1_to_rs,
    output reg [`DATA_LEN -1 : 0] V2_to_rs,
    output reg [`ROB_LEN : 0] Q1_to_rs,
    output reg [`ROB_LEN : 0] Q2_to_rs,
    output reg [`ADDR_LEN -1 : 0] pc_to_rs,
    output reg [`ADDR_LEN -1 : 0] imm_to_rs,
    output reg [`ROB_LEN : 0] rob_id_to_rs,

    // to ls
    output reg ena_to_lsb,
    output reg [`OPENUM_LEN - 1 : 0] openum_to_lsb,
    output reg [`DATA_LEN -1 : 0] V1_to_lsb,
    output reg [`DATA_LEN -1 : 0] V2_to_lsb,
    output reg [`ROB_LEN : 0] Q1_to_lsb,
    output reg [`ROB_LEN : 0] Q2_to_lsb,
    output reg [`ADDR_LEN -1 : 0] imm_to_lsb,
    output reg [`ROB_LEN : 0] rob_id_to_lsb
);

reg dispatch_flag;

assign Q1_to_rob = Q1_from_reg;
assign Q2_to_rob = Q2_from_reg;

always @(posedge clk) begin
    if (rst == `TRUE) begin
        ena_to_rob <= `FALSE;
        ena_to_rs <= `FALSE;
        ena_to_lsb <= `FALSE;
        ena_to_reg <= `FALSE;
        dispatch_flag <= `FALSE;
    end    
    // should pause
    else if (rdy == `FALSE || openum_from_dcd == `OPENUM_NOP || (!ok_flag_from_if && !dispatch_flag)) begin
        ena_to_rob <= `FALSE;
        ena_to_rs <= `FALSE;
        ena_to_lsb <= `FALSE;
        ena_to_reg <= `FALSE;
    end
    else begin
        // data fetch
        if (ok_flag_from_if == `TRUE) begin
            // query reg
            rs1_to_reg <= rs1_from_dcd;
            rs2_to_reg <= rs2_from_dcd; 

            // rob alloc
            ena_to_rob <= `TRUE;
            rd_to_rob <= rd_from_dcd;
            data_to_rob <= `ZERO_WORD; // nothing now
            pc_to_rob <= pc_from_if;

            // dispatch enable
            dispatch_flag <= `TRUE;
        end
        // dispatch
        else if (dispatch_flag == `TRUE) begin
            dispatch_flag <= `FALSE;
            ena_to_rob <= `FALSE;

             // reg alloc
            ena_to_reg <= `TRUE;
            rd_to_reg <= rd_from_dcd;
            Q_to_reg <= rob_id_from_rob;

            // to ls
            if (openum_from_dcd >= `OPENUM_LB && openum_from_dcd <= `OPENUM_SW) begin
                ena_to_lsb <= `TRUE;
                openum_to_lsb <= openum_from_dcd;
                V1_to_lsb <= Q1_ready_from_rob ? V1_from_reg : `ZERO_WORD;
                V2_to_lsb <= Q2_ready_from_rob ? V2_from_reg : `ZERO_WORD;
                Q1_to_lsb <= Q1_from_reg;
                Q2_to_lsb <= Q2_from_reg;
                imm_to_lsb <= imm_from_dcd;
                rob_id_to_lsb <= rob_id_from_rob;
            end 
            // to rs
            else begin
                ena_to_rs <= `TRUE;
                openum_to_rs <= openum_from_dcd;
                V1_to_rs <= V1_from_reg;
                V2_to_rs <= V2_from_reg;
                Q1_to_rs <= Q1_from_reg;
                Q2_to_rs <= Q2_from_reg;
                pc_to_rs <= pc_from_if;
                imm_to_rs <= imm_from_dcd;
                rob_id_to_rs <= rob_id_from_rob;
            end
        end
    end    
end    

endmodule