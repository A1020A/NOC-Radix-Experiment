`default_nettype none
module TOP();
  logic clk, rst_l;
  //M2C_IN
  logic en_M2C_IN;
  logic [`BIT_WIDTH-1:0] Data_M2C_IN;
  logic [`AccessComplete_Width:0] AccessComplete_M2C_IN;
  //C2M_IN
  logic [`RADIX-1:0] en_C2M_IN;
  logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_C2M_IN;
  logic [`RADIX-1:0][`ADDR_WIDTH-1:0] Addr_C2M_IN;
  //M2C_OUT
  logic [`RADIX-1:0] en_M2C_OUT;
  logic [`RADIX-1:0][`BIT_WIDTH-1:0] Data_M2C_OUT;
  logic [`RADIX-1:0][`AccessComplete_Width:0] AccessComplete_M2C_OUT;
  //C2M_OUT
  logic en_C2M_OUT;
  logic [`BIT_WIDTH-1:0] Data_C2M_OUT;
  logic [`ADDR_WIDTH-1:0] Addr_C2M_OUT;

  NOC noc_DUT(.*);

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    rst_l = 1'b0;
    rst_l <= 1'b1;

    en_M2C_IN = 1'b0;
    Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    AccessComplete_M2C_IN = '0;

    en_C2M_IN = 2'b00;
    Data_C2M_IN = {(`BIT_WIDTH*2){1'b1}};
    Addr_C2M_IN = {(`ADDR_WIDTH*2){1'b1}};

    @(posedge clk);
    en_M2C_IN = 1'b1;
    Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    AccessComplete_M2C_IN = 2'b11;

    en_C2M_IN = 2'b01;
    Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
    Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

    @(posedge clk);
    en_M2C_IN = 1'b1;
    Data_M2C_IN = {`BIT_WIDTH{1'b1}};
    AccessComplete_M2C_IN = 2'b01;

    en_C2M_IN = 2'b10;
    Data_C2M_IN = {{(`BIT_WIDTH/2){1'b1}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b0}}, {(`BIT_WIDTH/2){1'b1}}};
    Addr_C2M_IN = {{(`ADDR_WIDTH/2){1'b1}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b0}}, {(`ADDR_WIDTH/2){1'b1}}};

    #15;
    $finish();
  end
endmodule 