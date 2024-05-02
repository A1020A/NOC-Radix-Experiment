`default_nettype none
module TB();
  logic clk, rst_l;

  logic [`RADIX_IN-1:0] FIFO_ENQ;
  logic [`RADIX_IN-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_IN;
  logic [`RADIX_IN-1:0] FIFO_FULL; 

  logic [`RADIX_OUT-1:0] FIFO_ENQ_downstream;
  logic [`RADIX_OUT-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_OUT;
  logic [`RADIX_OUT-1:0] FIFO_FULL_downstream;

  NOC_CrossBar DUT(.*);
  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_l = 1'b0;
    rst_l <= 1'b1;
    FIFO_ENQ = {(`RADIX_IN){1'b0}};
    FIFO_IN = {{1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b0}}, {1'b1}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};
    FIFO_FULL_downstream = {(`RADIX_OUT){1'b1}};

    @(posedge clk);
    FIFO_ENQ = {(`RADIX_IN){1'b1}};
    FIFO_FULL_downstream = {(`RADIX_OUT){1'b0}};
    @(posedge clk);
    FIFO_IN = {{1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}, {1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};
    // FIFO_ENQ = {(`RADIX_IN-1){1'b0}, {1'b1}};
    @(posedge clk);
    FIFO_ENQ = {(`RADIX_IN){1'b0}};
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $finish();
  end

endmodule