`default_nettype none
module Buffer
  #(parameter BIT_WIDTH = 512)
  (input logic clk, rst_l, en,
   input logic [BIT_WIDTH-1:0] Buff_In,
   output logic [BIT_WIDTH-1:0] Buff_Out);
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      Buff_Out <= {BIT_WIDTH{1'b0}};
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
  assign Output_Vector = Sel ? Input_Vector[1] : Input_Vector[0];
endmodule


module Mux
  #(parameter RADIX = 2, BIT_WIDTH = 512)
  (input logic [RADIX-1:0][BIT_WIDTH-1:0] Input_Vector,
   input logic [$clog2(RADIX)-1:0] Sel,
   output logic [BIT_WIDTH-1:0] Output_Vector);
  assign Output_Vector = Input_Vector[Sel];
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


module DeMux4to1
  #(parameter BIT_WIDTH = 512)
  (input logic [BIT_WIDTH-1:0] Input_Vector,
   input logic [1:0] Sel,
   output logic [3:0][BIT_WIDTH-1:0] Output_Vector);
  always_comb begin
    Output_Vector = '0;
    unique case(Sel)
    0: Output_Vector[0] = Input_Vector;
    1: Output_Vector[1] = Input_Vector;
    2: Output_Vector[2] = Input_Vector;
    3: Output_Vector[3] = Input_Vector;
    endcase
  end
endmodule

/*
 *  Create a FIFO (First In First Out) buffer with depth 4 using the given
 *  interface and constraints
 *    - The buffer is initally empty
 *    - Reads are combinational, so data_out is valid unless empty is asserted
 *    - Removal from the queue is processed on the clk edge.
 *    - Writes are processed on the clk edge
 *    - If a write is pending while the buffer is full, do nothing
 *    - If a read is pending while the buffer is empty, do nothing
 */
module FIFO #(parameter WIDTH=512+32, DEPTH = 4) (
  input logic              clk, rst_l,
  input logic [WIDTH-1:0]  data_in,
  input logic              we, re,
  output logic [WIDTH-1:0] data_out,
  output logic             full, empty);
  logic [WIDTH-1:0] Q[DEPTH];
  logic [$clog2(DEPTH)-1:0] putPtr, getPtr; 
  logic [$clog2(DEPTH):0] count;

  assign empty = (count == 0);
  assign full = (count == DEPTH);
  assign data_out = empty ? {WIDTH {1'b0}} : Q[getPtr];
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      count <= 0;
      getPtr <= 0;
      putPtr <= 0;
    end
    else if(DEPTH == 1)begin
      if (re && (!empty) && we) begin // read & write at the same time
        Q[putPtr] <= data_in;
        count <= count;
      end
      else 
      if (re && (!empty)) begin // not empty
        count <= count - 1;
      end
      else if (we && (!full)) begin // not full
        Q[putPtr] <= data_in;
        count <= count + 1;
      end
      else begin
        getPtr <= getPtr;
        putPtr <= putPtr;
      end
    end 
    else begin
      if (re && (!empty) && we) begin // read & write at the same time
        getPtr <= getPtr + 1;
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        count <= count;
      end
      else 
      if (re && (!empty)) begin // not empty
        getPtr <= getPtr + 1;
        count <= count - 1;
      end
      else if (we && (!full)) begin // not full
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        count <= count + 1;
      end
      else begin
        getPtr <= getPtr;
        putPtr <= putPtr;
      end
    end
  end
endmodule


// A binary up-down counter.
module Counter
  #(parameter WIDTH=8)
  (input  logic [WIDTH-1:0] D,
   input  logic             en, rst_l, clk, up,
   output logic [WIDTH-1:0] Q);
   
  always_ff @(posedge clk, negedge rst_l)
    if (!rst_l)
      Q <= {WIDTH {1'b0}};
    else if (en)
      if (up)
        Q <= Q + 1'b1;
      else
        Q <= Q - 1'b1;
        
endmodule : Counter

