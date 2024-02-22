`default_nettype none
module Buffer
  #(parameter BIT_WIDTH = 512)
  (input logic clk, rst_l, en
   input logic [BIT_WIDTH-1:0] Buff_In,
   output logic [BIT_WIDTH-1:0] Buff_Out);
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      Buff_Out <= {BIT_WIDTH{1'b0}}
    end
    else if (en) begin
      Buff_Out <= Buff_In;
    end
  end
endmodule


module Register
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, clear, clk, rst_l,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clk, negedge rst_l)
    if (~rst_l)
      Q <= 0;
    else if (en)
      Q <= D;
    else if (clear)
      Q <= '0;
      
endmodule : Register


module Mux2to1
  #(parameter BIT_WIDTH = 512)
  (input logic [1:0][BIT_WIDTH-1:0] Input_Vector,
   input logic Sel,
   output logic [BIT_WIDTH-1:0] Output_Vector);
  assign Output_Vector = Sel ? Input_Vector[1] : Input_Vector[0]
endmodule


module DeMux2to1
  #(parameter BIT_WIDTH = 512)
  (input logic [BIT_WIDTH-1:0] Input_Vector,
   input logic Sel,
   output logic [1:0][BIT_WIDTH-1:0] Output_Vector);
  always_comb begin
    Output_Vector = '0;
    unique case(Sel)
    0: Output_Vector[0] = Input_Vector;
    1: Output_Vector[1] = Input_Vector;
    endcase
  end
endmodule