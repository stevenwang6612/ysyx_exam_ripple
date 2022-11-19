// Burst types
`define AXI_BURST_TYPE_FIXED                                2'b00               //突发类型  FIFO
`define AXI_BURST_TYPE_INCR                                 2'b01               //ram  
`define AXI_BURST_TYPE_WRAP                                 2'b10
// Access permissions
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100
// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
// Memory types (AW)
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

`define AXI_SIZE_BYTES_1                                    3'b000                //突发宽度一个数据的宽度
`define AXI_SIZE_BYTES_2                                    3'b001
`define AXI_SIZE_BYTES_4                                    3'b010
`define AXI_SIZE_BYTES_8                                    3'b011
`define AXI_SIZE_BYTES_16                                   3'b100
`define AXI_SIZE_BYTES_32                                   3'b101
`define AXI_SIZE_BYTES_64                                   3'b110
`define AXI_SIZE_BYTES_128                                  3'b111


module ysyx_040729_AXI # (
    parameter RW_DATA_WIDTH     = 128,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 32,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_STRB_WIDTH    = AXI_DATA_WIDTH/8,
    parameter AXI_USER_WIDTH    = 1
)(
    input                               clock,
    input                               reset,

    //read
    input  [AXI_ADDR_WIDTH-1:0]         r_addr_i,
    input  [2:0]                        r_size_i,
	input                               r_valid_i, 
	output                              r_ready_o,  
    output [RW_DATA_WIDTH-1:0]          r_data_o,
    //write
    input  [AXI_ADDR_WIDTH-1:0]         w_addr_i,
    input  [RW_DATA_WIDTH-1:0]          w_data_i,
    input  [2:0]                        w_size_i,
    input                               w_valid_i,  
	output                              w_ready_o,



    // Advanced eXtensible Interface
    input                               axi_aw_ready_i,              
    output                              axi_aw_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o,
    output [2:0]                        axi_aw_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_aw_user_o,
    output [7:0]                        axi_aw_len_o,
    output [2:0]                        axi_aw_size_o,
    output [1:0]                        axi_aw_burst_o,
    output                              axi_aw_lock_o,
    output [3:0]                        axi_aw_cache_o,
    output [3:0]                        axi_aw_qos_o,
    output [3:0]                        axi_aw_region_o,

    input                               axi_w_ready_i,                
    output                              axi_w_valid_o,
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o,
    output [AXI_STRB_WIDTH-1:0]         axi_w_strb_o,
    output                              axi_w_last_o,
    output [AXI_USER_WIDTH-1:0]         axi_w_user_o,
    
    output                              axi_b_ready_o,                
    input                               axi_b_valid_i,
    input  [1:0]                        axi_b_resp_i,                 
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_b_user_i,

    input                               axi_ar_ready_i,                
    output                              axi_ar_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o,
    output [2:0]                        axi_ar_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_ar_user_o,
    output [7:0]                        axi_ar_len_o,
    output [2:0]                        axi_ar_size_o,
    output [1:0]                        axi_ar_burst_o,
    output                              axi_ar_lock_o,
    output [3:0]                        axi_ar_cache_o,
    output [3:0]                        axi_ar_qos_o,
    output [3:0]                        axi_ar_region_o,
    
    output                              axi_r_ready_o,                 
    input                               axi_r_valid_i,                
    input  [1:0]                        axi_r_resp_i,
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i,
    input                               axi_r_last_i,
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_r_user_i
);

    // handshake
    wire aw_hs      = axi_aw_ready_i & axi_aw_valid_o;
    wire w_hs       = axi_w_ready_i  & axi_w_valid_o;
    wire b_hs       = axi_b_ready_o  & axi_b_valid_i;
    wire ar_hs      = axi_ar_ready_i & axi_ar_valid_o;
    wire r_hs       = axi_r_ready_o  & axi_r_valid_i; 

    wire w_done     = w_hs & axi_w_last_o;// write done只是用于状态转换
    wire r_done     = r_hs & axi_r_last_i;

    // ------------------State Machine---------------------
    localparam [1:0] W_STATE_IDLE = 2'b00, W_STATE_ADDR = 2'b01, W_STATE_WRITE = 2'b10, W_STATE_RESP = 2'b11;
    localparam [1:0] R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_READ  = 2'b10;
    reg r_ready, w_ready;
    reg [1:0] w_state, w_state_next, r_state, r_state_next;
    wire w_state_idle = w_state == W_STATE_IDLE, w_state_addr = w_state == W_STATE_ADDR, w_state_write = w_state == W_STATE_WRITE, w_state_resp = w_state == W_STATE_RESP;
    wire r_state_idle = r_state == R_STATE_IDLE, r_state_addr = r_state == R_STATE_ADDR, r_state_read  = r_state == R_STATE_READ;
    // 写通道状态切换
    Reg #(2, W_STATE_IDLE) w_state_inst (clock, reset, w_state_next, w_state, w_valid_i & ~w_ready);
    assign w_state_next = ( {2{w_state == W_STATE_IDLE}}) & ( W_STATE_ADDR ) |
			              ( {2{w_state == W_STATE_ADDR}}) & ( ar_hs  ? W_STATE_WRITE: w_state ) |
			              ( {2{w_state == W_STATE_WRITE}})& ( w_done ? W_STATE_RESP : w_state ) |
                          ( {2{w_state == W_STATE_RESP}}) & ( b_hs   ? W_STATE_IDLE : w_state ) ;

    // 读通道状态切换
    Reg #(2, R_STATE_IDLE) r_state_inst (clock, reset, r_state_next, r_state, r_valid_i & ~r_ready);
    assign r_state_next = ( {2{r_state == R_STATE_IDLE}}) & ( R_STATE_ADDR ) |
			              ( {2{r_state == R_STATE_ADDR}}) & ( ar_hs  ? R_STATE_READ : r_state ) |
			              ( {2{r_state == R_STATE_READ}}) & ( r_done ? R_STATE_IDLE : r_state ) ;

    //
    Reg #(1, 0) r_ready_inst (clock, reset, r_done, r_ready, r_done | r_ready);
    Reg #(1, 0) w_ready_inst (clock, reset, b_hs  , w_ready, b_hs   | w_ready);
    assign r_ready_o = r_ready;
    assign w_ready_o = w_ready;

    // ------------------burst Transaction------------------
    localparam CNT_WID = (RW_DATA_WIDTH > AXI_DATA_WIDTH) ? $clog2($clog2(RW_DATA_WIDTH / AXI_DATA_WIDTH)+1) : 1;
    reg [CNT_WID-1:0] r_cnt;
    wire [7:0] r_len = ($clog2(AXI_DATA_WIDTH/8) < r_size_i) ? ((8'b1<<({29'b0,r_size_i}-$clog2(AXI_DATA_WIDTH/8)))-1) : 8'b0;
    wire [CNT_WID:0] r_cnt_next = r_cnt + 1;
    wire r_cnt_reset = reset | r_state_addr;
    wire r_cnt_en = r_hs | |r_len;
    Reg #(CNT_WID, {CNT_WID{1'b0}}) r_cnt_inst (clock, r_cnt_reset, r_cnt_next[CNT_WID-1:0], r_cnt, r_cnt_en);

    reg [CNT_WID-1:0] w_cnt;
    wire [7:0] w_len = ($clog2(AXI_DATA_WIDTH/8) < w_size_i) ? ((8'b1<<({29'b0,w_size_i}-$clog2(AXI_DATA_WIDTH/8)))-1) : 8'b0;
    wire [CNT_WID:0] w_cnt_next = w_cnt + 1;
    wire w_cnt_reset = reset | w_state_addr;
    wire w_cnt_en = w_hs | |w_len;
    Reg #(CNT_WID, {CNT_WID{1'b0}}) w_cnt_inst (clock, w_cnt_reset, w_cnt_next[CNT_WID-1:0], w_cnt, w_cnt_en);

    // ------------------Write Transaction------------------
    parameter AXI_SIZE      = $clog2(AXI_DATA_WIDTH / 8);
    wire [AXI_ID_WIDTH-1:0] axi_id              = {AXI_ID_WIDTH{1'b0}};
    wire [AXI_USER_WIDTH-1:0] axi_user          = {AXI_USER_WIDTH{1'b0}};
    wire [2:0] axi_len      =  3'b0 ;
    wire [2:0] axi_size     = AXI_SIZE[2:0];
    // Write address channel signals  以下没有备注初始化信号的都可能是你需要产生和用到的
    assign axi_aw_valid_o   = w_state_addr;
    assign axi_aw_addr_o    = w_addr_i;
    assign axi_aw_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;  //初始化信号即可
    assign axi_aw_id_o      = axi_id;                                                                           //初始化信号即可
    assign axi_aw_user_o    = axi_user;                                                                         //初始化信号即可
    assign axi_aw_len_o     = w_len;
    assign axi_aw_size_o    = |w_len ? axi_size : w_size_i;
    assign axi_aw_burst_o   = `AXI_BURST_TYPE_INCR;                                                             
    assign axi_aw_lock_o    = 1'b0;                                                                             //初始化信号即可
    assign axi_aw_cache_o   = `AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE;                                  //初始化信号即可
    assign axi_aw_qos_o     = 4'h0;                                                                             //初始化信号即可
    assign axi_aw_region_o  = 4'h0;                                                                             //初始化信号即可

    // Write data channel signals
    generate if (RW_DATA_WIDTH > AXI_DATA_WIDTH) begin
        wire [AXI_DATA_WIDTH-1:0] axi_w_data_buf[(RW_DATA_WIDTH / AXI_DATA_WIDTH)];
        for (genvar i=0; i<(RW_DATA_WIDTH / AXI_DATA_WIDTH); i=i+1) begin
            assign axi_w_data_buf[i] = w_data_i[AXI_DATA_WIDTH*i + (AXI_DATA_WIDTH-1) : AXI_DATA_WIDTH*i];
        end
        assign axi_w_data_o = axi_w_data_buf[w_cnt];
    end else
        assign axi_w_data_o = w_data_i;
    endgenerate
    
    assign axi_w_strb_o[0] = 1'b1;
    generate
        for (genvar i=0; i<$clog2(AXI_STRB_WIDTH); i=i+1) begin
            assign axi_w_strb_o[(2**(i+1))-1 : 2**i] = |w_len ? {(2**i){1'b1}} : {(2**i){i<w_size_i}};
        end
    endgenerate
    assign axi_w_valid_o    = w_state_write;
    assign axi_w_last_o     = 1'b1;
    assign axi_w_user_o     = axi_user;                                                                         //初始化信号即可

    // Write back channel signals
    assign axi_b_ready_o    = w_state_resp;

    // ------------------Read Transaction------------------

    // Read address channel signals
    assign axi_ar_valid_o   = r_state_addr;
    assign axi_ar_addr_o    = r_addr_i;
    assign axi_ar_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;  //初始化信号即可
    assign axi_ar_id_o      = axi_id;                                                                           //初始化信号即可                        
    assign axi_ar_user_o    = axi_user;                                                                         //初始化信号即可
    assign axi_ar_len_o     = r_len;                                                                          
    assign axi_ar_size_o    = |r_len ? axi_size : r_size_i;
    assign axi_ar_burst_o   = `AXI_BURST_TYPE_INCR;
    assign axi_ar_lock_o    = 1'b0;                                                                             //初始化信号即可
    assign axi_ar_cache_o   = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;                                 //初始化信号即可
    assign axi_ar_qos_o     = 4'h0;                                                                             //初始化信号即可
    assign axi_ar_region_o  = 4'h0;

    // Read data channel signals
    reg [RW_DATA_WIDTH-1:0] r_data_reg;
    assign axi_r_ready_o    = r_state_read;
    wire [RW_DATA_WIDTH-1:0] r_data_o_next;
    generate if (RW_DATA_WIDTH > AXI_DATA_WIDTH) begin
        for (genvar i=0; i<(RW_DATA_WIDTH / AXI_DATA_WIDTH); i=i+1) begin
            assign r_data_o_next[AXI_DATA_WIDTH*i + (AXI_DATA_WIDTH-1) : AXI_DATA_WIDTH*i] = 
            (r_cnt==i) ? axi_r_data_i : r_data_o[AXI_DATA_WIDTH*i + (AXI_DATA_WIDTH-1) : AXI_DATA_WIDTH*i];
        end
    end else
        assign r_data_o_next = axi_r_data_i;
    endgenerate
    Reg #(RW_DATA_WIDTH, {RW_DATA_WIDTH{1'b0}}) data_read_o_inst (clock, reset, r_data_o_next, r_data_reg, r_hs);
    assign r_data_o = r_data_reg;

endmodule
