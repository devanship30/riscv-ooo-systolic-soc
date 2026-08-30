//MEM stage designed by Pratik

module mem_stage(
//BASIC
input logic clk,
input logic rst_n,

//INPUTS FROM EX
input logic [4:0] ex_mem_rd_addr, //5 bit reg addr
input logic [31:0]ex_mem_alu_result,//32 bit computed addr
input logic [31:0]ex_mem_rs2_data,//32bit store data
input logic ex_mem_mem_read,
input logic ex_mem_mem_write,
input logic [2:0]ex_mem_mem_funct3,
input logic ex_mem_reg_wen,
input logic [1:0]ex_mem_wb_src,
input logic ex_mem_valid,
input logic [31:0]ex_mem_pc_plus4,

//AXI4 WRITE CHANNELS (TO SRAM)
output logic [31:0] data_awaddr,
output logic [7:0]  data_awlen,
output logic [2:0]  data_awsize,
output logic [1:0]  data_awburst,
output logic        data_awvalid,
input logic         data_awready,
output logic [31:0] data_wdata,
output logic [3:0]  data_wstrb,
output logic        data_wlast,
output logic        data_wvalid,
input logic         data_wready,
input logic  [1:0]  data_bresp,
input logic         data_bvalid,
output logic        data_bready,

//AXI4 READ CHANNELS
output logic [31:0] data_araddr,
output logic [7:0] data_arlen,
output logic [2:0] data_arsize,
output logic [1:0]  data_arburst,
output logic        data_arvalid,
input logic         data_arready,
input logic [31:0]  data_rdata,
input logic [1:0]   data_rresp,
input logic         data_rvalid,
output logic        data_rready,

//OUTPUTS TO WB CHANNELS
output logic [4:0]  mem_wb_rd_addr,
output logic [31:0] mem_wb_alu_result,
output logic [31:0] mem_wb_load_data,
output logic [1:0]  mem_wb_wb_src,
output logic        mem_wb_reg_wen,
output logic [31:0] mem_wb_pc_plus4,
output logic        mem_wb_valid
);

assign data_awaddr = ex_mem_alu_result;
assign data_wdata  = wdata_shifted;

//WORD ALIGNMENT LOGIC
logic [1:0] byte_offset;
assign byte_offset = ex_mem_alu_result[1:0];

always_comb begin
case(ex_mem_mem_funct3)
//STORE BYTE LOGIC
3'b000: begin
case(byte_offset)
2'b00: data_wstrb = 4'b0001;
2'b01: data_wstrb = 4'b0010;
2'b10: data_wstrb = 4'b0100;
2'b11: data_wstrb = 4'b1000;
endcase
end

//STORE HALF WORD LOGIC
//data_wstrb = 4'b0011
3'b001:begin
case(byte_offset)
2'b00: data_wstrb = 4'b0011;
2'b10: data_wstrb = 4'b1100;
default: data_wstrb = 4'b0000;
endcase
end

//STORE WORD LOGIC
//data_wstrb = 4'b1111
3'b010:begin
data_wstrb = 4'b1111;
end
default:data_wstrb = 4'b0000;
endcase
end

logic [31:0] wdata_shifted;//hold duplicated version of stores (SB,SH,SW)

always_comb begin
case (ex_mem_mem_funct3)
//FOR STORE BYTE
3'b000: begin
wdata_shifted = {4{ex_mem_rs2_data[7:0]}};
end

//FOR STORE HALFWORD
3'b001: begin
wdata_shifted = {2{ex_mem_rs2_data[15:0]}};
end

//FOR STORE WORD
3'b010: begin
wdata_shifted = ex_mem_rs2_data;
end

//DEFAULT
default: wdata_shifted = ex_mem_rs2_data;
endcase
end

//WRITE SIDE (STORE)
assign data_wvalid  = ex_mem_mem_write && ex_mem_valid;
assign data_awvalid = ex_mem_mem_write && ex_mem_valid;
assign data_wlast   = 1'b1; //since we transfer data 1 bit at a time
assign data_awlen   = 8'd0; //awlen = burst-1 => 1-1 => 0
assign data_awsize  = 3'b010; //we send 4 bytes, 3'b010 (2^2)
assign data_awburst = 2'b01; //increment hardwired (AXI4 hardwiring)
assign data_bready  = 1'b1;  //always ready 

//READ SIDE (LOAD)
//assign data_rvalid= ex_mem_mem_read Cant assign rvalid cause its input
assign data_arvalid = ex_mem_mem_read && ex_mem_valid;
assign data_araddr  = ex_mem_alu_result;
assign data_arlen   = 8'd0;
assign data_arsize  = 3'b010;
assign data_arburst = 2'b01;
assign data_rready  = 1'b1;


//LOAD sign extension 

logic [31:0] load_data_extended;

always_comb begin
case (ex_mem_mem_funct3)

//LOAD BYTE EXTRACTION
3'b000: begin
case (byte_offset)
2'b00: load_data_extended ={{24{data_rdata[7]}}, data_rdata[7:0]}; 
2'b01: load_data_extended ={{24{data_rdata[15]}}, data_rdata[15:8]}; 
2'b10: load_data_extended ={{24{data_rdata[23]}}, data_rdata[23:16]}; 
2'b11: load_data_extended ={{24{data_rdata[31]}}, data_rdata [31:24]}; 
endcase
end

//LOAD HALF WORD EXTRACTION
3'b001: begin
case(byte_offset)
2'b00: load_data_extended = {{16{data_rdata[15]}}, data_rdata[15:0]};
2'b10: load_data_extended = {{16{data_rdata[31]}}, data_rdata[31:16]};
default: load_data_extended = {{16{data_rdata[15]}}, data_rdata[15:0]};
endcase
end

//LOAD WORD EXTRACTION
3'b010: begin
load_data_extended = data_rdata;
end



//LOAD BYTE UNSIGNED EXTRACTION
3'b100: begin
case (byte_offset)
2'b00: load_data_extended ={24'd0, data_rdata[7:0]}; 
2'b01: load_data_extended ={24'd0, data_rdata[15:8]}; 
2'b10: load_data_extended ={24'd0, data_rdata[23:16]}; 
2'b11: load_data_extended ={24'd0, data_rdata [31:24]}; 
endcase
end


//LOAD HALFWORD UNSIGNED EXTRACTION
3'b101: begin
case(byte_offset)
2'b00: load_data_extended   = {16'd0, data_rdata[15:0]};
2'b10: load_data_extended   = {16'd0, data_rdata[31:16]};
default: load_data_extended = {16'd0, data_rdata[15:0]};
endcase
end
default: load_data_extended   = data_rdata;
endcase
end

always_ff @(posedge clk) begin
if (!rst_n)begin
mem_wb_rd_addr    <= 0;
mem_wb_alu_result <= 0;
mem_wb_load_data  <= 0;
mem_wb_wb_src     <= 0;
mem_wb_reg_wen    <= 0;
mem_wb_pc_plus4   <= 0;
mem_wb_valid      <= 0;
end
else begin
mem_wb_rd_addr    <= ex_mem_rd_addr;
mem_wb_alu_result <= ex_mem_alu_result;
mem_wb_load_data  <= load_data_extended;
mem_wb_wb_src     <= ex_mem_wb_src;
mem_wb_reg_wen    <= ex_mem_reg_wen;
mem_wb_pc_plus4   <= ex_mem_pc_plus4;
mem_wb_valid      <= ex_mem_valid;
end
end
endmodule