// `default_nettype none
/***
single memory responding to mutiple cores
***/
`define ADDR_WIDTH 16
`define DATA_WIDTH 32 // start with smaller num
`define RADIX_IN 4
`define RADIX_OUT 8
`define DEPTH 2
`define NETWORK_DEPTH 1

module NOC_unit #(
  parameter RADIX_IN = `RADIX_IN,
            RADIX_OUT = `RADIX_OUT,
            ADDR_WIDTH = `ADDR_WIDTH, 
            DATA_WIDTH = `DATA_WIDTH,
            DEPTH = `DEPTH,
            LAYER = 0
) (
  input logic clk, rst_l, 

  input logic [RADIX_IN-1:0] FIFO_ENQ,
  input logic [RADIX_IN-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_IN, 
  output logic [RADIX_IN-1:0] FIFO_FULL, 

  output logic [RADIX_OUT-1:0] FIFO_ENQ_downstream,
  output logic [RADIX_OUT-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_OUT,
  input logic [RADIX_OUT-1:0] FIFO_FULL_downstream
);
  logic [RADIX_IN-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_DATA_mid1;
  logic [RADIX_IN-1:0] FIFO_deq_mid1;
  logic [RADIX_IN-1:0][RADIX_OUT-1:0] FIFO_deq_mid1_Matrix;
  logic [RADIX_OUT-1:0][RADIX_IN-1:0] FIFO_deq_mid1_Transpose;
  logic [RADIX_IN-1:0] FIFO_empty_mid1;
  logic [RADIX_IN-1:0][RADIX_OUT-1:0] Matrix_Request;
  logic [RADIX_OUT-1:0][RADIX_IN-1:0] Matrix_Request_Transpose;
  logic [RADIX_OUT-1:0][$clog2(RADIX_IN)-1:0] Mux_Sel;

  
  genvar i, j;
  generate
    for (i = 0; i < RADIX_IN; i++) begin: Input_Buff
      logic full, full_next_cylce;
      FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) Input_FIFO(.clk(clk), .rst_l(rst_l), 
                                                      .data_in(FIFO_IN[i]), .we(FIFO_ENQ[i]), .re(FIFO_deq_mid1[i]), 
                                                      .data_out(FIFO_DATA_mid1[i]), .full(full), .full_next_cylce(full_next_cylce), 
                                                      .empty(FIFO_empty_mid1[i]));
      assign FIFO_FULL[i] = full || full_next_cylce;
      Addr_Decode #(RADIX_OUT, ADDR_WIDTH, LAYER) Dest_Decode(.Addr(FIFO_DATA_mid1[i][ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH]), 
                                                              .empty(FIFO_empty_mid1[i]), .Dest(Matrix_Request[i]));
    end
  endgenerate
  // pipeline stage 1
  generate
    for (i = 0; i < RADIX_IN; i++) begin: Transpose
      for (j = 0; j < RADIX_OUT; j++) begin
        assign Matrix_Request_Transpose[j][i] = Matrix_Request[i][j];
        assign FIFO_deq_mid1_Matrix[i][j] = FIFO_deq_mid1_Transpose[j][i];
      end
    end
  endgenerate

  generate
    for(i = 0; i < RADIX_IN; i++) begin: Target_Gather
      assign FIFO_deq_mid1[i] = | FIFO_deq_mid1_Matrix[i];
    end
  endgenerate

  generate
    for (j = 0; j < RADIX_OUT; j++) begin: Flow_Control
      RoundRobinArbiter #(RADIX_IN) Arbiter(.clk(clk), .rst_l(rst_l), 
                                         .request(Matrix_Request_Transpose[j]), .deq(FIFO_deq_mid1_Transpose[j]),
                                         .FIFO_FULL(FIFO_FULL_downstream[j]), .FIFO_ENQ(FIFO_ENQ_downstream[j]),
                                         .mux_sel(Mux_Sel[j]));
      // pipeline stage 2
      Mux #(RADIX_IN, ADDR_WIDTH+DATA_WIDTH) Cross_Bar(.Input_Vector(FIFO_DATA_mid1), .Sel(Mux_Sel[j]), 
                                                  .Output_Vector(FIFO_OUT[j]));
    end
  endgenerate
endmodule


module Arbiter #(
  parameter RADIX_IN = `RADIX_IN
) (
  input  logic [RADIX_IN-1:0] request,
  output logic [RADIX_IN-1:0] deq, 
  output logic [$clog2(RADIX_IN)-1:0] mux_sel,
  output logic FIFO_ENQ
);
  always_comb begin
    deq = '0;
    FIFO_ENQ = '0;
    mux_sel = '0;
    for (int i = 0; i < RADIX_IN; i++) begin
      if (request[i]) begin
        deq[i] = 1;
        mux_sel = i;
        FIFO_ENQ = 1;
        break;
      end
    end
  end

endmodule


module RoundRobinArbiter #(
  parameter RADIX_IN = `RADIX_IN
) (
  input logic clk,
  input logic rst_l,
  input logic FIFO_FULL,
  input logic [RADIX_IN-1:0] request, 
  output logic [RADIX_IN-1:0] deq, // use this as one hot decode encode arbitration result for crossbar
  output logic [$clog2(RADIX_IN)-1:0] mux_sel,
  output logic FIFO_ENQ
);
  logic [RADIX_IN-1:0] req_unmasked;
  logic [RADIX_IN-1:0] req_masked;

  logic [RADIX_IN-1:0] mask, maskNext;
  
  logic [RADIX_IN-1:0] deq_unmasked, deq_masked;
  logic [$clog2(RADIX_IN)-1:0] mux_sel_unmasked, mux_sel_masked;
  logic FIFO_ENQ_unmasked, FIFO_ENQ_masked;

  assign req_masked = req_unmasked & mask;

  genvar i;
  for (i = 0; i < RADIX_IN; i++) begin
    assign req_unmasked[i] = request[i] && !FIFO_FULL;
  end

  Arbiter #(
    RADIX_IN
  ) arbiter (
    .request(req_unmasked),
    .deq(deq_unmasked), 
    .mux_sel(mux_sel_unmasked), 
    .FIFO_ENQ(FIFO_ENQ_unmasked)
  );

  Arbiter #(
    RADIX_IN
  ) maskedArbiter (
    .request(req_masked),
    .deq(deq_masked), 
    .mux_sel(mux_sel_masked), 
    .FIFO_ENQ(FIFO_ENQ_masked)
  );

  always_comb begin
    deq = '0;
    mux_sel = '0;
    FIFO_ENQ = '0;
    if (req_masked == '0) begin
      deq = deq_unmasked;
      mux_sel = mux_sel_unmasked;
      FIFO_ENQ = FIFO_ENQ_unmasked;
    end
    else begin
      deq = deq_masked;
      mux_sel = mux_sel_masked;
      FIFO_ENQ = FIFO_ENQ_masked;
    end

    if (deq == '0) begin
      maskNext = mask;
    end
    else begin
      maskNext = '1;

      for (int i = 0; i < RADIX_IN; i++) begin
        maskNext[i] = 1'b0;
        if (deq[i]) break;
      end
    end
  end

  always_ff @(posedge clk or negedge rst_l) begin
    if (!rst_l) mask <= '1;
    else mask <= maskNext;
  end
  
endmodule


module Addr_Decode #(
  parameter RADIX_OUT = `RADIX_OUT,
            ADDR_WIDTH = `ADDR_WIDTH,
            LAYER = 0
) (
  input logic [ADDR_WIDTH-1:0] Addr, 
  input logic empty, 
  output logic [RADIX_OUT-1:0] Dest
);
  logic [$clog2(RADIX_OUT)-1:0] Addr_Indicator;
  assign Addr_Indicator = Addr[((ADDR_WIDTH-1) - ($clog2(RADIX_OUT) * LAYER)): ((ADDR_WIDTH) - ($clog2(RADIX_OUT) * (LAYER + 1)))];
  always_comb begin
    Dest = 1 & !empty;
    Dest = Dest << Addr_Indicator;
  end

endmodule 


module Mux
  #(parameter RADIX = 2, BIT_WIDTH = 512)
  (input logic [RADIX-1:0][BIT_WIDTH-1:0] Input_Vector,
   input logic [$clog2(RADIX)-1:0] Sel,
   output logic [BIT_WIDTH-1:0] Output_Vector);
  assign Output_Vector = Input_Vector[Sel];
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
  output logic             full, full_next_cylce, almost_full, empty);
  logic [WIDTH-1:0] Q[DEPTH];
  logic [$clog2(DEPTH)-1:0] putPtr, getPtr; 
  logic [$clog2(DEPTH):0] count;

  assign empty = (count == 0);
  assign full = (count == DEPTH);
  assign full_next_cylce = almost_full && we;
  assign almost_full = (count == DEPTH - 1);
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
      if (re) begin
        if (empty) $fatal("FIFO empty");
      end
      else if (we) begin
        if (full) $fatal("FIFO full");
      end
      if (re && (!empty) && we) begin // read & write at the same time
        getPtr <= getPtr + 1;
        Q[putPtr] <= data_in;
        putPtr <= putPtr + 1;
        count <= count;
      end
      else if (re && (!empty)) begin // not empty
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


module FIFO_sreg #(parameter WIDTH=512+32, DEPTH = 2) (
  input logic             clk, rst_l,
  input logic [WIDTH-1:0] data_in,
  input logic             we, re,
  output logic [WIDTH-1:0] data_out,
  output logic             full, full_next_cylce, empty, almost_full
);
  logic [WIDTH-1:0] D;
  logic [DEPTH-1:0][WIDTH-1:0] Q; 
  logic [$clog2(DEPTH):0] putPtr_q, putPtr_d;
  assign data_out = Q[0];
  assign empty = (putPtr_q == 0);
  assign full = (putPtr_q == DEPTH);
  assign full_next_cylce = almost_full && we;
  assign almost_full = (putPtr_q == DEPTH - 1);
  assign D = we ? data_in : '0;

  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      putPtr_q <= 0;
      Q <= '0;
    end
    else begin
      if (re) begin
        for (int i = 0; i < DEPTH; i++) begin
          if (i < DEPTH-1) begin
            Q[i] <= Q[i+1];
          end
          else begin
            Q[i] <= '0;
          end
        end
      end
      if (we && re) begin
        if (empty) $fatal("FIFO empty, read and write at the same time");
        Q[putPtr_q-1] <= D;
        // $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q-1, D);
        putPtr_q <= putPtr_q;
      end
      else if (re) begin
        if (empty) $fatal("FIFO empty");
        putPtr_q <= putPtr_q - 1;
      end
      else if (we) begin
        if (full) $fatal("FIFO full");
        Q[putPtr_q] <= D;
        // $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q, D);
        putPtr_q <= putPtr_q + 1;
      end
      else begin
        putPtr_q <= putPtr_q;
      end
    end
  end
endmodule


`define ENABLE_PIPELINE 0
module Pipeline_Register #(
  parameter WIDTH = 512
) (
  input logic clk, rst_l,
  input logic [WIDTH-1:0] data_in,
  output logic [WIDTH-1:0] data_out
);
`ifdef ENABLE_PIPELINE
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      data_out <= {WIDTH{1'b0}};
    end
    else begin
      data_out <= data_in;
    end
  end
`else
  assign data_out = data_in;
`endif
endmodule

