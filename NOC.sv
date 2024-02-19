`default_nettype none
/***
single memory responding to mutiple cores
***/
module NOC_N3XT
  #(parameter BIT_WIDTH = 512, 
    parameter RADIX = 2,
    parameter ADDR_WIDTH = 32)
  (input logic clock, rst_l,
   input logic [BIT_WIDTH-1:0] Data_M2C,
   input logic [ADDR_WIDTH-1:0] AccessComplete_M2C,
   input logic [RADIX-1:0][BIT_WIDTH-1:0] Data_C2M,
   input logic [RADIX-1:0][ADDR_WIDTH-1:0] Addr_C2M);
  
endmodule

module Destination_Decoder
endmodule

