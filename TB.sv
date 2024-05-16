`default_nettype none
module TOP();
  logic clk, rst_l;

  logic FIFO_M2C_ENQ;
  logic [`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_M2C_IN;
  logic FIFO_M2C_FULL;

  logic [`RADIX-1:0] FIFO_M2C_ENQ_downstream;
  logic [`RADIX-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_M2C_OUT;
  logic [`RADIX-1:0] FIFO_M2C_FULL_downstream;
  

  logic [`RADIX-1:0] FIFO_C2M_ENQ;
  logic [`RADIX-1:0][`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_C2M_IN;
  logic [`RADIX-1:0] FIFO_C2M_FULL;

  logic FIFO_C2M_ENQ_downstream;
  logic [`ADDR_WIDTH+`DATA_WIDTH-1:0] FIFO_C2M_OUT;
  logic FIFO_C2M_FULL_downstream;
  
  NOC noc_DUT(.*);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_l = 1'b0;
    rst_l <= 1'b1;

    FIFO_M2C_ENQ = 1'b0;
    FIFO_M2C_IN = {{1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};

    FIFO_M2C_FULL_downstream = 2'b11;

    FIFO_C2M_ENQ = {(`RADIX){1'b0}};
    FIFO_C2M_IN = {{1'b1}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b0}}, {1'b0}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b1}}};
    // {{(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b1}}, {(`ADDR_WIDTH + `DATA_WIDTH){1'b0}}};
    FIFO_C2M_FULL_downstream = 1'b1;

    @(posedge clk);
    FIFO_M2C_ENQ = 1'b1;
    FIFO_M2C_FULL_downstream = 2'b00;
    @(posedge clk);
    FIFO_M2C_IN = {{1'b1}, {(`ADDR_WIDTH + `DATA_WIDTH - 1){1'b0}}};
    @(posedge clk);
    FIFO_M2C_ENQ = 1'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    FIFO_M2C_FULL_downstream = 2'b11;
    FIFO_C2M_ENQ = 2'b11;
    FIFO_C2M_FULL_downstream = 1'b0;
    @(posedge clk);
    FIFO_C2M_ENQ = 2'b00;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);



    // en_M2C_IN = 1'b0;
    // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    // AccessComplete_M2C_IN = '0;

    // en_C2M_IN = 2'b00;
    // Data_C2M_IN = {(`BIT_WIDTH*2){1'b1}};
    // Addr_C2M_IN = {(`ADDR_WIDTH*2){1'b1}};

    // @(posedge clk);
    // en_M2C_IN = 1'b1;
    // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    // AccessComplete_M2C_IN = 2'b11;

    // en_C2M_IN = 2'b01;
    // Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
    // Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

    // @(posedge clk);
    // en_M2C_IN = 1'b1;
    // Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    // AccessComplete_M2C_IN = 2'b01;

    // en_C2M_IN = 2'b10;
    // Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
    // Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

    #15;
    $finish();
  end
endmodule 