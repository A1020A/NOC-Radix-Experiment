`default_nettype none
/***
single memory responding to mutiple cores
***/
module NOC_N3XT
  #(parameter BIT_WIDTH = 512, 
    parameter RADIX = 2,
    parameter NETWORK_DEPTH = 1,
    parameter ADDR_WIDTH = 32)
  (input logic clk, rst_l,
   input logic en_M2C_IN,
   input logic [BIT_WIDTH-1:0] Data_M2C_IN,
   input logic [$clog2(RADIX)*NETWORK_DEPTH:0] AccessComplete_M2C_IN,
   input logic [$clog2(RADIX)-1:0] en_C2M_IN,
   input logic [$clog2(RADIX)-1:0][BIT_WIDTH-1:0] Data_C2M_IN,
   input logic [$clog2(RADIX)-1:0][ADDR_WIDTH-1:0] Addr_C2M_IN,
   output logic en_M2C_OUT,
   output logic [BIT_WIDTH-1:0] Data_M2C_OUT,
   output logic [$clog2(RADIX)*NETWORK_DEPTH:0] AccessComplete_M2C_OUT,
   output logic en_C2M_OUT, 
   output logic [BIT_WIDTH-1:0] Data_C2M_OUT,
   output logic [ADDR_WIDTH-1:0] Addr_C2M_OUT);
  logic [$clog2(RADIX)-1:0][BIT_WIDTH+ADDR_WIDTH-1:0] Data_Addr_C2M_Latched;
  logic [BIT_WIDTH + $clog2(RADIX)*NETWORK_DEPTH] Data_AccessComplete_M2C_Latched;
  logic mux_sel, demux_sel;
  genvar i;
  generate
    for (i = 0; i < RADIX; i++) begin
      Buffer #(BIT_WIDTH+ADDR_WIDTH) Input_Port_Buffer(.clk, .rst_l, .en(en_C2M_IN[i]), .Buff_In({Data_C2M_IN[i], Addr_C2M_IN[i]}), .Buff_Out());
    end
  endgenerate

  Buffer #(BIT_WIDTH + $clog2(RADIX)*NETWORK_DEPTH+1) Read_Data_Buffer(.clk, .rst_l, .en())

  Destination_Decoder #(ADDR_WIDTH, RADIX, NETWORK_DEPTH) Dest_Decode(.clk, .rst_l, .en_C2M_IN, .AccessComplete_M2C_IN, .en_C2M_OUT, 
                                                                      .mux_sel, .demux_sel, .AccessComplete_M2C_OUT);
  
  Mux2to1 #(BIT_WIDTH+ADDR_WIDTH) DestinationMux(.Input_Vector(Data_Addr_C2M_Latched), .Sel(mux_sel), .Output_Vector({Data_C2M_OUT, Addr_C2M_OUT}));

  DeMux2to1 #(BIT_WIDTH+ADDR_WIDTH) DestinationDeMux(.Input_Vector(), .Sel, .Output_Vector())
endmodule


module Destination_Decoder
  #(parameter ADDR_WIDTH = 32,
    parameter RADIX = 2,
    parameter NETWORK_DEPTH = 1)
  (input logic clk, rst_l,
  //  input logic [$clog2(RADIX)-1:0][ADDR_WIDTH-1:0] Addr_C2M_IN, 
   input logic [$clog2(RADIX)-1:0] en_C2M_IN, 
   input logic [$clog2(RADIX)*NETWORK_DEPTH:0] AccessComplete_M2C_IN, 
   output logic en_C2M_OUT,
   output logic [$clog2(RADIX)-1:0] mux_sel, demux_sel
   output logic [$clog2(RADIX)*NETWORK_DEPTH:0] AccessComplete_M2C_OUT, );
  logic [$clog2(RADIX)-1:0] data_Available;
  logic [$clog2(RADIX)-1:0] data_Forwarded;

  genvar i;
  generate
    for (i = 0; i < RADIX, i++) begin
      Register Availability(.D(en_C2M_IN[i]), .en(en_C2M_IN[i] || data_Forwarded[i]), .clear(1'b0), 
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
      nextState <= MODE2;
      if (data_Available[0]) begin
        mux_sel <= ($clog2(RADIX))'d0;
        data_Forwarded[0] <= 1'b1;
        en_C2M_OUT <= 1'b1;
      end
      else if (data_Available[1]) begin
        mux_sel <= ($clog2(RADIX))'d1;
        data_Forwarded[1] <= 1'b1;
        en_C2M_OUT <= 1'b1;
      end
    end
    MODE2: begin
      nextState <= MODE1;
      if (data_Available[1]) begin
        mux_sel <= ($clog2(RADIX))'d1;
        data_Forwarded[1] <= 1'b1;
        en_C2M_OUT <= 1'b1;
      end
      else if (data_Available[0]) begin
        mux_sel <= ($clog2(RADIX))'d0;
        data_Forwarded[0] <= 1'b1;
        en_C2M_OUT <= 1'b1;
      end
    end
    endcase

    demux_sel = AccessComplete_M2C_IN[$clog2(RADIX):1];
    AccessComplete_M2C_OUT = {$clog2(RADIX)'d0, AccessComplete_M2C_IN[$clog2(RADIX)*NETWORK_DEPTH:$clog2(RADIX)+1], AccessComplete_M2C_IN[1]};
  end
endmodule

