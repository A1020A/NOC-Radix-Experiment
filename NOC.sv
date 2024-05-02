`default_nettype none
/***
single memory responding to mutiple cores
***/
`define DATA_WIDTH 128 // start with smaller num
`define RADIX_IN 2
`define RADIX_OUT 2
`define ADDR_WIDTH 16
`define DEPTH 2
`define NETWORK_DEPTH 2

// module CrossBar #(
//   parameter RADIX_IN = 2,
//   parameter RADIX_OUT = 2,
//   parameter BIT_WIDTH = `DATA_WIDTH + `ADDR_WIDTH
// ) (
//   input logic [RADIX_IN-1:0][BIT_WIDTH-1:0] FIFO_C2M_DATA_mid1,
//   output logic [RADIX_OUT-1:0][BIT_WIDTH-1:0] FIFO_C2M_DATA_mid2,
//   input logic [RADIX_OUT-1:0][RADIX_IN-1:0] Matrix_Sel
// );
// genvar i, j;
// generate
//   for (i = 0; i < RADIX_IN; i++) begin
//     for (j = 0; j < RADIX_IN; j++) begin
//       Mux2to1 #(BIT_WIDTH) mux(.Input_Vector({FIFO_C2M_DATA_mid1[i], BIT_WIDTH'0}), .Output_Vector(FIFO_C2M_DATA_mid2[j]), .Sel(Matrix_Sel[i][j]));
//     end
//   end
// endgenerate
// endmodule CrossBar


module Arbiter #(
  parameter RADIX = `RADIX_IN
) (
  input  logic [RADIX-1:0] request,
  output logic [RADIX-1:0] deq, 
  output logic [$clog2(RADIX)-1:0] mux_sel,
  output logic FIFO_ENQ
);
  always_comb begin
    deq = '0;
    FIFO_ENQ = '0;
    mux_sel = '0;
    for (int i = 0; i < RADIX; i++) begin
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

// module DeMux_Dest_Decode #(parameter RADIX = `RADIX, ADDR_WIDTH = `ADDR_WIDTH, LAYER = 0) (
//   input logic [ADDR_WIDTH-1:0] Addr,
//   input logic [RADIX-1:0] FIFO_FULL,
//   output logic [RADIX-1:0] FIFO_ENQ,
//   input logic empty,
//   output logic deq
// );
//   logic [$clog2(RADIX)-1:0] Addr_Indicator;
//   assign Addr_Indicator = Addr[(ADDR_WIDTH-1) - $clog2(RADIX) * LAYER: (ADDR_WIDTH) - $clog2(RADIX) * (LAYER + 1)];
//   always_comb begin
//     deq = 1'b0;
//     deq = (!empty) & (!FIFO_FULL[Addr_Indicator]);
//     FIFO_ENQ = '0;
//     FIFO_ENQ[Addr_Indicator] = deq;
//   end
// endmodule


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
  assign Addr_Indicator = Addr[(ADDR_WIDTH-1) - $clog2(RADIX_OUT) * LAYER: (ADDR_WIDTH) - $clog2(RADIX_OUT) * (LAYER + 1)];
  always_comb begin
    Dest = 1 & !empty;
    Dest = Dest << Addr_Indicator;
  end

endmodule 


module NOC_CrossBar #(
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
  logic [RADIX_OUT-1:0] FIFO_full_mid1;
  logic [RADIX_OUT-1:0] FIFO_enq_mid1;
  logic [RADIX_OUT-1:0][$clog2(RADIX_IN)-1:0] Mux_Sel;
  
  genvar i, j;
  generate
    for (i = 0; i < RADIX_IN; i++) begin
      FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) Input_FIFO(.clk(clk), .rst_l(rst_l), 
                                                          .data_in(FIFO_IN[i]), .we(FIFO_ENQ[i]), .re(FIFO_deq_mid1[i]), 
                                                          .data_out(FIFO_DATA_mid1[i]), .full(FIFO_FULL[i]), .empty(FIFO_empty_mid1[i]));
      Addr_Decode #(RADIX_IN, ADDR_WIDTH, LAYER) Dest_Decode(.Addr(FIFO_DATA_mid1[i][ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH]), 
                                                     .empty(FIFO_empty_mid1[i]), .Dest(Matrix_Request[i]));
    end
  endgenerate

  generate
    for (i = 0; i < RADIX_IN; i++) begin
      for (j = 0; j < RADIX_OUT; j++) begin
        assign Matrix_Request_Transpose[j][i] = Matrix_Request[i][j];
        assign FIFO_deq_mid1_Matrix[i][j] = FIFO_deq_mid1_Transpose[j][i];
      end
    end
  endgenerate

  generate
    for(i = 0; i < RADIX_IN; i++) begin
      assign FIFO_deq_mid1[i] = | FIFO_deq_mid1_Matrix[i];
    end
  endgenerate

  generate 
    for (j = 0; j < RADIX_OUT; j++) begin
      RoundRobinArbiter #(RADIX_OUT) Arbiter(.clk(clk), .rst_l(rst_l), 
                                         .request(Matrix_Request_Transpose[j]), .deq(FIFO_deq_mid1_Transpose[j]),
                                         .FIFO_FULL(FIFO_FULL_downstream[j]), .FIFO_ENQ(FIFO_enq_mid1[j]),
                                         .mux_sel(Mux_Sel[j]));

      Mux #(RADIX_OUT, ADDR_WIDTH+DATA_WIDTH) NOC_Mux(.Input_Vector(FIFO_DATA_mid1), .Sel(Mux_Sel[j]), 
                                                  .Output_Vector(FIFO_OUT[j]));
    end
  endgenerate

  
endmodule


// module NOC_unit #(parameter RADIX = `RADIX,
//                        ADDR_WIDTH = `ADDR_WIDTH,
//                        DATA_WIDTH = `DATA_WIDTH,
//                        DEPTH = `DEPTH,
//                        LAYER = 0) (
//   input logic clk, rst_l,

//   input logic FIFO_M2C_ENQ,
//   input logic [ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_M2C_IN,
//   output logic FIFO_M2C_FULL,

//   output logic [RADIX-1:0] FIFO_M2C_ENQ_downstream,
//   output logic [RADIX-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_M2C_OUT,
//   input logic [RADIX-1:0] FIFO_M2C_FULL_downstream,
  
//   input logic [RADIX-1:0] FIFO_C2M_ENQ,
//   input logic [RADIX-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_C2M_IN,
//   output logic [RADIX-1:0] FIFO_C2M_FULL,

//   output logic FIFO_C2M_ENQ_downstream,
//   output logic [ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_C2M_OUT,
//   input logic FIFO_C2M_FULL_downstream
// );
//   logic [ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_M2C_DATA_mid1;
//   logic FIFO_M2C_empty_mid1;
//   logic [RADIX-1:0] FIFO_M2C_empty_mid2;
//   logic FIFO_M2C_deq_mid1;
//   logic [RADIX-1:0] FIFO_M2C_deq_mid2;
//   logic [RADIX-1:0] FIFO_M2C_full_mid1;
//   logic [RADIX-1:0] FIFO_M2C_enq_mid1;

//   FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) M2C_Input_FIFO(.clk(clk), .rst_l(rst_l), 
//                                                       .data_in(FIFO_M2C_IN), .we(FIFO_M2C_ENQ), .re(FIFO_M2C_deq_mid1), 
//                                                       .data_out(FIFO_M2C_DATA_mid1), .full(FIFO_M2C_FULL), .empty(FIFO_M2C_empty_mid1));
//   DeMux_Dest_Decode #(RADIX, ADDR_WIDTH, LAYER) DeMux_Decode(.Addr(FIFO_M2C_DATA_mid1[ADDR_WIDTH+DATA_WIDTH-1:DATA_WIDTH]), 
//                                           .FIFO_FULL(FIFO_M2C_full_mid1), .FIFO_ENQ(FIFO_M2C_enq_mid1), 
//                                           .empty(FIFO_M2C_empty_mid1), .deq(FIFO_M2C_deq_mid1));

//   genvar i;
//   generate
//     for (i = 0; i < RADIX; i++) begin
//       FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) M2C_Output_FIFO(.clk(clk), .rst_l(rst_l), 
//                                                           .data_in(FIFO_M2C_DATA_mid1), .we(FIFO_M2C_enq_mid1[i]), .re(FIFO_M2C_deq_mid2[i]), 
//                                                           .data_out(FIFO_M2C_OUT[i]), .full(FIFO_M2C_full_mid1[i]), .empty(FIFO_M2C_empty_mid2[i]));
//       FIFO_Ctrl M2C_Output_Aux(.FIFO_EMPTY(FIFO_M2C_empty_mid2[i]), .FIFO_FULL_downstream(FIFO_M2C_FULL_downstream[i]), 
//                               .FIFO_DEQ(FIFO_M2C_deq_mid2[i]), .FIFO_ENQ_downstream(FIFO_M2C_ENQ_downstream[i]));
//     end
//   endgenerate

//   logic [RADIX-1:0] FIFO_C2M_empty_mid1;
//   logic [RADIX-1:0] FIFO_C2M_empty_rot;
//   logic FIFO_C2M_empty_mid2;
//   logic FIFO_C2M_full_mid1;
//   logic [RADIX-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_C2M_DATA_mid1;
//   // logic [RADIX-1:0][ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_C2M_DATA_rot;
//   logic [ADDR_WIDTH+DATA_WIDTH-1:0] FIFO_C2M_DATA_mid2;
//   logic [RADIX-1:0] FIFO_C2M_deq_mid1;
//   logic [RADIX-1:0] FIFO_C2M_deq_rot;
//   logic FIFO_C2M_deq_mid2;
//   logic FIFO_C2M_enq_mid1;
//   logic [$clog2(RADIX)-1:0] Mux_Sel;

//   generate
//     for (i = 0; i < RADIX; i++) begin
//       FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) C2M_Input_FIFO(.clk(clk), .rst_l(rst_l),
//                                                           .data_in(FIFO_C2M_IN[i]), .we(FIFO_C2M_ENQ[i]), .re(FIFO_C2M_deq_mid1[i]), 
//                                                           .data_out(FIFO_C2M_DATA_mid1[i]), .full(FIFO_C2M_FULL[i]), .empty(FIFO_C2M_empty_mid1[i]));
//     end
//   endgenerate
  
//   RoundRobinArbiter #(RADIX) Arbiter(.clk(clk), .rst_l(rst_l), 
//                                      .FIFO_FULL(FIFO_C2M_full_mid1),
//                                      .requ(FIFO_C2M_empty_mid1), .deq(FIFO_C2M_deq_mid1),
//                                      .mux_sel(Mux_Sel), .FIFO_ENQ(FIFO_C2M_enq_mid1));

//   Mux #(RADIX, ADDR_WIDTH+DATA_WIDTH) NOC_Mux(.Input_Vector(FIFO_C2M_DATA_mid1), .Sel(Mux_Sel), 
//                                               .Output_Vector(FIFO_C2M_DATA_mid2));

//   FIFO #(ADDR_WIDTH+DATA_WIDTH, DEPTH) C2M_Output_FIFO(.clk(clk), .rst_l(rst_l), 
//                                                        .data_in(FIFO_C2M_DATA_mid2), .we(FIFO_C2M_enq_mid1), .re(FIFO_C2M_deq_mid2), 
//                                                        .data_out(FIFO_C2M_OUT), .full(FIFO_C2M_full_mid1), .empty(FIFO_C2M_empty_mid2));
//   FIFO_Ctrl C2M_Output_Aux(.FIFO_EMPTY(FIFO_C2M_empty_mid2), .FIFO_FULL_downstream(FIFO_C2M_FULL_downstream), 
//                            .FIFO_DEQ(FIFO_C2M_deq_mid2), .FIFO_ENQ_downstream(FIFO_C2M_ENQ_downstream));
// endmodule
 