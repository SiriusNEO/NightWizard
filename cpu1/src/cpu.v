// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/defines.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/if_unit/Fetcher.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/if_unit/Predictor.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/if_unit/InstQueue.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/id_unit/Dispatcher.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/ex_unit/RS.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/ex_unit/RS_EX.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/ex_unit/LSBuffer.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/ex_unit/LS_EX.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/pub_unit/MemCtrl.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/pub_unit/RegFile.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu1/src/pub_unit/ReOrderBuffer.v"

module cpu(
  input  wire                 clk_in,			// system clock signal
  input  wire                 rst_in,			// reset signal
	input  wire					        rdy_in,			// ready signal, pause cpu when low

  input  wire [ 7:0]          mem_din,		// data input bus
  output wire [ 7:0]          mem_dout,		// data output bus
  output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
  output wire                 mem_wr,			// write/read signal (1 for write)
	
	input  wire                 io_buffer_full, // 1 if uart buffer is full
	
	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

// fetcher and memctrl
wire [`ADDR_TYPE] pc_if_mc;
wire [`INS_TYPE] inst_mc_if;
wire ena_if_mc, ok_flag_mc_if, drop_flag_if_mc;

// fetcher and dispatcher
wire ok_flag_if_dsp;
wire [`INS_TYPE] inst_if_dsp;
wire [`ADDR_TYPE] pc_if_dsp;
wire [`ADDR_TYPE] rollback_pc_if_dsp;
wire predicted_jump_if_dsp;

/*
// fetcher and instqueue 
wire ok_flag_if_iq;
wire [`INS_TYPE] inst_if_iq;
wire [`ADDR_TYPE] pc_if_iq;
wire [`ADDR_TYPE] rollback_pc_if_iq;
wire predicted_jump_if_iq;

wire full_iq_if;

// instqueue and dispatcher
wire ok_flag_iq_dsp;
wire [`INS_TYPE] inst_iq_dsp;
wire [`ADDR_TYPE] pc_iq_dsp;
wire [`ADDR_TYPE] rollback_pc_iq_dsp;
wire predicted_jump_iq_dsp;
*/

// fetcher and predictor
wire [`ADDR_TYPE] query_pc_if_pdc;
wire [`INS_TYPE] query_inst_if_pdc;
wire predicted_jump_pdc_if;
wire [`ADDR_TYPE] predicted_imm_pdc_if;

// full signal to fetcher
wire full_rs, full_lsb, full_rob;
wire global_full = (full_rs || full_lsb || full_rob);

// dispatcher and rs
wire ena_dsp_rs;
wire [`OPENUM_TYPE] openum_dsp_rs;
wire [`DATA_TYPE] V1_dsp_rs;
wire [`DATA_TYPE] V2_dsp_rs;
wire [`ROB_ID_TYPE] Q1_dsp_rs;
wire [`ROB_ID_TYPE] Q2_dsp_rs;
wire [`ADDR_TYPE] pc_dsp_rs;
wire [`ADDR_TYPE] imm_dsp_rs;
wire [`ROB_ID_TYPE] rob_id_dsp_rs;

// dispatcher and lsbuffer
wire ena_dsp_lsb;
wire [`OPENUM_TYPE] openum_dsp_lsb;
wire [`DATA_TYPE] V1_dsp_lsb;
wire [`DATA_TYPE] V2_dsp_lsb;
wire [`ROB_ID_TYPE] Q1_dsp_lsb;
wire [`ROB_ID_TYPE] Q2_dsp_lsb;
wire [`ADDR_TYPE] imm_dsp_lsb;
wire [`ROB_ID_TYPE] rob_id_dsp_lsb;

// dispatcher and rob
wire ena_dsp_rob;

wire [`REG_POS_TYPE] rd_dsp_rob;
wire is_jump_dsp_rob;
wire is_store_dsp_rob;
wire is_branch_dsp_rob;
wire predicted_jump_dsp_rob;
wire [`ADDR_TYPE] pc_dsp_rob;
wire [`ADDR_TYPE] rollback_pc_dsp_rob;

wire [`ROB_ID_TYPE] rob_id_rob_dsp;

wire [`ROB_ID_TYPE] Q1_dsp_rob;
wire [`ROB_ID_TYPE] Q2_dsp_rob;
wire Q1_ready_rob_dsp;
wire Q2_ready_rob_dsp;
wire [`DATA_TYPE] ready_data1_rob_dsp;
wire [`DATA_TYPE] ready_data2_rob_dsp;

// dispatcher and regfile
wire [`REG_POS_TYPE] rs1_dsp_reg;
wire [`REG_POS_TYPE] rs2_dsp_reg;
wire [`DATA_TYPE] V1_reg_dsp;
wire [`DATA_TYPE] V2_reg_dsp;
wire [`ROB_ID_TYPE] Q1_reg_dsp;
wire [`ROB_ID_TYPE] Q2_reg_dsp;

wire ena_dsp_reg;
wire [`REG_POS_TYPE] rd_dsp_reg;
wire [`ROB_ID_TYPE] Q_dsp_reg;

// commit
wire commit_flag_bus;
wire rollback_flag_bus;

// rob to reg
wire [`REG_POS_TYPE] rd_rob_reg;
wire [`ROB_ID_TYPE] Q_rob_reg;
wire [`DATA_TYPE] V_rob_reg;

// rob to if
wire [`ADDR_TYPE] target_pc_rob_if;

// rob and lsb
wire [`ROB_ID_TYPE] rob_id_rob_lsb;
wire [`ROB_ID_TYPE] req_rob_id_lsb_rob;
wire [`ROB_ID_TYPE] io_rob_id_lsb_rob;
wire [`ROB_ID_TYPE] head_io_rob_id_rob_lsb;

// rob and predictor
wire ena_rob_pdc;
wire hit_rob_pdc;
wire [`ADDR_TYPE] pc_rob_pdc;

// rs and rs_ex
wire [`OPENUM_TYPE] openum_rs_ex1;
wire [`DATA_TYPE] V1_rs_ex1;
wire [`DATA_TYPE] V2_rs_ex1;
wire [`DATA_TYPE] imm_rs_ex1;
wire [`ADDR_TYPE] pc_rs_ex1;

wire [`OPENUM_TYPE] openum_rs_ex2;
wire [`DATA_TYPE] V1_rs_ex2;
wire [`DATA_TYPE] V2_rs_ex2;
wire [`DATA_TYPE] imm_rs_ex2;
wire [`ADDR_TYPE] pc_rs_ex2;

// ls and ls_ex
wire ena_ls_ex;
wire busy_ex_ls;
wire [`OPENUM_TYPE] openum_ls_ex;
wire [`ADDR_TYPE] mem_addr_ls_ex;
wire [`DATA_TYPE] store_value_ls_ex;

// ls_ex and memctrl
wire ena_ex_mc;
wire [`ADDR_TYPE] addr_ex_mc;
wire [`DATA_TYPE] data_ex_mc;
wire wr_flag_ex_mc;
wire [2: 0] size_ex_mc;
wire ok_flag_mc_ex;
wire [`DATA_TYPE] data_mc_ex;

// ls_ex and data_ram
wire ena_ex_ram1;
wire [`DATA_RAM_ADDR_RANGE] addr_ex_ram1;
wire [`DATA_TYPE] data_w_ex_ram1;
wire wr_flag_ex_ram1;

wire [`DATA_TYPE] data_r_ram1_ex;

// cdb
wire valid_rs_cdb1;
wire [`ROB_ID_TYPE] rob_id_rs_cdb1;
wire [`DATA_TYPE] result_rs_cdb1;
wire [`ADDR_TYPE] target_pc_rs_cdb1;
wire jump_flag_rs_cdb1;

wire valid_rs_cdb2;
wire [`ROB_ID_TYPE] rob_id_rs_cdb2;
wire [`DATA_TYPE] result_rs_cdb2;
wire [`ADDR_TYPE] target_pc_rs_cdb2;
wire jump_flag_rs_cdb2;

wire valid_ls_cdb;
wire [`ROB_ID_TYPE] rob_id_ls_cdb;
wire [`DATA_TYPE] result_ls_cdb; 

Fetcher fetcher (
  .clk(clk_in), 
  .rst(rst_in), 
  .rdy(rdy_in),

  // full signal
  .global_full(global_full),

  // with pdc
  .query_pc_to_pdc(query_pc_if_pdc),
  .query_inst_to_pdc(query_inst_if_pdc),
  .predicted_jump_from_pdc(predicted_jump_pdc_if),
  .predicted_imm_from_pdc(predicted_imm_pdc_if),

  // to dsp
  .inst_to_dsp(inst_if_dsp),
  .pc_to_dsp(pc_if_dsp), 
  .rollback_pc_to_dsp(rollback_pc_if_dsp),
  .predicted_jump_to_dsp(predicted_jump_if_dsp),
  .ok_flag_to_dsp(ok_flag_if_dsp),

  // port with memctrl
  // to memctrl
  .pc_to_mc(pc_if_mc), 
  .ena_to_mc(ena_if_mc), 
  .drop_flag_to_mc(drop_flag_if_mc),
  // from memctrl
  .ok_flag_from_mc(ok_flag_mc_if), 
  .inst_from_mc(inst_mc_if),

  // from rob
  .rollback_flag_from_rob(rollback_flag_bus), 
  .target_pc_from_rob(target_pc_rob_if)
);

/*
InstQueue instQueue (
    .clk(clk_in),
    .rst(rst_in),
    .rdy(rdy_in),

    .global_full(global_full),

    // fetcher
    .ok_flag_from_if(ok_flag_if_iq),
    .inst_from_if(inst_if_iq),
    .pc_from_if(pc_if_iq),
    .rollback_pc_from_if(rollback_pc_if_iq),
    .predicted_jump_from_if(predicted_jump_if_iq),

    // rollback
    .rollback_flag_from_rob(rollback_flag_bus),

    // full
    .full_to_if(full_iq_if),
    
    // to dsp
    .ok_flag_to_dsp(ok_flag_iq_dsp),
    .inst_to_dsp(inst_iq_dsp),
    .pc_to_dsp(pc_iq_dsp),
    .rollback_pc_to_dsp(rollback_pc_iq_dsp),
    .predicted_jump_to_dsp(predicted_jump_iq_dsp)
);
*/

Predictor predictor (
  .clk(clk_in), 
  .rst(rst_in),

  // query
  .query_pc(query_pc_if_pdc),
  .query_inst(query_inst_if_pdc),

  .predicted_jump(predicted_jump_pdc_if),
  .predicted_imm(predicted_imm_pdc_if),

  // update
  .ena_from_rob(ena_rob_pdc), 
  .hit_from_rob(hit_rob_pdc),
  .pc_from_rob(pc_rob_pdc)
);

Dispatcher dispatcher(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // from fetcher
  .inst_from_if(inst_if_dsp),
  .ok_flag_from_if(ok_flag_if_dsp),
  .pc_from_if(pc_if_dsp),
  .rollback_pc_from_if(rollback_pc_if_dsp),
  .predicted_jump_from_if(predicted_jump_if_dsp),

  // query Q1 Q2 ready in rob
  // to rob
  .Q1_to_rob(Q1_dsp_rob),
  .Q2_to_rob(Q2_dsp_rob),   
  // from rob
  .Q1_ready_from_rob(Q1_ready_rob_dsp),
  .Q2_ready_from_rob(Q2_ready_rob_dsp),
  .ready_data1_from_rob(ready_data1_rob_dsp),
  .ready_data2_from_rob(ready_data2_rob_dsp),

  // to rob
  .ena_to_rob(ena_dsp_rob),
  .rd_to_rob(rd_dsp_rob),
  .is_jump_to_rob(is_jump_dsp_rob),
  .is_store_to_rob(is_store_dsp_rob),
  .is_branch_to_rob(is_branch_dsp_rob),
  .predicted_jump_to_rob(predicted_jump_dsp_rob),
  .pc_to_rob(pc_dsp_rob),
  .rollback_pc_to_rob(rollback_pc_dsp_rob),
  // from rob
  .rob_id_from_rob(rob_id_rob_dsp),

  // to reg
  .rs1_to_reg(rs1_dsp_reg),
  .rs2_to_reg(rs2_dsp_reg), 
  // from reg
  .V1_from_reg(V1_reg_dsp),
  .V2_from_reg(V2_reg_dsp),
  .Q1_from_reg(Q1_reg_dsp),
  .Q2_from_reg(Q2_reg_dsp),

  // dsp alloc to reg
  .ena_to_reg(ena_dsp_reg),
  .rd_to_reg(rd_dsp_reg),
  .Q_to_reg(Q_dsp_reg),

  // to rs
  .ena_to_rs(ena_dsp_rs),
  .openum_to_rs(openum_dsp_rs),
  .V1_to_rs(V1_dsp_rs),
  .V2_to_rs(V2_dsp_rs),
  .Q1_to_rs(Q1_dsp_rs),
  .Q2_to_rs(Q2_dsp_rs),
  .pc_to_rs(pc_dsp_rs),
  .imm_to_rs(imm_dsp_rs),
  .rob_id_to_rs(rob_id_dsp_rs),

  // to ls
  .ena_to_lsb(ena_dsp_lsb),
  .openum_to_lsb(openum_dsp_lsb),
  .V1_to_lsb(V1_dsp_lsb),
  .V2_to_lsb(V2_dsp_lsb),
  .Q1_to_lsb(Q1_dsp_lsb),
  .Q2_to_lsb(Q2_dsp_lsb),
  .imm_to_lsb(imm_dsp_lsb),
  .rob_id_to_lsb(rob_id_dsp_lsb),

  // from rs cdb
  .valid_from_rs_cdb1(valid_rs_cdb1),
  .rob_id_from_rs_cdb1(rob_id_rs_cdb1),
  .result_from_rs_cdb1(result_rs_cdb1),

  .valid_from_rs_cdb2(valid_rs_cdb2),
  .rob_id_from_rs_cdb2(rob_id_rs_cdb2),
  .result_from_rs_cdb2(result_rs_cdb2),

  // from ls cdb
  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  // jump
  .rollback_flag_from_rob(rollback_flag_bus)
);

RS rs(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // from dsp
  .ena_from_dsp(ena_dsp_rs),
  .openum_from_dsp(openum_dsp_rs),
  .V1_from_dsp(V1_dsp_rs),
  .V2_from_dsp(V2_dsp_rs),
  .Q1_from_dsp(Q1_dsp_rs),
  .Q2_from_dsp(Q2_dsp_rs),
  .pc_from_dsp(pc_dsp_rs),
  .imm_from_dsp(imm_dsp_rs),
  .rob_id_from_dsp(rob_id_dsp_rs),

  .full_to_if(full_rs),
  
  // to ex1
  .openum_to_ex1(openum_rs_ex1),
  .V1_to_ex1(V1_rs_ex1),
  .V2_to_ex1(V2_rs_ex1),
  .pc_to_ex1(pc_rs_ex1),
  .imm_to_ex1(imm_rs_ex1),

  // to ex2
  .openum_to_ex2(openum_rs_ex2),
  .V1_to_ex2(V1_rs_ex2),
  .V2_to_ex2(V2_rs_ex2),
  .pc_to_ex2(pc_rs_ex2),
  .imm_to_ex2(imm_rs_ex2),

  // to cdb
  .rob_id_to_cdb1(rob_id_rs_cdb1),
  .rob_id_to_cdb2(rob_id_rs_cdb2),

  // from rs cdb
  .valid_from_rs_cdb1(valid_rs_cdb1),
  .rob_id_from_rs_cdb1(rob_id_rs_cdb1),
  .result_from_rs_cdb1(result_rs_cdb1),

  .valid_from_rs_cdb2(valid_rs_cdb2),
  .rob_id_from_rs_cdb2(rob_id_rs_cdb2),
  .result_from_rs_cdb2(result_rs_cdb2),

  // from ls cdb
  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  // jump_flag
  .rollback_flag_from_rob(rollback_flag_bus)
);

RS_EX rs_ex1(
  .openum(openum_rs_ex1),
  .V1(V1_rs_ex1),
  .V2(V2_rs_ex1),
  .imm(imm_rs_ex1),
  .pc(pc_rs_ex1),
  
  .result(result_rs_cdb1),
  .target_pc(target_pc_rs_cdb1),
  .jump_flag(jump_flag_rs_cdb1),
  .valid(valid_rs_cdb1)
);

RS_EX rs_ex2(
  .openum(openum_rs_ex2),
  .V1(V1_rs_ex2),
  .V2(V2_rs_ex2),
  .imm(imm_rs_ex2),
  .pc(pc_rs_ex2),
  
  .result(result_rs_cdb2),
  .target_pc(target_pc_rs_cdb2),
  .jump_flag(jump_flag_rs_cdb2),
  .valid(valid_rs_cdb2)
);

LSBuffer lsBuffer(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // from dsp
  .ena_from_dsp(ena_dsp_lsb),
  .openum_from_dsp(openum_dsp_lsb),
  .V1_from_dsp(V1_dsp_lsb),
  .V2_from_dsp(V2_dsp_lsb),
  .Q1_from_dsp(Q1_dsp_lsb),
  .Q2_from_dsp(Q2_dsp_lsb),
  .imm_from_dsp(imm_dsp_lsb),
  .rob_id_from_dsp(rob_id_dsp_lsb),
    
  // to if
  .full_to_if(full_lsb),

  // to ls ex
  .ena_to_ex(ena_ls_ex),
  .openum_to_ex(openum_ls_ex),
  .mem_addr_to_ex(mem_addr_ls_ex),
  .store_value_to_ex(store_value_ls_ex),
  // to cdb
  .rob_id_to_cdb(rob_id_ls_cdb),

  // from ls ex
  .busy_from_ex(busy_ex_ls),

  // to rob
  .io_rob_id_to_rob(io_rob_id_lsb_rob),

  // update when commit
  // from rob
  .commit_flag_from_rob(commit_flag_bus),
  .rob_id_from_rob(rob_id_rob_lsb),
  .head_io_rob_id_from_rob(head_io_rob_id_rob_lsb),

  // from rs cdb
  .valid_from_rs_cdb1(valid_rs_cdb1),
  .rob_id_from_rs_cdb1(rob_id_rs_cdb1),
  .result_from_rs_cdb1(result_rs_cdb1),

  .valid_from_rs_cdb2(valid_rs_cdb2),
  .rob_id_from_rs_cdb2(rob_id_rs_cdb2),
  .result_from_rs_cdb2(result_rs_cdb2),

  // from ls cdb
  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  .rollback_flag_from_rob(rollback_flag_bus)
);

LS_EX ls_ex(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .ena(ena_ls_ex),
  .openum(openum_ls_ex),
  .mem_addr(mem_addr_ls_ex),
  .store_value(store_value_ls_ex),

  // lsb
  .busy_to_lsb(busy_ex_ls),

  // port with mc
  .ena_to_mc(ena_ex_mc),

  .addr_to_mc(addr_ex_mc),
  .data_to_mc(data_ex_mc),
  .wr_flag_to_mc(wr_flag_ex_mc),
  .size_to_mc(size_ex_mc),
  
  .ok_flag_from_mc(ok_flag_mc_ex),
  .data_from_mc(data_mc_ex),

  // port with data_ram
  .ena_to_ram1(ena_ex_ram1),
    
  .addr_to_ram1(addr_ex_ram1),
  .data_w_to_ram1(data_w_ex_ram1),
  .wr_flag_to_ram1(wr_flag_ex_ram1),
    
  .data_r_from_ram1(data_r_ram1_ex),

  // to cdb
  .valid(valid_ls_cdb),
  .result(result_ls_cdb),

  //jump
  .rollback_flag_from_rob(rollback_flag_bus)
);

data_ram ram1 (
    .clk(clk_in),
    .rst(rst_in),
    .ena(ena_ex_ram1),
    .wr_flag(wr_flag_ex_ram1), 
    .addr_in(addr_ex_ram1),
    .data_in(data_w_ex_ram1),
    .data_out(data_r_ram1_ex)
);

ReOrderBuffer reOrderBuffer(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // reply to dsp_ready query
  // from dsp
  .Q1_from_dsp(Q1_dsp_rob),
  .Q2_from_dsp(Q2_dsp_rob),
  // to dsp
  .Q1_ready_to_dsp(Q1_ready_rob_dsp),
  .Q2_ready_to_dsp(Q2_ready_rob_dsp),
  .ready_data1_to_dsp(ready_data1_rob_dsp),
  .ready_data2_to_dsp(ready_data2_rob_dsp),

  // dsp allocate to rob
  // from dsp
  .ena_from_dsp(ena_dsp_rob),
  .is_jump_from_dsp(is_jump_dsp_rob),
  .is_store_from_dsp(is_store_dsp_rob),
  .is_branch_from_dsp(is_branch_dsp_rob),
  .rd_from_dsp(rd_dsp_rob),
  .predicted_jump_from_dsp(predicted_jump_dsp_rob),
  .pc_from_dsp(pc_dsp_rob),
  .rollback_pc_from_dsp(rollback_pc_dsp_rob),
  // to dsp
  .rob_id_to_dsp(rob_id_rob_dsp),

  // to if
  .full_to_if(full_rob),

  // update rob by cdb
  // from cdb
  .valid_from_rs_cdb1(valid_rs_cdb1),
  .rob_id_from_rs_cdb1(rob_id_rs_cdb1),
  .result_from_rs_cdb1(result_rs_cdb1),
  .target_pc_from_rs_cdb1(target_pc_rs_cdb1),
  .jump_flag_from_rs_cdb1(jump_flag_rs_cdb1),

  .valid_from_rs_cdb2(valid_rs_cdb2),
  .rob_id_from_rs_cdb2(rob_id_rs_cdb2),
  .result_from_rs_cdb2(result_rs_cdb2),
  .target_pc_from_rs_cdb2(target_pc_rs_cdb2),
  .jump_flag_from_rs_cdb2(jump_flag_rs_cdb2),

  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  // from lsb
  .io_rob_id_from_lsb(io_rob_id_lsb_rob),

  // commit
  .rollback_flag(rollback_flag_bus),
  // to reg
  .commit_flag(commit_flag_bus),
  .rd_to_reg(rd_rob_reg),
  .Q_to_reg(Q_rob_reg),
  .V_to_reg(V_rob_reg),
  // to if
  .target_pc_to_if(target_pc_rob_if),
  // to lsb
  .rob_id_to_lsb(rob_id_rob_lsb),
  // to predictor
  .ena_to_pdc(ena_rob_pdc),
  .pc_to_pdc(pc_rob_pdc),
  .hit_to_pdc(hit_rob_pdc),
  
  // io port singal to lsb
  .head_io_rob_id_to_lsb(head_io_rob_id_rob_lsb)
);

MemCtrl memCtrl(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  // with ram
  .uart_full_from_ram(io_buffer_full),
  .wr_flag_to_ram(mem_wr),

  .addr_to_ram(mem_a),
    
  .data_i_from_ram(mem_din),
  .data_o_to_ram(mem_dout),

  // with fetcher
  .pc_from_if(pc_if_mc),
  .ena_from_if(ena_if_mc),
  .drop_flag_from_if(drop_flag_if_mc),
  .ok_flag_to_if(ok_flag_mc_if),
  .inst_to_if(inst_mc_if),

  // with ls ex
  .addr_from_lsex(addr_ex_mc),
  .write_data_from_lsex(data_ex_mc),
  .ena_from_lsex(ena_ex_mc),
  .wr_flag_from_lsex(wr_flag_ex_mc),
  .size_from_lsex(size_ex_mc),
  .ok_flag_to_lsex(ok_flag_mc_ex),
  .load_data_to_lsex(data_mc_ex)
);

RegFile regFile(
  .clk(clk_in),
  .rst(rst_in),

  // from dsp
  .rs1_from_dsp(rs1_dsp_reg),
  .rs2_from_dsp(rs2_dsp_reg),

  // to dsp
  .V1_to_dsp(V1_reg_dsp),
  .V2_to_dsp(V2_reg_dsp),
  .Q1_to_dsp(Q1_reg_dsp),
  .Q2_to_dsp(Q2_reg_dsp),

  // dsp alloc to reg
  .ena_from_dsp(ena_dsp_reg),
  .rd_from_dsp(rd_dsp_reg),
  .Q_from_dsp(Q_dsp_reg),

  // commit from rob
  .commit_flag_from_rob(commit_flag_bus),
  .rollback_flag_from_rob(rollback_flag_bus),
  .rd_from_rob(rd_rob_reg),
  .Q_from_rob(Q_rob_reg),
  .V_from_rob(V_rob_reg)
);

endmodule