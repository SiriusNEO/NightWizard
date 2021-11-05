// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/defines.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/if_unit/Fetcher.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/id_unit/Dispatcher.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/id_unit/Decoder.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/ex_unit/RS.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/ex_unit/RS_EX.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/ex_unit/LSBuffer.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/ex_unit/LS_EX.v"

`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/pub_unit/MemCtrl.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/pub_unit/RegFile.v"
`include "/mnt/c/Users/17138/Desktop/CPU/NightWizard/cpu/src/pub_unit/ReOrderBuffer.v"

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
wire [`ADDR_LEN - 1 : 0] pc_if_mc;
wire [`INS_LEN - 1 : 0] inst_mc_if;
wire ena_if_mc, ok_flag_mc_if, drop_flag_if_mc;

// fetcher and dispatcher
wire [`INS_LEN - 1 : 0] inst_if_dsp;
wire [`ADDR_LEN - 1 : 0] pc_if_dsp;
wire ok_flag_if_dsp;

// full signal to fetcher
wire full_rs_if, full_lsb_if, full_rob_if;

// fetcher and decoder
wire [`INS_LEN - 1 : 0] inst_if_dcd;

// dispatcher and decoder
wire [`OPENUM_LEN - 1 : 0] openum_dcd_dsp;
wire [`REG_LEN - 1 : 0] rd_dcd_dsp, rs1_dcd_dsp, rs2_dcd_dsp;
wire [`DATA_LEN - 1 : 0] imm_dcd_dsp;

// dispatcher and rs
wire ena_dsp_rs;
wire [`OPENUM_LEN - 1 : 0] openum_dsp_rs;
wire [`DATA_LEN -1 : 0] V1_dsp_rs;
wire [`DATA_LEN -1 : 0] V2_dsp_rs;
wire [`ROB_LEN : 0] Q1_dsp_rs;
wire [`ROB_LEN : 0] Q2_dsp_rs;
wire [`ADDR_LEN -1 : 0] pc_dsp_rs;
wire [`ADDR_LEN -1 : 0] imm_dsp_rs;
wire [`ROB_LEN : 0] rob_id_dsp_rs;

// dispatcher and lsbuffer
wire ena_dsp_lsb;
wire [`OPENUM_LEN - 1 : 0] openum_dsp_lsb;
wire [`DATA_LEN -1 : 0] V1_dsp_lsb;
wire [`DATA_LEN -1 : 0] V2_dsp_lsb;
wire [`ROB_LEN : 0] Q1_dsp_lsb;
wire [`ROB_LEN : 0] Q2_dsp_lsb;
wire [`ADDR_LEN -1 : 0] imm_dsp_lsb;
wire [`ROB_LEN : 0] rob_id_dsp_lsb;

// dispatcher and rob
wire ena_dsp_rob;
wire [`REG_LEN - 1 : 0] rd_dsp_rob;
wire [`DATA_LEN - 1 : 0] data_dsp_rob;
wire [`ADDR_LEN - 1 : 0] pc_dsp_rob;
wire [`ROB_LEN : 0] rob_id_rob_dsp;

wire [`ROB_LEN : 0] Q1_dsp_rob;
wire [`ROB_LEN : 0] Q2_dsp_rob;
wire Q1_ready_rob_dsp;
wire Q2_ready_rob_dsp;

// dispatcher and regfile
wire [`REG_LEN - 1 : 0] rs1_dsp_reg;
wire [`REG_LEN - 1 : 0] rs2_dsp_reg;
wire [`DATA_LEN -1 : 0] V1_reg_dsp;
wire [`DATA_LEN -1 : 0] V2_reg_dsp;
wire [`ROB_LEN : 0] Q1_reg_dsp;
wire [`ROB_LEN : 0] Q2_reg_dsp;

wire ena_dsp_reg;
wire [`REG_LEN - 1 : 0] rd_dsp_reg;
wire [`ROB_LEN : 0] Q_dsp_reg;

// commit
wire commit_flag_bus;
wire commit_jump_flag_bus;

// rob to reg
wire [`REG_LEN - 1 : 0] rd_rob_reg;
wire [`ROB_LEN : 0] Q_rob_reg;
wire [`DATA_LEN - 1 : 0] V_rob_reg;

// rob to if
wire [`ADDR_LEN - 1 : 0] target_pc_rob_if;

// rob and lsb
wire [`ROB_LEN : 0] rob_id_rob_lsb;

wire [`ROB_LEN : 0] store_rob_id_lsb_rob;

// rs and rs_ex
wire [`OPENUM_LEN - 1 : 0] openum_rs_ex;
wire [`DATA_LEN - 1 : 0] V1_rs_ex;
wire [`DATA_LEN - 1 : 0] V2_rs_ex;
wire [`DATA_LEN - 1 : 0] imm_rs_ex;
wire [`ADDR_LEN - 1 : 0] pc_rs_ex;

// ls and ls_ex
wire ena_ls_ex;
wire busy_ex_ls;
wire [`OPENUM_LEN - 1 : 0] openum_ls_ex;
wire [`ADDR_LEN - 1 : 0] mem_addr_ls_ex;
wire [`DATA_LEN - 1 : 0] store_value_ls_ex;

// ls_ex and memctrl
wire ena_ex_mc;
wire [`ADDR_LEN - 1 : 0] addr_ex_mc;
wire [`DATA_LEN - 1 : 0] data_ex_mc;
wire wr_flag_ex_mc;
wire [2: 0] size_ex_mc;
wire ok_flag_mc_ex;
wire [`DATA_LEN - 1 : 0] data_mc_ex;

// cdb
wire valid_rs_cdb;
wire [`ROB_LEN : 0] rob_id_rs_cdb;
wire [`DATA_LEN - 1 : 0] result_rs_cdb;
wire [`ADDR_LEN - 1 : 0] target_pc_rs_cdb;
wire jump_flag_rs_cdb;

wire valid_ls_cdb;
wire [`ROB_LEN : 0] rob_id_ls_cdb;
wire [`DATA_LEN - 1 : 0] result_ls_cdb;

Fetcher fetcher(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .inst_to_dcd(inst_if_dcd),

  .pc_to_mc(pc_if_mc),
  .ena_to_mc(ena_if_mc),
  .drop_flag_to_mc(drop_flag_if_mc),

  .ok_flag_from_mc(ok_flag_mc_if),
  .inst_from_mc(inst_mc_if),

  .pc_to_dsp(pc_if_dsp),
  .ok_flag_to_dsp(ok_flag_if_dsp),

  .full_from_rs(full_rs_if), .full_from_lsb(full_lsb_if), .full_from_rob(full_rob_if),

  .commit_flag_from_rob(commit_flag_bus),
  .commit_jump_flag_from_rob(commit_jump_flag_bus),
  .target_pc_from_rob(target_pc_rob_if)
);

Dispatcher dispatcher(
  .clk(clk_in),
  .rst(rst_in),
  .rdy(rdy_in),

  .ok_flag_from_if(ok_flag_if_dsp),
  .pc_from_if(pc_if_dsp),

  // decoder
  .openum_from_dcd(openum_dcd_dsp),
  .rd_from_dcd(rd_dcd_dsp),
  .rs1_from_dcd(rs1_dcd_dsp),
  .rs2_from_dcd(rs2_dcd_dsp),
  .imm_from_dcd(imm_dcd_dsp),

  // query Q1 Q2 ready in rob
  // to rob
  .Q1_to_rob(Q1_dsp_rob),
  .Q2_to_rob(Q2_dsp_rob),   
  // from rob
  .Q1_ready_from_rob(Q1_ready_rob_dsp),
  .Q2_ready_from_rob(Q2_ready_rob_dsp),

  // to rob
  .ena_to_rob(ena_dsp_rob),
  .rd_to_rob(rd_dsp_rob),
  .pc_to_rob(pc_dsp_rob),
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
  .rob_id_to_lsb(rob_id_dsp_lsb)
);

Decoder decoder(
  .ena(rdy_in),

  .inst(inst_if_dcd),

  .openum(openum_dcd_dsp),
  .rd(rd_dcd_dsp),
  .rs1(rs1_dcd_dsp),
  .rs2(rs2_dcd_dsp),
  .imm(imm_dcd_dsp)
);

RS rs(
  .clk(clk_in),
  .rst(rst_in),

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

  .full_to_if(full_rs_if),
  
  // to ex
  .openum_to_ex(openum_rs_ex),
  .V1_to_ex(V1_rs_ex),
  .V2_to_ex(V2_rs_ex),
  .pc_to_ex(pc_rs_ex),
  .imm_to_ex(imm_rs_ex),

  // to cdb
  .rob_id_to_cdb(rob_id_rs_cdb),

  // from rs cdb
  .valid_from_rs_cdb(valid_rs_cdb),
  .rob_id_from_rs_cdb(rob_id_rs_cdb),
  .result_from_rs_cdb(result_rs_cdb),

  // from ls cdb
  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  // jump_flag
  .commit_jump_flag_from_rob(commit_jump_flag_bus)
);

RS_EX rs_ex(
  .openum(openum_rs_ex),
  .V1(V1_rs_ex),
  .V2(V2_rs_ex),
  .imm(imm_rs_ex),
  .pc(pc_rs_ex),
  
  .result(result_rs_cdb),
  .target_pc(target_pc_rs_cdb),
  .jump_flag(jump_flag_rs_cdb),
  .valid(valid_rs_cdb)
);

LSBuffer lsBuffer(
  .clk(clk_in),
  .rst(rst_in),
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
  .full_to_if(full_lsb_if),

  // to ls ex
  .ena_to_ex(ena_ls_ex),
  .openum_to_ex(openum_ls_ex),
  .mem_addr_to_ex(mem_addr_ls_ex),
  .store_value_to_ex(store_value_ls_ex),
  // to cdb
  .rob_id_to_cdb(rob_id_ls_cdb),

  // from ls ex
  .busy_from_ex(busy_ex_ls),

  .store_rob_id_to_rob(store_rob_id_lsb_rob),

  // update when commit
  // from rob
  .commit_flag_from_rob(commit_flag_bus),
  .rob_id_from_rob(rob_id_rob_lsb),

  // from rs cdb
  .valid_from_rs_cdb(valid_rs_cdb),
  .rob_id_from_rs_cdb(rob_id_rs_cdb),
  .result_from_rs_cdb(result_rs_cdb),

  // from ls cdb
  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  .commit_jump_flag_from_rob(commit_jump_flag_bus)
);

LS_EX ls_ex(
  .clk(clk_in),
  .rst(rst_in),
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

  // to cdb
  .valid(valid_ls_cdb),
  .result(result_ls_cdb)
);

ReOrderBuffer reOrderBuffer(
  .clk(clk_in),
  .rst(rst_in),

  // reply to dsp_ready query
  // from dsp
  .Q1_from_dsp(Q1_dsp_rob),
  .Q2_from_dsp(Q2_dsp_rob),
  // to dsp
  .Q1_ready_to_dsp(Q1_ready_rob_dsp),
  .Q2_ready_to_dsp(Q2_ready_rob_dsp),

  // dsp allocate to rob
  // from dsp
  .ena_from_dsp(ena_dsp_rob),
  .rd_from_dsp(rd_dsp_rob),
  // to dsp
  .rob_id_to_dsp(rob_id_rob_dsp),

  // to if
  .full_to_if(full_rob_if),

  // update rob by cdb
  // from cdb
  .valid_from_rs_cdb(valid_rs_cdb),
  .rob_id_from_rs_cdb(rob_id_rs_cdb),
  .result_from_rs_cdb(result_rs_cdb),
  .target_pc_from_rs_cdb(target_pc_rs_cdb),
  .jump_flag_from_rs_cdb(jump_flag_rs_cdb),

  .valid_from_ls_cdb(valid_ls_cdb),
  .rob_id_from_ls_cdb(rob_id_ls_cdb),
  .result_from_ls_cdb(result_ls_cdb),

  // from lsb
  .store_rob_id_from_lsb(store_rob_id_lsb_rob),

  // commit
  .commit_jump_flag(commit_jump_flag_bus),
  // to reg
  .commit_flag(commit_flag_bus),
  .rd_to_reg(rd_rob_reg),
  .Q_to_reg(Q_rob_reg),
  .V_to_reg(V_rob_reg),
  // to if
  .target_pc_to_if(target_pc_rob_if),
  // to lsb
  .rob_id_to_lsb(rob_id_rob_lsb)
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
  .rd_from_rob(rd_rob_reg),
  .Q_from_rob(Q_rob_reg),
  .V_from_rob(V_rob_reg)
);

endmodule