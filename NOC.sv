`default_nettype none
/***
single memory responding to mutiple cores
***/
`define RADIX_Width 1
`define BIT_WIDTH 512 // start with smaller num
`define RADIX 2
`define AC_WIDTH $clog2(`RADIX)
`define ADDR_WIDTH 32
`define NODE_WIDTH_FINAL 2

module NOC
  (input logic clk, rst_l,
   input logic en_M2C_IN,
   input logic [`BIT_WIDTH-1:0] Data_M2C_IN,
   input logic [`AC_WIDTH:0] AccessComplete_M2C_IN,
   output logic en_C2M_OUT, 
   output logic [`BIT_WIDTH-1:0] Data_C2M_OUT,
   output logic [`ADDR_WIDTH-1:0] Addr_C2M_OUT,
   input logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0] en_C2M_IN,
   input logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0][`BIT_WIDTH-1:0] Data_C2M_IN,
   input logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0][`ADDR_WIDTH-1:0] Addr_C2M_IN,
   output logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0] en_M2C_OUT,  
   output logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0][`BIT_WIDTH-1:0] Data_M2C_OUT,
   output logic [`NODE_WIDTH_FINAL-1:0][`RADIX-1:0][`AC_WIDTH:0] AccessComplete_M2C_OUT);
  logic [`RADIX-1:0] en_C2M_l1l2, en_M2C_l1l2;
  logic [`RADIX-1:0][`ADDR_WIDTH-1:0] Addr_C2M_l1l2;
  logic [`RADIX-1:0][`AC_WIDTH:0] AccessComplete_M2C_l1l2;
  logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_C2M_l1l2, Data_M2C_l1l2;
  
  NOC_R2 NOC1_1 (.clk, .rst_l, .en_M2C_IN, .Data_M2C_IN, .AccessComplete_M2C_IN, 
                   .en_C2M_OUT, .Data_C2M_OUT, .Addr_C2M_OUT, 
                   .en_C2M_IN(en_C2M_l1l2), .Data_C2M_IN(Data_C2M_l1l2), .Addr_C2M_IN(Addr_C2M_l1l2), 
                   .en_M2C_OUT(en_M2C_l1l2), .Data_M2C_OUT(Data_M2C_l1l2), .AccessComplete_M2C_OUT(AccessComplete_M2C_l1l2));

  NOC_R2 NOC1_2 (.clk, .rst_l, .en_M2C_IN(en_M2C_l1l2[0]), .Data_M2C_IN(Data_M2C_l1l2[0]), .AccessComplete_M2C_IN(AccessComplete_M2C_l1l2[0]), 
                   .en_C2M_OUT(en_C2M_l1l2[0]), .Data_C2M_OUT(Data_C2M_l1l2[0]), .Addr_C2M_OUT(Addr_C2M_l1l2[0]), 
                   .en_C2M_IN(en_C2M_IN[0]), .Data_C2M_IN(Data_C2M_IN[0]), .Addr_C2M_IN(Addr_C2M_IN[0]), 
                   .en_M2C_OUT(en_M2C_OUT[0]), .Data_M2C_OUT(Data_M2C_OUT[0]), .AccessComplete_M2C_OUT(AccessComplete_M2C_OUT[0]));

  NOC_R2 NOC1_3 (.clk, .rst_l, .en_M2C_IN(en_M2C_l1l2[1]), .Data_M2C_IN(Data_M2C_l1l2[1]), .AccessComplete_M2C_IN(AccessComplete_M2C_l1l2[1]), 
                   .en_C2M_OUT(en_C2M_l1l2[1]), .Data_C2M_OUT(Data_C2M_l1l2[1]), .Addr_C2M_OUT(Addr_C2M_l1l2[1]), 
                   .en_C2M_IN(en_C2M_IN[1]), .Data_C2M_IN(Data_C2M_IN[1]), .Addr_C2M_IN(Addr_C2M_IN[1]), 
                   .en_M2C_OUT(en_M2C_OUT[1]), .Data_M2C_OUT(Data_M2C_OUT[1]), .AccessComplete_M2C_OUT(AccessComplete_M2C_OUT[1]));
endmodule


module NOC_R2
  (input logic clk, rst_l,
   input logic en_M2C_IN,
   input logic [`BIT_WIDTH-1:0] Data_M2C_IN,
   input logic [`AC_WIDTH:0] AccessComplete_M2C_IN,
   input logic [`RADIX-1:0] en_C2M_IN,
   input logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_C2M_IN,
   input logic [`RADIX-1:0][`ADDR_WIDTH-1:0] Addr_C2M_IN,
   output logic [`RADIX-1:0] en_M2C_OUT,
   output logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_M2C_OUT,
   output logic [`RADIX-1:0][`AC_WIDTH:0] AccessComplete_M2C_OUT,
   output logic en_C2M_OUT, 
   output logic [`BIT_WIDTH-1:0] Data_C2M_OUT,
   output logic [`ADDR_WIDTH-1:0] Addr_C2M_OUT);
  logic [`RADIX-1:0][`BIT_WIDTH+`ADDR_WIDTH-1:0] Data_Addr_C2M_Latched;
  logic [`BIT_WIDTH + `AC_WIDTH:0] Data_AccessComplete_M2C_Latched;
  logic [`AC_WIDTH:0] AccessComplete_M2C_Mod;
  logic [`RADIX_Width-1:0] mux_sel, demux_sel;

  genvar i;
  generate
    for (i = 0; i < `RADIX; i++) begin
      Buffer #(`BIT_WIDTH+`ADDR_WIDTH) Input_Port_Buffer(.clk, .rst_l, .en(en_C2M_IN[i]), .Buff_In({Data_C2M_IN[i], Addr_C2M_IN[i]}), .Buff_Out(Data_Addr_C2M_Latched[i]));
    end
  endgenerate

  Buffer #(`BIT_WIDTH+`AC_WIDTH+1) Read_Data_Buffer(.clk, .rst_l, .en(en_M2C_IN), .Buff_In({Data_M2C_IN, AccessComplete_M2C_IN}), .Buff_Out({Data_AccessComplete_M2C_Latched}));

  Destination_Decoder_R2 Dest_Decode(.clk, .rst_l, .en_C2M_IN, .AccessComplete_M2C_IN(Data_AccessComplete_M2C_Latched[`AC_WIDTH:0]), .en_C2M_OUT, .en_M2C_OUT,
                                  .mux_sel, .demux_sel, .AccessComplete_M2C_Mod);

  Mux2to1 #(`BIT_WIDTH+`ADDR_WIDTH) DestinationMux(.Input_Vector(Data_Addr_C2M_Latched), .Sel(mux_sel), .Output_Vector({Data_C2M_OUT, Addr_C2M_OUT}));

  DeMux2to1 #(`BIT_WIDTH+`AC_WIDTH+1) DestinationDeMux(.Input_Vector({Data_AccessComplete_M2C_Latched}), .Sel(demux_sel), 
                                                                  .Output_Vector({{Data_M2C_OUT[0], AccessComplete_M2C_OUT[0]}, {Data_M2C_OUT[1], AccessComplete_M2C_OUT[1]}}));
endmodule: NOC_R2


// module NOC
//   (input logic clk, rst_l,
//    input logic en_M2C_IN,
//    input logic [`BIT_WIDTH-1:0] Data_M2C_IN,
//    input logic [`AC_WIDTH:0] AccessComplete_M2C_IN,
//    input logic [`RADIX-1:0] en_C2M_IN,
//    input logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_C2M_IN,
//    input logic [`RADIX-1:0][`ADDR_WIDTH-1:0] Addr_C2M_IN,
//    output logic [`RADIX-1:0] en_M2C_OUT,
//    output logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_M2C_OUT,
//    output logic [`RADIX-1:0][`AC_WIDTH:0] AccessComplete_M2C_OUT,
//    output logic en_C2M_OUT, 
//    output logic [`BIT_WIDTH-1:0] Data_C2M_OUT,
//    output logic [`ADDR_WIDTH-1:0] Addr_C2M_OUT);
//   logic [`RADIX-1:0][`BIT_WIDTH+`ADDR_WIDTH-1:0] Data_Addr_C2M_Latched;
//   logic [`BIT_WIDTH + `AC_WIDTH:0] Data_AccessComplete_M2C_Latched;
//   logic [`AC_WIDTH:0] AccessComplete_M2C_Mod;
//   logic [`RADIX_Width-1:0] mux_sel, demux_sel;

//   genvar i;
//   generate
//     for (i = 0; i < `RADIX; i++) begin
//       Buffer #(`BIT_WIDTH+`ADDR_WIDTH) Input_Port_Buffer(.clk, .rst_l, .en(en_C2M_IN[i]), .Buff_In({Data_C2M_IN[i], Addr_C2M_IN[i]}), .Buff_Out(Data_Addr_C2M_Latched[i]));
//     end
//   endgenerate

//   Buffer #(`BIT_WIDTH+`AC_WIDTH+1) Read_Data_Buffer(.clk, .rst_l, .en(en_M2C_IN), .Buff_In({Data_M2C_IN, AccessComplete_M2C_IN}), .Buff_Out({Data_AccessComplete_M2C_Latched}));

//   Destination_Decoder_R4 Dest_Decode(.clk, .rst_l, .en_C2M_IN, .AccessComplete_M2C_IN(Data_AccessComplete_M2C_Latched[`AC_WIDTH:0]), .en_C2M_OUT, .en_M2C_OUT,
//                                   .mux_sel, .demux_sel, .AccessComplete_M2C_Mod);

//   Mux4to1 #(`BIT_WIDTH+`ADDR_WIDTH) DestinationMux(.Input_Vector(Data_Addr_C2M_Latched), .Sel(mux_sel), .Output_Vector({Data_C2M_OUT, Addr_C2M_OUT}));

//   DeMux4to1 #(`BIT_WIDTH+`AC_WIDTH+1) DestinationDeMux(.Input_Vector({Data_AccessComplete_M2C_Latched}), .Sel(demux_sel), 
//                                                                   .Output_Vector({{Data_M2C_OUT[0], AccessComplete_M2C_OUT[0]}, 
//                                                                                   {Data_M2C_OUT[1], AccessComplete_M2C_OUT[1]},
//                                                                                   {Data_M2C_OUT[2], AccessComplete_M2C_OUT[2]}, 
//                                                                                   {Data_M2C_OUT[3], AccessComplete_M2C_OUT[3]}}));
// endmodule: NOC


module Destination_Decoder_R2
  (input logic clk, rst_l,
   input logic [`RADIX-1:0] en_C2M_IN, 
   input logic [`AC_WIDTH:0] AccessComplete_M2C_IN, 
   output logic en_C2M_OUT, 
   output logic [`RADIX-1:0] en_M2C_OUT,
   output logic [$clog2(`RADIX)-1:0] mux_sel, demux_sel,
   output logic [`AC_WIDTH:0]AccessComplete_M2C_Mod);
  logic [`RADIX-1:0] data_Available;
  logic [`RADIX-1:0] data_Forwarded;

  genvar i;
  generate
    for (i = 0; i < `RADIX; i++) begin
      Register #(1) Availability(.D(en_C2M_IN[i]), .en(en_C2M_IN[i] || data_Forwarded[i]), .clear(1'b0), 
                            .clk(clk), .rst_l(rst_l), 
                            .Q(data_Available[i]));
    end
  endgenerate
  
  enum logic {MODE1, MODE2} currState, nextState;
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      currState <= MODE1;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    mux_sel = '0;
    en_C2M_OUT = 1'b0;
    data_Forwarded = '0;
    unique case(currState)
    MODE1: begin
      nextState = MODE2;
      if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    MODE2: begin
      nextState = MODE1;
      if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    endcase

    demux_sel = AccessComplete_M2C_IN[$clog2(`RADIX):1];
    en_M2C_OUT = demux_sel ? 2'b10 : 2'b01;
    AccessComplete_M2C_Mod = {$clog2(`RADIX)'(0), AccessComplete_M2C_IN[`AC_WIDTH:`AC_WIDTH-$clog2(`RADIX)], AccessComplete_M2C_IN[1]};
  end
endmodule


module Destination_Decoder_R4
  (input logic clk, rst_l,
   input logic [`RADIX-1:0] en_C2M_IN, 
   input logic [`AC_WIDTH:0] AccessComplete_M2C_IN, 
   output logic en_C2M_OUT, 
   output logic [`RADIX-1:0] en_M2C_OUT,
   output logic [$clog2(`RADIX)-1:0] mux_sel, demux_sel,
   output logic [`AC_WIDTH:0]AccessComplete_M2C_Mod);
  logic [`RADIX-1:0] data_Available;
  logic [`RADIX-1:0] data_Forwarded;

  genvar i;
  generate
    for (i = 0; i < `RADIX; i++) begin
      Register #(1) Availability(.D(en_C2M_IN[i]), .en(en_C2M_IN[i] || data_Forwarded[i]), .clear(1'b0), 
                            .clk(clk), .rst_l(rst_l), 
                            .Q(data_Available[i]));
    end
  endgenerate
  
  enum logic [1:0] {MODE1, MODE2, MODE3, MODE4} currState, nextState;
  always_ff @(posedge clk, negedge rst_l) begin
    if (~rst_l) begin
      currState <= MODE1;
    end
    else begin
      currState <= nextState;
    end
  end

  always_comb begin
    mux_sel = '0;
    en_C2M_OUT = 1'b0;
    data_Forwarded = '0;

    unique case(currState)
    MODE1: begin
      nextState = MODE2;
      if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[2]) begin
        mux_sel = (`RADIX_Width)'(2);
        data_Forwarded[2] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[3]) begin
        mux_sel = (`RADIX_Width)'(3);
        data_Forwarded[3] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    MODE2: begin
      nextState = MODE3;
      if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[2]) begin
        mux_sel = (`RADIX_Width)'(2);
        data_Forwarded[2] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[3]) begin
        mux_sel = (`RADIX_Width)'(3);
        data_Forwarded[3] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    MODE3: begin
      nextState = MODE4;
      if (data_Available[2]) begin
        mux_sel = (`RADIX_Width)'(2);
        data_Forwarded[2] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[3]) begin
        mux_sel = (`RADIX_Width)'(3);
        data_Forwarded[3] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    MODE4: begin
      nextState = MODE1;
      if (data_Available[3]) begin
        mux_sel = (`RADIX_Width)'(3);
        data_Forwarded[3] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[0]) begin
        mux_sel = (`RADIX_Width)'(0);
        data_Forwarded[0] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[1]) begin
        mux_sel = (`RADIX_Width)'(1);
        data_Forwarded[1] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
      else if (data_Available[2]) begin
        mux_sel = (`RADIX_Width)'(2);
        data_Forwarded[2] = 1'b1;
        en_C2M_OUT = 1'b1;
      end
    end
    endcase

    demux_sel = AccessComplete_M2C_IN[$clog2(`RADIX):1];
    case(demux_sel)
    2'b00: en_M2C_OUT = 4'b0001;
    2'b01: en_M2C_OUT = 4'b0010;
    2'b10: en_M2C_OUT = 4'b0100;
    2'b11: en_M2C_OUT = 4'b1000;
    endcase
    
    // en_M2C_OUT = demux_sel ? 2'b10 : 2'b01;
    AccessComplete_M2C_Mod = {$clog2(`RADIX)'(0), AccessComplete_M2C_IN[`AC_WIDTH:`AC_WIDTH-$clog2(`RADIX)], AccessComplete_M2C_IN[1]};
  end
endmodule
