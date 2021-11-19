`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/id_unit/Decoder.v"

module Dispatcher(
    input wire clk,
    input wire rst,
    input wire rdy,

    // from fetcher
    input wire [`INS_TYPE] inst_from_if,
    input wire [`ADDR_TYPE] pc_from_if,
    input wire ok_flag_from_if,

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
    output wire [`REG_POS_TYPE] rd_to_rob,
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
    output wire [`REG_POS_TYPE] rd_to_reg,
    output wire [`ROB_ID_TYPE] Q_to_reg,

    // to rs
    output reg ena_to_rs,
    output wire [`OPENUM_TYPE] openum_to_rs,
    output wire [`DATA_TYPE] V1_to_rs,
    output wire [`DATA_TYPE] V2_to_rs,
    output wire [`ROB_ID_TYPE] Q1_to_rs,
    output wire [`ROB_ID_TYPE] Q2_to_rs,
    output reg [`ADDR_TYPE] pc_to_rs,
    output wire [`DATA_TYPE] imm_to_rs,
    output wire [`ROB_ID_TYPE] rob_id_to_rs,

    // to ls
    output reg ena_to_lsb,
    output wire [`OPENUM_TYPE] openum_to_lsb,
    output wire [`DATA_TYPE] V1_to_lsb,
    output wire [`DATA_TYPE] V2_to_lsb,
    output wire [`ROB_ID_TYPE] Q1_to_lsb,
    output wire [`ROB_ID_TYPE] Q2_to_lsb,
    output wire [`DATA_TYPE] imm_to_lsb,
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

// with decoder
reg [`INS_TYPE] inst_to_dcd;
wire [`OPENUM_TYPE] openum_from_dcd;
wire [`REG_POS_TYPE] rd_from_dcd;
wire [`REG_POS_TYPE] rs1_from_dcd;
wire [`REG_POS_TYPE] rs2_from_dcd;
wire [`DATA_TYPE] imm_from_dcd;

Decoder decoder (
    .inst(inst_to_dcd), 
    
    .openum(openum_from_dcd),
    .rd(rd_from_dcd),
    .rs1(rs1_from_dcd),
    .rs2(rs2_from_dcd),
    .imm(imm_from_dcd)
);

assign Q1_to_rob = Q1_from_reg;
assign Q2_to_rob = Q2_from_reg;

assign rs1_to_reg = rs1_from_dcd;
assign rs2_to_reg = rs2_from_dcd;

assign rd_to_reg = rd_from_dcd;
assign Q_to_reg = rob_id_from_rob;

assign rd_to_rob = rd_from_dcd;

assign rob_id_to_rs = rob_id_from_rob;
assign rob_id_to_lsb = rob_id_from_rob;

wire [`ROB_ID_TYPE] real_Q1 = (valid_from_rs_cdb && Q1_from_reg == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q1_from_reg == rob_id_from_ls_cdb) ? `ZERO_ROB : (Q1_ready_from_rob ? `ZERO_ROB : Q1_from_reg));
wire [`ROB_ID_TYPE] real_Q2 = (valid_from_rs_cdb && Q2_from_reg == rob_id_from_rs_cdb) ? `ZERO_ROB : ((valid_from_ls_cdb && Q2_from_reg == rob_id_from_ls_cdb) ? `ZERO_ROB :(Q2_ready_from_rob ? `ZERO_ROB : Q2_from_reg));
wire [`DATA_TYPE] real_V1 = (valid_from_rs_cdb && Q1_from_reg == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q1_from_reg == rob_id_from_ls_cdb) ? result_from_ls_cdb :(Q1_ready_from_rob ? ready_data1_from_rob : V1_from_reg));
wire [`DATA_TYPE] real_V2 = (valid_from_rs_cdb && Q2_from_reg == rob_id_from_rs_cdb) ? result_from_rs_cdb : ((valid_from_ls_cdb && Q2_from_reg == rob_id_from_ls_cdb) ? result_from_ls_cdb :(Q2_ready_from_rob ? ready_data2_from_rob : V2_from_reg));

assign openum_to_rs = openum_from_dcd;
assign V1_to_rs = real_V1;
assign V2_to_rs = real_V2;
assign Q1_to_rs = real_Q1;
assign Q2_to_rs = real_Q2;
assign imm_to_rs = imm_from_dcd;

assign openum_to_lsb = openum_from_dcd;
assign V1_to_lsb = real_V1;
assign V2_to_lsb = real_V2;
assign Q1_to_lsb = real_Q1;
assign Q2_to_lsb = real_Q2;
assign imm_to_lsb = imm_from_dcd;

always @(posedge clk) begin 
    // should pause
    if (rst == `TRUE || rdy == `FALSE || inst_from_if == `ZERO_WORD || 
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
            inst_to_dcd <= inst_from_if;

            // rob alloc
            ena_to_rob <= `TRUE;

             // reg alloc
            ena_to_reg <= `TRUE;

            // to ls
            if (inst_from_if[`OPCODE_RANGE] == `OPCODE_L || inst_from_if[`OPCODE_RANGE] == `OPCODE_S) begin
                ena_to_lsb <= `TRUE;
            end
            // to rs
            else begin
                ena_to_rs <= `TRUE;
                pc_to_rs <= pc_from_if;
            end
        end
    end    
end    

endmodule