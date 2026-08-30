//Hazard Unit for CPU
//Last edited - 07/22/26

module hazard_unit(
output logic stall_if,
output logic stall_id,
output logic flush_if,
output logic flush_id,
output logic [1:0] fwd_a_sel,
output logic [1:0] fwd_b_sel,
input logic  [4:0] id_rs1_addr, id_rs2_addr,//what current instruct needs
input logic  [4:0] ex_rd_addr, //what EX stage is writing to
input logic        ex_reg_wen, //check if EX stage is actually writing
input logic  [4:0] mem_rd_addr, //what MEM stage is writing to
input logic        mem_reg_wen, //is mem actually writing
input logic        branch_taken, //did branch happen
input logic        ex_exception, //did exception happen
input logic        ex_mem_read
);

always_comb begin
//DEFAULTS TO AVOID LATCHES
stall_if=0;
stall_id=0;
flush_if=0;
flush_id=0;


//FWD_A_SEL 
if(ex_reg_wen==1 && ex_rd_addr != 5'd0 && ex_rd_addr == id_rs1_addr)
fwd_a_sel = 2'b01; //forward from EX

else if (mem_reg_wen==1 && mem_rd_addr != 5'd0 && mem_rd_addr == id_rs1_addr)
fwd_a_sel = 2'b10; //forward from MEM

else 
fwd_a_sel = 2'b00;




//FWD_B_SEL
if(ex_reg_wen==1 && ex_rd_addr != 5'd0 && ex_rd_addr == id_rs2_addr)
fwd_b_sel = 2'b01; //forward from EX

else if (mem_reg_wen==1 && mem_rd_addr != 5'd0 && mem_rd_addr == id_rs2_addr)
fwd_b_sel = 2'b10; //forward from MEM

else 
fwd_b_sel = 2'b00;




//Load-use stall
if (ex_mem_read == 1 && ex_rd_addr!=5'd0 && (ex_rd_addr==id_rs1_addr || ex_rd_addr==id_rs2_addr))begin
stall_if = 1;
stall_id = 1;
end



//BRANCH FLUSH
if(branch_taken==1)begin
flush_if=1;
flush_id=1;
end



//EXCEPTION FLUSH
if (ex_exception==1)begin
flush_if=1;
flush_id=1;
end
end
endmodule