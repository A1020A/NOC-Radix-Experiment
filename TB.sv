`default_nettype none
// module TOP();
//   logic clk, rst_l;

//   logic FIFO_M2C_ENQ;
//   logic [`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_M2C_IN;
//   logic FIFO_M2C_FULL;

//   logic [`RADIX-1:0] FIFO_M2C_ENQ_downstream;
//   logic [`RADIX-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_M2C_OUT;
//   logic [`RADIX-1:0] FIFO_M2C_FULL_downstream;
  

//   logic [`RADIX-1:0] FIFO_C2M_ENQ;
//   logic [`RADIX-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_C2M_IN;
//   logic [`RADIX-1:0] FIFO_C2M_FULL;

//   logic FIFO_C2M_ENQ_downstream;
//   logic [`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_C2M_OUT;
//   logic FIFO_C2M_FULL_downstream;
  
//   NOC noc_DUT(.*);

//   initial begin
//     clk = 1'b0;
//     forever #5 clk = ~clk;
//   end

//   initial begin
//     rst_l = 1'b0;
//     rst_l <= 1'b1;

//     FIFO_M2C_ENQ = 1'b0;
//     FIFO_M2C_IN = {{1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};

//     FIFO_M2C_FULL_downstream = 2'b11;

//     FIFO_C2M_ENQ = {(`RADIX){1'b0}};
//     FIFO_C2M_IN = {{1'b1}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b0}}, {1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};
//     // {{(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b1}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}};
//     FIFO_C2M_FULL_downstream = 1'b1;

//     @(posedge clk);
//     FIFO_M2C_ENQ = 1'b1;
//     FIFO_M2C_FULL_downstream = 2'b00;
//     @(posedge clk);
//     FIFO_M2C_IN = {{1'b1}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b0}}};
//     @(posedge clk);
//     FIFO_M2C_ENQ = 1'b0;
//     @(posedge clk);
//     @(posedge clk);
//     @(posedge clk);
//     FIFO_M2C_FULL_downstream = 2'b11;
//     FIFO_C2M_ENQ = 2'b11;
//     FIFO_C2M_FULL_downstream = 1'b0;
//     @(posedge clk);
//     FIFO_C2M_ENQ = 2'b00;
//     @(posedge clk);
//     @(posedge clk);
//     @(posedge clk);



//     // en_M2C_IN = 1'b0;
//     // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
//     // AccessComplete_M2C_IN = '0;

//     // en_C2M_IN = 2'b00;
//     // Data_C2M_IN = {(`BIT_WIDTH*2){1'b1}};
//     // Addr_C2M_IN = {(`ADDR_WIDTH*2){1'b1}};

//     // @(posedge clk);
//     // en_M2C_IN = 1'b1;
//     // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
//     // AccessComplete_M2C_IN = 2'b11;

//     // en_C2M_IN = 2'b01;
//     // Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
//     // Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

//     // @(posedge clk);
//     // en_M2C_IN = 1'b1;
//     // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
//     // AccessComplete_M2C_IN = 2'b01;

//     // en_C2M_IN = 2'b10;
//     // Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
//     // Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

//     #15;
//     $finish();
//   end
// endmodule 

module TOP ();
  logic clk, rst_l;
  logic [16-1:0] data_in, data_out;
  logic we, re, full, almost_full, empty, D_test;

  FIFO_sreg #(.WIDTH(16), .DEPTH(4)) fifo (
    .clk(clk), .rst_l(rst_l),
    .data_in(data_in), .we(we), .re(re),
    .data_out(data_out),
    .full(full), .empty(empty)
  );  

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_l = 1'b0;
    rst_l <= 1'b1;

    data_in = 16'd0;
    we = 1'b0;
    re = 1'b0;
    D_test = 0;

    @(posedge clk);
    we = 1'b1;
    data_in = 16'd1;
    @(posedge clk);
    we = 1'b0;
    re = 1'b1;
    @(posedge clk);
    we = 1'b1;
    re = 1'b0;
    data_in = 16'd1;
    @(posedge clk);
    data_in = 16'd2;
    @(posedge clk);
    we = 1'b0;
    re = 1'b1;
    @(posedge clk);
    data_in = 16'd3;
    re = 1'b0;
    we = 1'b1;
    @(posedge clk);
    data_in = 16'd4;
    @(posedge clk);
    data_in = 16'd5;
    re = 1'b1;
    @(posedge clk);
    re = 1'b0;
    data_in = 16'd6;
    @(posedge clk);
    data_in = 16'd7;
    re = 1'b1;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $finish();
  end

endmodule

// module FIFO_sreg #(parameter WIDTH=512+32, DEPTH = 2) (
//   input logic             clk, rst_l,
//   input logic [WIDTH-1:0] data_in,
//   input logic             we, re,
//   input logic D_test,
//   output logic [WIDTH-1:0] data_out,
//   output logic             full, empty, almost_full
// );
//   logic [DEPTH-1:0][WIDTH-1:0] Q;
//   logic [WIDTH-1:0] D;
//   logic [$clog2(DEPTH):0] putPtr_q, putPtr_d;
//   assign full = (putPtr_q == DEPTH);
//   assign almost_full = (putPtr_q == DEPTH - 1);
//   assign empty = (putPtr_q == 0);
//   assign data_out = Q[0];
//   logic Q_test, we_test;
//   // assign D = we ? data_in : '0;

//   always_comb begin
//     if (we && re) begin
//       if (empty) $fatal("FIFO empty, read and write at the same time");
//       putPtr_d = putPtr_q;
//     end
//     else if (re) begin
//       if (empty) $fatal("FIFO empty");
//       putPtr_d = putPtr_q - 1;
//     end
//     else if (we) begin
//       if (full) $fatal("FIFO full");
//       putPtr_d = putPtr_q + 1;
//     end
//     else begin
//       putPtr_d = putPtr_q;
//     end
//     // D = we ? data_in : '0;
//   end

//   always_ff @(posedge clk, negedge rst_l) begin
//     if (~rst_l) begin
//       Q <= '0;
//       putPtr_q <= 0;
//     end
//     else begin
//       if (re) begin
//         for (int i  = 0; i < DEPTH; i++) begin
//           if (i < putPtr_d) begin
//             Q[i] <= Q[i+1];
//           end
//           else if (i == putPtr_d) begin
//             if (we) begin
//               Q[i] <= data_in;
//             end
//             else begin
//               Q[i] <= '0;
//             end
//           end
//           else begin
//             Q[i] <= '0;
//           end
//         end
//       end
//       else if (we) begin
//         Q[putPtr_q] <= data_in;
//         // $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q, D);
//       end
//       else begin
//         Q[putPtr_q] <= '0;
//         // $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q, D);
//       end
//       putPtr_q <= putPtr_d;
//     end
//   end

//   always_ff @(posedge clk, negedge rst_l) begin
//     we_test = (we & D_test) &&(!full);
//     if (~rst_l) begin
//       Q_test <= '0;
//     end
//     else begin
//       if (we_test) begin
//         Q_test <= D_test;
//       end
//       else begin
//         Q_test <= '0;
//       end
      
//     end
//   end
// endmodule

module FIFO_sreg #(parameter WIDTH=512+32, DEPTH = 2) (
  input logic             clk, rst_l,
  input logic [WIDTH-1:0] data_in,
  input logic             we, re,
  output logic [WIDTH-1:0] data_out,
  output logic             full, empty, almost_full
);
  logic [WIDTH-1:0] D;
  logic [DEPTH-1:0][WIDTH-1:0] Q; 
  logic [$clog2(DEPTH):0] putPtr_q, putPtr_d;
  assign data_out = Q[0];
  assign empty = (putPtr_q == 0);
  assign full = (putPtr_q == DEPTH);
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
        $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q-1, D);
        putPtr_q <= putPtr_q;
      end
      else if (re) begin
        if (empty) $fatal("FIFO empty");
        putPtr_q <= putPtr_q - 1;
      end
      else if (we) begin
        if (full) $fatal("FIFO full");
        Q[putPtr_q] <= D;
        $display("at time: [%0d] Q[%0d] = %0d", $time, putPtr_q, D);
        putPtr_q <= putPtr_q + 1;
      end
      else begin
        putPtr_q <= putPtr_q;
      end
    end
  end

endmodule