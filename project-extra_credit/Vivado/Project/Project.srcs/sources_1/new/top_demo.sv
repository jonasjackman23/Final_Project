`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01/15/2021 06:40:11 PM
// Design Name: 
// Module Name: top_demo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module top_demo
(
  // input
  input  logic [7:0] sw,
  input  logic [3:0] btn,
  input  logic       sysclk_125mhz,
  input  logic       rst,
  
 
  // output  
  output logic [7:0] led,
  output logic       sseg_ca,
  output logic       sseg_cb,
  output logic       sseg_cc,
  output logic       sseg_cd,
  output logic       sseg_ce,
  output logic       sseg_cf,
  output logic       sseg_cg,
  output logic       sseg_dp,
  output logic [3:0] sseg_an,
  output logic [2:0] hdmi_d_p,  
  output logic [2:0] hdmi_d_n,   
  output logic       hdmi_clk_p,   
  output logic	     hdmi_clk_n,
   
  inout logic	     hdmi_cec,  
  inout logic	     hdmi_sda,   
  inout logic	     hdmi_scl,   
  input logic	     hdmi_hpd
);

  logic [23:0]aliveColor;
  logic [23:0]deadColor;
  logic [23:0]backgroundColor;

  logic [16:0] CURRENT_COUNT;
  logic [16:0] NEXT_COUNT;
  logic        smol_clk;
  logic [1023:0] seed;
  logic reset;
  logic [1023:0] out_grid;
  assign nextSeed = btn[1];
  assign reset = btn[0];
  assign pause = sw[6];
  assign start = sw[7];
  
  always @(*) begin
  case(sw[1:0]) 
    2'b00 : begin seed = 1024'h11000010110001eeeeeeeee11110011011011000101110100111110101110111011101011111001010010000001011010100000001010011101001000110010100001101101100001110000100001001101100110011110101000000111011001101111011001010100101000101100110111111000100001110111000110011011100101111010010110111101000111111110001111111101001011111111111111100001100001101101010010101110110101100100010000100000101100100101010001001111000000011110110100010101101011000001001001011000101110101110000001001110000111100101001110010010111001001101011110100110001100110101001000001110000001010011000111000111110010011111010011111011000111011100010101110001101110100101001111010111001100111010010101010100110010010000101110110110000011010001101110111011001111110110110110110101001110011110111100000110001100011010001010010010010100011111100010100100001011011011110001111110001010010111011111111001001111001010111010110101001110010000101100101101110100100000011100011001011110001110000101110011101111010100110100000101001111011011000101111001000100010101101000001001111111;
        
        end
    2'b01 : begin seed = 1024'b1101111010000001111001111011011001001111000011100000000101001111100011010000010100111001011111001110000000111001110111110011110101101110000011010001101001110010101010111111110011010110011010101101110001110010001011110101111010101011101111101011010011011101100101111001110000000111110111101001110000111010110001010110001100001011110001001100011111010101000010010111110100100011111110001000000001000010000100110111101110010110101111001010010011111111000001100111111101100011100010100000100100100100001111000111011011111101100001010011010010011010111000110000101100001110100101011111011011001010001001101110100100010011111001101000111011010111110010010000000110111101111101110001101011110001111000010010001110010100101101111010001010100011011011000000110100110001101000010110101000100111011001100001101011010001001100101011001110010011100111011100110101111100110010001100101110010011101010110110000010100010000100001010101000111011101100100101010101001111001010111000111010110101001110010101011001101111001001100101001010000010;
          end
          //gliders
    2'b10 : begin seed = 1024'b0010000000000000000000000000000010100000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000101000000000000000000000000000001100000000000000000000000000000000000000001000000000000000000000000000000001100000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000010100000000000000000000000000000110;
end
           //DLD 23 GO POKES
    2'b11 : begin 
         seed = 1024'b0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001110010000111000011100011000000010010100001001001000101001000000100101000010010000010000100000001110011110111000010000100100000000000000000000001111100110000000000000000000000000000000000000000111000111010001000000000000000010001010000100010000000000000000100010011001000100000000000000001000100001010001000000000000000001110011100011100000000000000000000000000000000000000000000000000111000111000000000000000000000010000010001000000000000000000000100110100010000000000000000000001000101000100000000000000000000001110001110000000000000000000000000000000000000000000000000000000111000111001000101111001100000001001010001010010010000100100000011100100010101000111000100000000100001000101100001000000100000001000010001010100010000100100000010000011100100100111100110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;end
endcase
end
  always @(*) begin
  case(sw[4:2]) 
    3'b000 : begin 
        backgroundColor = {8'hff, 8'h0d, 8'h2b};
        aliveColor = {8'h14, 8'hb4, 8'hff};
        deadColor = {8'hff, 8'hf6, 8'h14};
        end
    3'b010 : begin 
        backgroundColor = {8'ha3, 8'h0f, 8'hff};
        aliveColor = {8'h14, 8'hff, 8'h7e};
        deadColor = {8'hff, 8'hab, 8'h14};
          end
    3'b100 : begin 
        backgroundColor = {8'hff, 8'h14, 8'h77};
        aliveColor = {8'hff, 8'he6, 8'h00};
        deadColor = {8'h00, 8'hd5, 8'hff};
          end
        //osu    
    3'b110 : begin 
        backgroundColor = {8'h00, 8'h00, 8'h00};
        aliveColor = {8'hff, 8'h4d, 8'h00};
        deadColor = {8'hFF, 8'hFF, 8'hFF};
        end
        //dracula
     3'b001 : begin 
        backgroundColor = {8'h00, 8'h00, 8'h00};
        aliveColor = {8'hff, 8'hff, 8'hff};
        deadColor = {8'hdb, 8'h00, 8'h00};
        end
        //forrest
    3'b011 : begin 
        backgroundColor = {8'h04, 8'h47, 8'h1c};
        aliveColor = {8'h05, 8'h8C, 8'h42};
        deadColor = {8'h67, 8'h3d, 8'h13};
          end
        //silver and gold(precious ore)
    3'b101 : begin 
        backgroundColor = {8'h00, 8'h00, 8'h00};
        aliveColor = {8'hd4, 8'haf, 8'h37};
        deadColor = {8'hc0, 8'hc0, 8'hc0};
          end  
          //ocean breeze  
    3'b111 : begin 
        backgroundColor = {8'h04, 8'h56, 8'h76};
        aliveColor = {8'hff, 8'h4d, 8'h00};
        deadColor = {8'h0B, 8'hA4, 8'h95};
        end
  endcase
  end
  // Place Conway Game of Life instantiation here
  clk_div clk_slowed(sysclk_125mhz, reset, clk_en);
  GameOfLife g1(seed, clk_en, reset, pause , start, out_grid);

  // HDMI
  // logic hdmi_out_en;
  //assign hdmi_out_en = 1'b0;
  hdmi_top test (backgroundColor,aliveColor,deadColor, out_grid, sysclk_125mhz, hdmi_d_p, hdmi_d_n, hdmi_clk_p, 
		         hdmi_clk_n, hdmi_cec, hdmi_sda, hdmi_scl, hdmi_hpd);
  
  // 7-segment display
  segment_driver driver(
  .clk(smol_clk),
  .rst(btn[3]),
  .digit0(sw[3:0]),
  .digit1(4'b0111),
  .digit2(sw[7:4]),
  .digit3(4'b1111),
  .decimals({1'b0, btn[2:0]}),
  .segment_cathodes({sseg_dp, sseg_cg, sseg_cf, sseg_ce, sseg_cd, sseg_cc, sseg_cb, sseg_ca}),
  .digit_anodes(sseg_an)
  );

// Register logic storing clock counts
  always@(posedge sysclk_125mhz)
  begin
    if(btn[3])
      CURRENT_COUNT = 17'h00000;
    else
      CURRENT_COUNT = NEXT_COUNT;
  end
  
  // Increment logic
  assign NEXT_COUNT = CURRENT_COUNT == 17'd100000 ? 17'h00000 : CURRENT_COUNT + 1;

  // Creation of smaller clock signal from counters
  assign smol_clk = CURRENT_COUNT == 17'd100000 ? 1'b1 : 1'b0;

endmodule

module clk_div (input logic clk, input logic rst, output logic clk_en);


   logic [23:0] clk_count;

   always_ff @(posedge clk) begin
      if (rst)
	clk_count <= 24'h0;
      else
	clk_count <= clk_count + 1;
   end   
   
   assign clk_en = clk_count[23];
   
endmodule // clk_div