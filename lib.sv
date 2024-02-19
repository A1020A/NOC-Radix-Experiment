`default_nettype none
module Buffer
  #(parameter BIT_WIDTH = 512)
  (input logic clock, rst_l, en
   input logic [BIT_WIDTH-1:0] Buff_In,
   output logic [BIT_WIDTH-1:0] Buff_Out);
  always_ff @(posedge clock, negedge rst_l) begin
    if (~rst_l) begin
      Buff_Out <= {BIT_WIDTH{1'b0}}
    end
    else if (en) begin
      Buff_Out <= Buff_In;
    end
  end
endmodule


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