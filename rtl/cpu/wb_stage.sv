//Writeback stage designed by Pratik

module wb_stage(

//No clk and rst_n required bcoz WB is purely combinational

//INPUT FROM MEM
input logic [4:0]  mem_wb_rd_addr,
input logic [31:0] mem_wb_alu_result,
input logic [31:0] mem_wb_load_data,
input logic [31:0] mem_wb_pc_plus4,
input logic [1:0]  mem_wb_wb_src,
input logic        mem_wb_reg_wen,
input logic        mem_wb_valid,

//OUTPUT TO REG FILE(id stage)
output logic [4:0]  wb_rd_addr, 
output logic [31:0] wb_rd_data,
output logic        wb_wen

);


assign wb_rd_addr = mem_wb_rd_addr; //no MUX needed

always_comb begin
case (mem_wb_wb_src)
2'b00: wb_rd_data   = mem_wb_alu_result;
2'b01: wb_rd_data   = mem_wb_load_data;
2'b10: wb_rd_data   = mem_wb_pc_plus4;
default: wb_rd_data = mem_wb_alu_result;
endcase
end

assign wb_wen = mem_wb_reg_wen && mem_wb_valid;

endmodule