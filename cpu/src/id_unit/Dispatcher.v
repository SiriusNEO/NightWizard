`include "C:/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

module Dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from fetcher
    input wire [`ADDR_TYPE] pc_from_if,
    input wire ok_flag_from_if,

    // from decoder
    input wire [`OPENUM_TYPE] openum_from_dcd,
    input wire [`REG_POS_TYPE] rd_from_dcd,
    input wire [`REG_POS_TYPE] rs1_from_dcd,
    input wire [`REG_POS_TYPE] rs2_from_dcd,
    input wire [`DATA_TYPE] imm_from_dcd,

    // query Q1 Q2 ready in rob
    // to rob
    output wire [`ROB_ID_TYPE] Q1_to_rob,
    output wire [`ROB_ID_TYPE] Q2_to_rob,   
    // from rob
    input wire Q1_ready_from_rob,
    input wire Q2_ready_from_rob,
    input wire [`DATA_TYPE] ready_data1_from_rob,
    input wire [`DATA_TYPE] ready_data2_from_rob,

    // rob alloc
    // to rob
    output reg ena_to_rob,
    output reg [`REG_POS_TYPE] rd_to_rob,
    // from rob
    input wire [`ROB_ID_TYPE] rob_id_from_rob,

    // query from reg
    // to reg
    output wire [`REG_POS_TYPE] rs1_to_reg,
    output wire [`REG_POS_TYPE] rs2_to_reg, 
    // from reg
    input wire [`DATA_TYPE] V1_from_reg,
    input wire [`DATA_TYPE] V2_from_reg,
    input wire [`ROB_ID_TYPE] Q1_from_reg,
    input wire [`ROB_ID_TYPE] Q2_from_reg,

    // reg alloc
    output reg ena_to_reg, 
    output reg [`REG_POS_TYPE] rd_to_reg,
    output wire [`ROB_ID_TYPE] Q_to_reg,

    // to rs
    output reg ena_to_rs,
    output reg [`OPENUM_TYPE] openum_to_rs,
    output reg [`DATA_TYPE] V1_to_rs,
    output reg [`DATA_TYPE] V2_to_rs,
    output reg [`ROB_ID_TYPE] Q1_to_rs,
    output reg [`ROB_ID_TYPE] Q2_to_rs,
    output reg [`ADDR_TYPE] pc_to_rs,
    output reg [`DATA_TYPE] imm_to_rs,
    output wire [`ROB_ID_TYPE] rob_id_to_rs,

    // to ls
    output reg ena_to_lsb,
    output reg [`OPENUM_TYPE] openum_to_lsb,
    output reg [`DATA_TYPE] V1_to_lsb,
    output reg [`DATA_TYPE] V2_to_lsb,
    output reg [`ROB_ID_TYPE] Q1_to_lsb,
    output reg [`ROB_ID_TYPE] Q2_to_lsb,
    output reg [`DATA_TYPE] imm_to_lsb,
    output wire [`ROB_ID_TYPE] rob_id_to_lsb,

    // from rs cdb
    input wire valid_from_rs_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_rs_cdb,
    input wire [`DATA_TYPE] result_from_rs_cdb,

    // from ls cdb
    input wire valid_from_ls_cdb,
    input wire [`ROB_ID_TYPE] rob_id_from_ls_cdb,
    input wire [`DATA_TYPE] result_from_ls_cdb,

    // jump
    input wire commit_jump_flag_from_rob
);

assign Q1_to_rob = Q1_from_reg;
assign Q2_to_rob = Q2_from_reg;

assign rs1_to_reg = rs1_from_dcd;
assign rs2_to_reg = rs2_from_dcd;

assign Q_to_reg = rob_id_from_rob;
assign rob_id_to_rs = rob_id_from_rob;
assign rob_id_to_lsb = rob_id_from_rob;

wire [`ROB_ID_TYPE] real_Q1 = (valid_from_rs_cdb && Q1_from_reg == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q1_from_reg == rob_id_from_ls_cdb) ? `ZERO_ROB : (Q1_ready_from_rob ? `ZERO_ROB : Q1_from_reg));
wire [`ROB_ID_TYPE] real_Q2 = (valid_from_rs_cdb && Q2_from_reg == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q2_from_reg == rob_id_from_ls_cdb) ? `ZERO_ROB :(Q2_ready_from_rob ? `ZERO_ROB : Q2_from_reg));
wire [`DATA_TYPE] real_V1 = (valid_from_rs_cdb && Q1_from_reg == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q1_from_reg == rob_id_from_ls_cdb) ? result_from_ls_cdb :(Q1_ready_from_rob ? ready_data1_from_rob : V1_from_reg));
wire [`DATA_TYPE] real_V2 = (valid_from_rs_cdb && Q2_from_reg == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q2_from_reg == rob_id_from_ls_cdb) ? result_from_ls_cdb :(Q2_ready_from_rob ? ready_data2_from_rob : V2_from_reg));

always @(posedge clk) begin 
    // should pause
    if (rst == `TRUE || rdy == `FALSE || openum_from_dcd == `OPENUM_NOP || 
    ok_flag_from_if == `FALSE || commit_jump_flag_from_rob == `TRUE) begin
        ena_to_rob <= `FALSE;
        ena_to_rs <= `FALSE;
        ena_to_lsb <= `FALSE;
        ena_to_reg <= `FALSE;
    end
    else if (~rdy) begin
    end
    else begin
        ena_to_rob <= `FALSE;
        ena_to_rs <= `FALSE;
        ena_to_lsb <= `FALSE;
        ena_to_reg <= `FALSE;

        if (ok_flag_from_if == `TRUE) begin   
            // rob alloc
            ena_to_rob <= `TRUE;
            rd_to_rob <= rd_from_dcd;

             // reg alloc
            ena_to_reg <= `TRUE;
            rd_to_reg <= rd_from_dcd;

            // to ls
            if (openum_from_dcd >= `OPENUM_LB && openum_from_dcd <= `OPENUM_SW) begin
                ena_to_lsb <= `TRUE;
                openum_to_lsb <= openum_from_dcd;
                Q1_to_lsb <= real_Q1;
                Q2_to_lsb <= real_Q2;
                V1_to_lsb <= real_V1;
                V2_to_lsb <= real_V2;
                imm_to_lsb <= imm_from_dcd;
            end 
            // to rs
            else begin
                ena_to_rs <= `TRUE;
                openum_to_rs <= openum_from_dcd;
                Q1_to_rs <= real_Q1;
                Q2_to_rs <= real_Q2;
                V1_to_rs <= real_V1;
                V2_to_rs <= real_V2;
                pc_to_rs <= pc_from_if;
                imm_to_rs <= imm_from_dcd;
            end
        end
    end    
end    

endmodule