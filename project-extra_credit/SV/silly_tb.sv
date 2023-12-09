`timescale 1ns / 1ps
module stimulus ();
logic   clk;
logic   [1023:0] seed;
logic   reset;
logic   [1023:0]r2m;
logic   [1023:0]out_grid;
logic   [1023:0]grid_evolve;
logic start;
logic pause;

integer handle3;
integer desc3;


GameOfLife dut(seed, clk, pause, start, out_grid);

initial
    begin
       clk = 1'b1;
       forever #5 clk = ~clk; 
    end

initial
    begin
    handle3 = $fopen("grid.out");
    desc3 = handle3;
    #10000 $finish;
    end


always @(negedge clk)
    begin
    $fdisplay(desc3, "\n\n\n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b \n %b", out_grid[255:240], out_grid[239:224], out_grid[223:208], out_grid[207:192], out_grid[191:176], 
    out_grid[175:160], out_grid[159:144], out_grid[143:128], out_grid[127:112], out_grid[111:96], out_grid[95:80], out_grid[79:64], out_grid[63:48], out_grid[47:32], out_grid[31:16], out_grid[15:0]);
    end

initial
 begin
 //seed = 1024'h0000e00000;
 seed= 1024'b0011010100011011000111100110101101110111010010111000110001100111010110011101111101111111101001001100101000010000101011010100110001011011111010110111100111000010011000011100011111010001100111011100110010111001001000101111101110010101000001110001011110101101001110100111101010101100001000100010100000111001111011111110111111001000110000011101011011101010110100100000011110101100100001001011111000000101111010100011000001110111000110100001001001000000100010111010010111101111110001011010100011100101001111000000011001111010101010101001011001011100110010000111101000010010000000010111110011111101001011011010110100110110000111000111010111000111111011011011010001011001111001100100010100000010001011010001011101111010011001000101000001010000100000001101100001101000000110001010100000100110011010111011100100010111110101011111011111001111011110000010010001010100110110010001111101111101101110111110111111110001111001110001011101111111001100101111010101100110110101000011010111011110000001111011011010001111010110010101000000101101;
 #0 start = 1'b0;
 #0 reset = 1'b1;
 #20 start = 1'b1;
//#20 reset = 1'b0;

 #20 pause = 1'b1;
 #1000 pause = 1'b0;
//#40 reset = 1'b1;
 
 end

endmodule