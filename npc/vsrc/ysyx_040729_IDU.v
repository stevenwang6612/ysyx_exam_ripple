module ysyx_040729_IDU #(
    parameter DATA_WIDTH = 64,
    parameter ADDR_WIDTH = 64,
    parameter INST_WIDTH = 32,
    parameter REG_ADDR_W = 5
)(
  input  clock,
  input  reset,

  input  [INST_WIDTH-1:0] instruction_i,
  input  [ADDR_WIDTH-1:0] pc_i,

  input  system_jump_i,
  input  [ADDR_WIDTH-1:0] system_jump_entry_i,
  input  rf_we_i,
  input  [REG_ADDR_W-1:0] rf_waddr_i,
  input  [DATA_WIDTH-1:0] rf_wdata_i,

  input                   rf_we_exe_i,
  input                   rf_we_mem_i,
  input  [2:0]            rf_wdata_src_exe_i,
  input  [2:0]            rf_wdata_src_mem_i,
  input  [REG_ADDR_W-1:0] dst_addr_exe_i,
  input  [REG_ADDR_W-1:0] dst_addr_mem_i,
  input  [DATA_WIDTH-1:0] ALU_result_exe_i,
  input  [DATA_WIDTH-1:0] immediate_exe_i,
  input  [DATA_WIDTH-1:0] pc_exe_i,
  input  [DATA_WIDTH-1:0] ALU_result_mem_i,
  input  [DATA_WIDTH-1:0] immediate_mem_i,
  input  [DATA_WIDTH-1:0] pc_mem_i,
  
  output                  mem_hazard_o,

  output rf_we_o,
  output [REG_ADDR_W-1:0] rf_waddr_o,
  output [DATA_WIDTH-1:0] rf_rdata1_o,
  output [DATA_WIDTH-1:0] rf_rdata2_o,
  output mem_wen_o,
  output alu_src2_ri_o,
  output alu_len_dw_o,
  output ecall_o,
  output mret_o,
  output csr_enable_o,
  output [2:0] rf_wdata_src_o,
  output [DATA_WIDTH-1:0] immediate_o,
  output [ADDR_WIDTH-1:0] npc,
  output [ADDR_WIDTH-1:0] pc_next_o
);

//Decoder
wire [1:0] npc_src;
ysyx_040729_IDU_Decoder #(32, 64) Decoder_inst(
  .instruction  (instruction_i),
  .ecall        (ecall_o),
  .mret         (mret_o),
  .csr_enable   (csr_enable_o),
  .rf_we        (rf_we_o),
  .rf_wdata_src (rf_wdata_src_o),
  .npc_src      (npc_src),
  .alu_len_dw   (alu_len_dw_o),
  .mem_wen      (mem_wen_o),
  .alu_src2_ri  (alu_src2_ri_o),
  .immediate    (immediate_o)
);


//RegFile
wire [REG_ADDR_W-1:0] rf_raddr1, rf_raddr2;
wire [DATA_WIDTH-1:0] rf_rdata1, rf_rdata2;
ysyx_040729_IDU_RegisterFile #(32, DATA_WIDTH) RF_inst (
  .clock    (clock),
  .reset    (reset),
  .wen      (rf_we_i),
  .waddr    (rf_waddr_i),
  .wdata    (rf_wdata_i),
  .raddr1   (rf_raddr1),
  .rdata1   (rf_rdata1),
  .raddr2   (rf_raddr2),
  .rdata2   (rf_rdata2)
);
assign rf_raddr1  = instruction_i[19:15];
assign rf_raddr2  = instruction_i[24:20];
assign rf_waddr_o = instruction_i[11:7];

//forward
wire                  rf_we_exe    = rf_we_exe_i;
wire                  rf_we_mem    = rf_we_mem_i;
wire [REG_ADDR_W-1:0] dst_addr_exe = dst_addr_exe_i;
wire [REG_ADDR_W-1:0] dst_addr_mem = dst_addr_mem_i;
wire [DATA_WIDTH-1:0] rf_wdata_exe = ({DATA_WIDTH{rf_wdata_src_exe_i == 3'b000}} & (ALU_result_exe_i  )) |
                                     ({DATA_WIDTH{rf_wdata_src_exe_i == 3'b010}} & (immediate_exe_i   )) |
                                     ({DATA_WIDTH{rf_wdata_src_exe_i == 3'b100}} & (pc_exe_i + immediate_exe_i)) |
                                     ({DATA_WIDTH{rf_wdata_src_exe_i == 3'b101}} & (pc_exe_i + 64'd4  ));
wire [DATA_WIDTH-1:0] rf_wdata_mem = ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b000}} & (ALU_result_mem_i  )) |
                                     ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b010}} & (immediate_mem_i   )) |
                                     ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b100}} & (pc_mem_i + immediate_mem_i)) |
                                     ({DATA_WIDTH{rf_wdata_src_mem_i == 3'b101}} & (pc_mem_i + 64'd4  ));
wire src1_forward_exe = (|rf_raddr1) & (rf_raddr1==dst_addr_exe) & rf_we_exe;
wire src1_forward_mem = (|rf_raddr1) & (rf_raddr1==dst_addr_mem) & rf_we_mem;
wire src2_forward_exe = (|rf_raddr2) & (rf_raddr2==dst_addr_exe) & rf_we_exe;
wire src2_forward_mem = (|rf_raddr2) & (rf_raddr2==dst_addr_mem) & rf_we_mem;

assign rf_rdata1_o = src1_forward_exe ? rf_wdata_exe : src1_forward_mem ? rf_wdata_mem : rf_rdata1;
assign rf_rdata2_o = src2_forward_exe ? rf_wdata_exe : src2_forward_mem ? rf_wdata_mem : rf_rdata2;


assign mem_hazard_o = (rf_wdata_src_mem_i==3'b001 | rf_wdata_src_exe_i==3'b001) &
                      (npc_src[1] | (csr_enable_o&~instruction_i[14])) & //branch or csrw
                      (src1_forward_mem | src2_forward_mem | src1_forward_exe | src2_forward_exe);

//npc
wire [DATA_WIDTH-1:0] snpc, dnpc, rnpc, bnpc;
wire branch_switch;
wire [DATA_WIDTH:0] sub_result = rf_rdata1_o - rf_rdata2_o;
MuxKey #(6, 3, 1) mux_branch (
  branch_switch,
  instruction_i[14:12], {
    3'b000, !(|sub_result),              //beq 
    3'b001, |sub_result,                 //bne
    3'b100, sub_result[DATA_WIDTH-1],    //blt
    3'b101, !sub_result[DATA_WIDTH-1],   //bge
    3'b110, sub_result[DATA_WIDTH],      //bltu
    3'b111, !sub_result[DATA_WIDTH]}     //bgeu
);
assign snpc = pc_i + 4;
assign dnpc = pc_i + immediate_o;
assign rnpc = rf_rdata1_o + immediate_o;
assign bnpc = branch_switch ? dnpc : snpc;
assign pc_next_o =  system_jump_i ? system_jump_entry_i : npc;
assign npc =  ({DATA_WIDTH{npc_src == 2'b00}} & snpc) |
              ({DATA_WIDTH{npc_src == 2'b01}} & dnpc) |
              ({DATA_WIDTH{npc_src == 2'b10}} & rnpc) |
              ({DATA_WIDTH{npc_src == 2'b11}} & bnpc) ;


endmodule
