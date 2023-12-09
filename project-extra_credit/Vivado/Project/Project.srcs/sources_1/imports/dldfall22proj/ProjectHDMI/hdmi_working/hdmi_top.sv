module hdmi_top (backgroundColor,aliveColor, deadColor, n2,CLK_125MHZ, HDMI_TX, HDMI_TX_N, HDMI_CLK, 
		 HDMI_CLK_N, HDMI_CEC, HDMI_SDA, HDMI_SCL, HDMI_HPD, ac_bclk, ac_mclk, ac_muten, ac_pbdat, ac_pblrc,
		 ac_recdat, ac_reclrc, ac_scl, ac_sda);
		 
 
   input  logic [1023:0] n2;
  
   input logic         CLK_125MHZ;   

   // HDMI output
   output logic [2:0]  HDMI_TX;   
   output logic [2:0]  HDMI_TX_N;   
   output logic        HDMI_CLK;   
   output logic	       HDMI_CLK_N;
   
   input logic	       HDMI_CEC;   
   inout logic	       HDMI_SDA;   
   inout logic	       HDMI_SCL;   
   input logic	       HDMI_HPD;

   logic 	           clk_pixel_x5;
   logic 	           clk_pixel;
   logic 	           clk_audio;
   logic [23:0] 	      DataIn; // RGB Data to HDMI
   
   //Audio Out
   output logic    ac_bclk;
   output logic    ac_mclk;
   output logic    ac_muten;
   output logic    ac_pbdat;
   output logic    ac_pblrc;
   output logic    ac_recdat;
   output logic    ac_reclrc;
   output logic    ac_scl;
   output logic    ac_sda;
   
   
   hdmi_pll_xilinx hdmi_pll (.clk_in1(CLK_125MHZ), .clk_out1(clk_pixel), .clk_out2(clk_pixel_x5));
   
   logic [10:0]        counter = 1'd0;
   always_ff @(posedge clk_pixel)
     begin
	counter <= counter == 11'd1546 ? 1'd0 : counter + 1'd1;
     end
   assign clk_audio = clk_pixel && counter == 11'd1546;
   
   localparam AUDIO_BIT_WIDTH = 16;
   localparam AUDIO_RATE = 48000;
   localparam WAVE_RATE = 480;

   // This is to avoid giving you a heart attack -- it'll be really loud if it uses the full dynamic range.   
   logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word;
   logic [AUDIO_BIT_WIDTH-1:0] audio_sample_word_dampened; 
   assign audio_sample_word_dampened = audio_sample_word >> 9;
   
   //sawtooth #(.BIT_WIDTH(AUDIO_BIT_WIDTH), .SAMPLE_RATE(AUDIO_RATE), 
   //.WAVE_RATE(WAVE_RATE)) sawtooth (.clk_audio(clk_audio), .level(audio_sample_word));

   logic [23:0] 	   rgb;
   logic [10:0] 		   cx, cy;
   logic [2:0] 		   tmds;
   logic 		       tmds_clock;
   
   hdmi #(.VIDEO_ID_CODE(4), .VIDEO_REFRESH_RATE(60.0), .AUDIO_RATE(AUDIO_RATE), 
	  .AUDIO_BIT_WIDTH(AUDIO_BIT_WIDTH)) 
   hdmi(.clk_pixel_x5(clk_pixel_x5), .clk_pixel(clk_pixel), .clk_audio(clk_audio), 
	.rgb(DataIn), .audio_sample_word('{audio_sample_word_dampened, audio_sample_word_dampened}), 
	.tmds(tmds), .tmds_clock(tmds_clock), .cx(cx), .cy(cy));

   genvar 		       i;
   generate
      for (i = 0; i < 3; i++)
	  begin: obufds_gen
        OBUFDS #(.IOSTANDARD("TMDS_33")) obufds (.I(tmds[i]), .O(HDMI_TX[i]), .OB(HDMI_TX_N[i]));
	  end
      OBUFDS #(.IOSTANDARD("TMDS_33")) obufds_clock(.I(tmds_clock), .O(HDMI_CLK), .OB(HDMI_CLK_N));
   endgenerate
   
   /*   logic [7:0] character = 8'h30;
   logic [5:0] prevcy = 6'd0;
   always @(posedge clk_pixel)
     begin
	if (cy == 10'd0)
	  begin
             character <= 8'h30;
             prevcy <= 6'd0;
	  end
	else if (prevcy != cy[9:4])
	  begin
             character <= character + 8'h01;
             prevcy <= cy[9:4];
	  end
     end */
   
   // console console(.clk_pixel(clk_pixel), .codepoint(character), 
   //		   .attribute({cx[9], cy[8:6], cx[8:5]}), .cx(cx), .cy(cy), .rgb(rgb));
   
   
   // Game of Life screen configuration
   // Skip each block
   parameter    SKIP = 5; 
   // Distance to each block to block
   parameter	SEGMENT = 20;
   // Starting position (START,START)
   parameter	START = 30;   
   
   // Color Choice
   input logic [23:0]aliveColor,deadColor,backgroundColor;
   logic [23:0] alive, dead, background;
   assign alive = aliveColor;//{8'hFF, 8'hA5, 8'h00};
   assign dead  = deadColor;//{8'hFF, 8'hFF, 8'hFF};
   assign background = backgroundColor;

   always @(posedge CLK_125MHZ)
     begin	
       
	if (cy < START)
	  DataIn <= {background};
	
	
//Row 1
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[1023] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[1022] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[1021] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[1020] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[1019] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[1018] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[1017] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[1016] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[1015] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[1014] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[1013] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[1012] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[1011] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[1010] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[1009] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[1008] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[1007] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[1006] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[1005] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[1004] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[1003] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[1002] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[1001] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[1000] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[999] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[998] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[997] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[996] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[995] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[994] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[993] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[992] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*0) && (cy <= START+SEGMENT*1-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*1-SKIP) && (cy <= START+SEGMENT*1))
        DataIn <= background;

//Row 2
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[991] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[990] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[989] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[988] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[987] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[986] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[985] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[984] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[983] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[982] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[981] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[980] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[979] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[978] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[977] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[976] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[975] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[974] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[973] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[972] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[971] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[970] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[969] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[968] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[967] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[966] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[965] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[964] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[963] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[962] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[961] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[960] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*1) && (cy <= START+SEGMENT*2-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*2-SKIP) && (cy <= START+SEGMENT*2))
        DataIn <= background;

//Row 3
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[959] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[958] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[957] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[956] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[955] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[954] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[953] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[952] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[951] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[950] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[949] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[948] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[947] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[946] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[945] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[944] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[943] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[942] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[941] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[940] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[939] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[938] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[937] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[936] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[935] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[934] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[933] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[932] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[931] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[930] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[929] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[928] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*2) && (cy <= START+SEGMENT*3-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*3-SKIP) && (cy <= START+SEGMENT*3))
        DataIn <= background;

//Row 4
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[927] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[926] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[925] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[924] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[923] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[922] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[921] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[920] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[919] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[918] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[917] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[916] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[915] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[914] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[913] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[912] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[911] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[910] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[909] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[908] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[907] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[906] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[905] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[904] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[903] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[902] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[901] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[900] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[899] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[898] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[897] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[896] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*3) && (cy <= START+SEGMENT*4-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*4-SKIP) && (cy <= START+SEGMENT*4))
        DataIn <= background;

//Row 5
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[895] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[894] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[893] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[892] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[891] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[890] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[889] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[888] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[887] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[886] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[885] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[884] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[883] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[882] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[881] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[880] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[879] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[878] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[877] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[876] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[875] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[874] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[873] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[872] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[871] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[870] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[869] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[868] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[867] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[866] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[865] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[864] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*4) && (cy <= START+SEGMENT*5-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*5-SKIP) && (cy <= START+SEGMENT*5))
        DataIn <= background;

//Row 6
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[863] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[862] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[861] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[860] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[859] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[858] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[857] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[856] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[855] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[854] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[853] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[852] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[851] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[850] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[849] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[848] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[847] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[846] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[845] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[844] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[843] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[842] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[841] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[840] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[839] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[838] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[837] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[836] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[835] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[834] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[833] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[832] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*5) && (cy <= START+SEGMENT*6-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*6-SKIP) && (cy <= START+SEGMENT*6))
        DataIn <= background;

//Row 7
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[831] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[830] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[829] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[828] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[827] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[826] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[825] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[824] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[823] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[822] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[821] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[820] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[819] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[818] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[817] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[816] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[815] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[814] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[813] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[812] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[811] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[810] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[809] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[808] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[807] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[806] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[805] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[804] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[803] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[802] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[801] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[800] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*6) && (cy <= START+SEGMENT*7-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*7-SKIP) && (cy <= START+SEGMENT*7))
        DataIn <= background;

//Row 8
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[799] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[798] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[797] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[796] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[795] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[794] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[793] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[792] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[791] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[790] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[789] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[788] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[787] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[786] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[785] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[784] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[783] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[782] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[781] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[780] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[779] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[778] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[777] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[776] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[775] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[774] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[773] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[772] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[771] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[770] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[769] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[768] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*7) && (cy <= START+SEGMENT*8-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*8-SKIP) && (cy <= START+SEGMENT*8))
        DataIn <= background;

//Row 9
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[767] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[766] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[765] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[764] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[763] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[762] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[761] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[760] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[759] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))
        if (n2[758] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP))

        if (n2[757] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP))

        if (n2[756] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP))

        if (n2[755] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP))

        if (n2[754] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP))

        if (n2[753] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP))

        if (n2[752] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP))

        if (n2[751] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP))

        if (n2[750] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP))

        if (n2[749] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP))

        if (n2[748] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP))

        if (n2[747] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP))

        if (n2[746] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP))

        if (n2[745] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP))

        if (n2[744] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP))

        if (n2[743] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP))

        if (n2[742] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP))

        if (n2[741] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP))

        if (n2[740] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP))

        if (n2[739] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP))

        if (n2[738] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP))

        if (n2[737] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP))

        if (n2[736] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31))

        DataIn <= background;
if((cy >= START+SEGMENT*8) && (cy <= START+SEGMENT*9-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32))

        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*9-SKIP) && (cy <= START+SEGMENT*9))
        DataIn <= background;

//Row 10
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))
        if (n2[735] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))
        if (n2[734] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))
        if (n2[733] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))
        if (n2[732] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))
        if (n2[731] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))
        if (n2[730] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))
        if (n2[729] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))
        if (n2[728] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))
        if (n2[727] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP))

        if (n2[726] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP)
)
        if (n2[725] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP)
)
        if (n2[724] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP)
)
        if (n2[723] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP)
)
        if (n2[722] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP)
)
        if (n2[721] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP)
)
        if (n2[720] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP)
)
        if (n2[719] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP)
)
        if (n2[718] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP)
)
        if (n2[717] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP)
)
        if (n2[716] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP)
)
        if (n2[715] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP)
)
        if (n2[714] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP)
)
        if (n2[713] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP)
)
        if (n2[712] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP)
)
        if (n2[711] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP)
)
        if (n2[710] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP)
)
        if (n2[709] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP)
)
        if (n2[708] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP)
)
        if (n2[707] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP)
)
        if (n2[706] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP)
)
        if (n2[705] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP)
)
        if (n2[704] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31)
)
        DataIn <= background;
if((cy >= START+SEGMENT*9) && (cy <= START+SEGMENT*10-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32)
)
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*10-SKIP) && (cy <= START+SEGMENT*10))
        DataIn <= background;

//Row 11
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[703] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[702] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[701] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[700] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[699] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[698] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[697] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[696] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[695] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[694] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[693] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[692] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[691] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[690] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[689] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[688] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[687] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[686] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[685] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[684] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[683] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[682] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[681] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[680] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[679] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[678] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[677] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[676] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[675] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[674] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[673] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[672] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*10) && (cy <= START+SEGMENT*11-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*11-SKIP) && (cy <= START+SEGMENT*11))
        DataIn <= background;

//Row 12
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[671] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[670] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[669] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[668] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[667] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[666] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[665] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[664] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[663] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[662] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[661] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[660] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[659] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[658] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[657] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[656] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[655] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[654] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[653] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[652] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[651] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[650] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[649] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[648] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[647] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[646] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[645] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[644] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[643] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[642] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[641] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[640] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*11) && (cy <= START+SEGMENT*12-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*12-SKIP) && (cy <= START+SEGMENT*12))
        DataIn <= background;

//Row 13
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[639] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[638] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[637] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[636] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[635] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[634] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[633] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[632] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[631] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[630] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[629] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[628] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[627] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[626] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[625] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[624] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[623] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[622] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[621] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[620] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[619] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[618] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[617] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[616] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[615] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[614] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[613] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[612] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[611] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[610] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[609] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[608] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*12) && (cy <= START+SEGMENT*13-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*13-SKIP) && (cy <= START+SEGMENT*13))
        DataIn <= background;

//Row 14
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[607] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[606] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[605] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[604] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[603] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[602] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[601] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[600] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[599] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[598] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[597] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[596] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[595] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[594] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[593] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[592] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[591] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[590] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[589] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[588] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[587] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[586] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[585] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[584] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[583] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[582] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[581] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[580] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[579] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[578] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[577] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[576] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*13) && (cy <= START+SEGMENT*14-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*14-SKIP) && (cy <= START+SEGMENT*14))
        DataIn <= background;

//Row 15
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[575] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[574] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[573] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[572] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[571] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[570] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[569] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[568] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[567] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[566] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[565] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[564] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[563] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[562] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[561] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[560] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[559] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[558] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[557] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[556] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[555] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[554] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[553] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[552] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[551] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[550] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[549] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[548] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[547] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[546] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[545] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[544] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*14) && (cy <= START+SEGMENT*15-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*15-SKIP) && (cy <= START+SEGMENT*15))
        DataIn <= background;

//Row 16
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[543] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[542] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[541] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[540] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[539] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[538] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[537] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[536] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[535] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[534] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[533] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[532] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[531] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[530] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[529] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[528] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[527] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[526] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[525] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[524] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[523] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[522] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[521] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[520] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[519] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[518] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[517] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[516] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[515] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[514] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[513] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[512] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*15) && (cy <= START+SEGMENT*16-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*16-SKIP) && (cy <= START+SEGMENT*16))
        DataIn <= background;

//Row 17
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[511] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[510] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[509] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[508] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[507] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[506] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[505] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[504] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[503] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[502] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[501] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[500] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[499] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[498] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[497] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[496] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[495] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[494] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[493] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[492] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[491] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[490] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[489] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[488] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[487] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[486] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[485] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[484] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[483] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[482] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[481] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[480] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*16) && (cy <= START+SEGMENT*17-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*17-SKIP) && (cy <= START+SEGMENT*17))
        DataIn <= background;

//Row 18
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[479] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[478] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[477] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[476] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[475] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[474] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[473] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[472] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[471] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[470] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[469] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[468] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[467] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[466] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[465] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[464] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[463] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[462] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[461] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[460] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[459] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[458] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[457] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[456] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[455] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[454] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[453] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[452] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[451] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[450] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[449] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[448] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*17) && (cy <= START+SEGMENT*18-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*18-SKIP) && (cy <= START+SEGMENT*18))
        DataIn <= background;

//Row 19
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[447] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[446] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[445] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[444] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[443] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[442] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[441] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[440] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[439] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[438] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[437] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[436] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[435] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[434] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[433] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[432] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[431] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[430] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[429] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[428] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[427] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[426] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[425] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[424] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[423] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[422] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[421] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[420] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[419] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[418] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[417] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[416] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*18) && (cy <= START+SEGMENT*19-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*19-SKIP) && (cy <= START+SEGMENT*19))
        DataIn <= background;

//Row 20
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[415] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[414] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[413] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[412] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[411] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[410] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[409] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[408] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[407] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[406] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[405] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[404] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[403] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[402] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[401] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[400] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[399] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[398] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[397] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[396] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[395] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[394] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[393] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[392] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[391] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[390] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[389] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[388] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[387] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[386] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[385] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[384] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*19) && (cy <= START+SEGMENT*20-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*20-SKIP) && (cy <= START+SEGMENT*20))
        DataIn <= background;

//Row 21
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[383] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[382] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[381] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[380] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[379] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[378] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[377] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[376] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[375] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[374] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[373] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[372] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[371] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[370] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[369] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[368] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[367] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[366] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[365] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[364] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[363] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[362] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[361] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[360] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[359] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[358] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[357] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[356] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[355] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[354] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[353] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[352] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*20) && (cy <= START+SEGMENT*21-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*21-SKIP) && (cy <= START+SEGMENT*21))
        DataIn <= background;

//Row 22
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[351] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[350] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[349] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[348] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[347] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[346] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[345] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[344] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[343] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[342] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[341] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[340] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[339] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[338] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[337] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[336] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[335] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[334] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[333] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[332] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[331] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[330] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[329] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[328] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[327] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[326] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[325] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[324] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[323] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[322] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[321] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[320] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*21) && (cy <= START+SEGMENT*22-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*22-SKIP) && (cy <= START+SEGMENT*22))
        DataIn <= background;

//Row 23
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[319] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[318] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[317] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[316] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[315] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[314] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[313] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[312] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[311] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[310] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[309] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[308] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[307] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[306] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[305] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[304] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[303] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[302] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[301] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[300] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[299] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[298] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[297] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[296] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[295] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[294] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[293] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[292] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[291] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[290] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[289] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[288] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*22) && (cy <= START+SEGMENT*23-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*23-SKIP) && (cy <= START+SEGMENT*23))
        DataIn <= background;

//Row 24
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[287] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[286] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[285] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[284] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[283] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[282] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[281] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[280] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[279] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[278] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[277] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[276] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[275] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[274] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[273] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[272] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[271] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[270] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[269] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[268] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[267] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[266] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[265] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[264] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[263] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[262] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[261] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[260] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[259] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[258] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[257] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[256] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*23) && (cy <= START+SEGMENT*24-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*24-SKIP) && (cy <= START+SEGMENT*24))
        DataIn <= background;

//Row 25
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[255] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[254] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[253] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[252] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[251] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[250] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[249] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[248] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[247] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[246] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[245] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[244] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[243] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[242] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[241] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[240] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[239] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[238] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[237] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[236] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[235] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[234] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[233] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[232] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[231] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[230] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[229] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[228] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[227] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[226] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[225] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[224] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*24) && (cy <= START+SEGMENT*25-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*25-SKIP) && (cy <= START+SEGMENT*25))
        DataIn <= background;

//Row 26
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[223] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[222] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[221] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[220] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[219] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[218] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[217] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[216] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[215] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[214] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[213] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[212] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[211] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[210] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[209] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[208] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[207] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[206] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[205] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[204] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[203] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[202] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[201] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[200] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[199] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[198] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[197] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[196] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[195] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[194] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[193] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[192] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*25) && (cy <= START+SEGMENT*26-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*26-SKIP) && (cy <= START+SEGMENT*26))
        DataIn <= background;

//Row 27
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[191] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[190] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[189] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[188] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[187] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[186] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[185] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[184] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[183] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[182] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[181] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[180] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[179] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[178] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[177] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[176] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[175] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[174] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[173] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[172] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[171] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[170] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[169] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[168] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[167] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[166] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[165] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[164] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[163] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[162] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[161] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[160] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*26) && (cy <= START+SEGMENT*27-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*27-SKIP) && (cy <= START+SEGMENT*27))
        DataIn <= background;

//Row 28
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[159] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[158] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[157] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[156] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[155] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[154] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[153] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[152] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[151] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[150] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[149] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[148] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[147] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[146] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[145] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[144] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[143] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[142] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[141] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[140] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[139] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[138] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[137] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[136] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[135] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[134] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[133] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[132] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[131] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[130] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[129] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[128] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*27) && (cy <= START+SEGMENT*28-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*28-SKIP) && (cy <= START+SEGMENT*28))
        DataIn <= background;

//Row 29
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[127] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[126] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[125] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[124] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[123] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[122] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[121] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[120] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[119] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[118] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[117] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[116] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[115] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[114] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[113] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[112] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[111] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[110] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[109] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[108] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[107] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[106] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[105] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[104] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[103] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[102] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[101] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[100] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[99] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[98] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[97] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[96] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*28) && (cy <= START+SEGMENT*29-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*29-SKIP) && (cy <= START+SEGMENT*29))
        DataIn <= background;

//Row 30
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[95] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[94] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[93] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[92] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[91] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[90] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[89] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[88] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[87] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[86] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[85] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[84] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[83] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[82] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[81] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[80] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[79] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[78] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[77] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[76] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[75] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[74] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[73] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[72] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[71] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[70] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[69] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[68] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[67] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[66] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[65] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[64] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*29) && (cy <= START+SEGMENT*30-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*30-SKIP) && (cy <= START+SEGMENT*30))
        DataIn <= background;

//Row 31
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[63] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[62] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[61] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[60] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[59] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[58] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[57] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[56] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[55] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[54] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[53] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[52] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[51] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[50] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[49] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[48] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[47] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[46] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[45] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[44] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[43] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[42] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[41] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[40] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[39] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[38] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[37] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[36] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[35] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[34] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[33] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[32] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*30) && (cy <= START+SEGMENT*31-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*31-SKIP) && (cy <= START+SEGMENT*31))
        DataIn <= background;

//Row 32
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*0) && (cx <= START+SEGMENT*1-SKIP))

        if (n2[31] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*1) && (cx <= START+SEGMENT*2-SKIP))

        if (n2[30] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*2) && (cx <= START+SEGMENT*3-SKIP))

        if (n2[29] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*3) && (cx <= START+SEGMENT*4-SKIP))

        if (n2[28] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*4) && (cx <= START+SEGMENT*5-SKIP))

        if (n2[27] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*5) && (cx <= START+SEGMENT*6-SKIP))

        if (n2[26] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*6) && (cx <= START+SEGMENT*7-SKIP))

        if (n2[25] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*7) && (cx <= START+SEGMENT*8-SKIP))

        if (n2[24] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*8) && (cx <= START+SEGMENT*9-SKIP))

        if (n2[23] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*9) && (cx <= START+SEGMENT*10-SKIP)
)
        if (n2[22] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*10) && (cx <= START+SEGMENT*11-SKIP
))
        if (n2[21] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*11) && (cx <= START+SEGMENT*12-SKIP
))
        if (n2[20] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*12) && (cx <= START+SEGMENT*13-SKIP
))
        if (n2[19] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*13) && (cx <= START+SEGMENT*14-SKIP
))
        if (n2[18] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*14) && (cx <= START+SEGMENT*15-SKIP
))
        if (n2[17] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*15) && (cx <= START+SEGMENT*16-SKIP
))
        if (n2[16] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*16) && (cx <= START+SEGMENT*17-SKIP
))
        if (n2[15] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*17) && (cx <= START+SEGMENT*18-SKIP
))
        if (n2[14] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*18) && (cx <= START+SEGMENT*19-SKIP
))
        if (n2[13] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*19) && (cx <= START+SEGMENT*20-SKIP
))
        if (n2[12] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*20) && (cx <= START+SEGMENT*21-SKIP
))
        if (n2[11] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*21) && (cx <= START+SEGMENT*22-SKIP
))
        if (n2[10] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*22) && (cx <= START+SEGMENT*23-SKIP
))
        if (n2[9] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*23) && (cx <= START+SEGMENT*24-SKIP
))
        if (n2[8] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*24) && (cx <= START+SEGMENT*25-SKIP
))
        if (n2[7] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*25) && (cx <= START+SEGMENT*26-SKIP
))
        if (n2[6] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*26) && (cx <= START+SEGMENT*27-SKIP
))
        if (n2[5] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*27) && (cx <= START+SEGMENT*28-SKIP
))
        if (n2[4] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*28) && (cx <= START+SEGMENT*29-SKIP
))
        if (n2[3] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*29) && (cx <= START+SEGMENT*30-SKIP
))
        if (n2[2] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*30) && (cx <= START+SEGMENT*31-SKIP
))
        if (n2[1] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;

if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*31) && (cx <= START+SEGMENT*32-SKIP
))
        if (n2[0] == 1'b0)
                DataIn <= dead;
        else
                DataIn <= alive;


// Begining/End of Row
if ((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx < START))
        DataIn <= background;
if ((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx > START+SEGMENT*32))
        DataIn <= background;

// Skip Row
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*1-SKIP) && (cx <= START+SEGMENT*1))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*2-SKIP) && (cx <= START+SEGMENT*2))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*3-SKIP) && (cx <= START+SEGMENT*3))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*4-SKIP) && (cx <= START+SEGMENT*4))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*5-SKIP) && (cx <= START+SEGMENT*5))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*6-SKIP) && (cx <= START+SEGMENT*6))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*7-SKIP) && (cx <= START+SEGMENT*7))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*8-SKIP) && (cx <= START+SEGMENT*8))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*9-SKIP) && (cx <= START+SEGMENT*9))

        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*10-SKIP) && (cx <= START+SEGMENT*10
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*11-SKIP) && (cx <= START+SEGMENT*11
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*12-SKIP) && (cx <= START+SEGMENT*12
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*13-SKIP) && (cx <= START+SEGMENT*13
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*14-SKIP) && (cx <= START+SEGMENT*14
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*15-SKIP) && (cx <= START+SEGMENT*15
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*16-SKIP) && (cx <= START+SEGMENT*16
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*17-SKIP) && (cx <= START+SEGMENT*17
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*18-SKIP) && (cx <= START+SEGMENT*18
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*19-SKIP) && (cx <= START+SEGMENT*19
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*20-SKIP) && (cx <= START+SEGMENT*20
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*21-SKIP) && (cx <= START+SEGMENT*21
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*22-SKIP) && (cx <= START+SEGMENT*22
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*23-SKIP) && (cx <= START+SEGMENT*23
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*24-SKIP) && (cx <= START+SEGMENT*24
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*25-SKIP) && (cx <= START+SEGMENT*25
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*26-SKIP) && (cx <= START+SEGMENT*26
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*27-SKIP) && (cx <= START+SEGMENT*27
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*28-SKIP) && (cx <= START+SEGMENT*28
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*29-SKIP) && (cx <= START+SEGMENT*29
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*30-SKIP) && (cx <= START+SEGMENT*30
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*31-SKIP) && (cx <= START+SEGMENT*31
))
        DataIn <= background;
if((cy >= START+SEGMENT*31) && (cy <= START+SEGMENT*32-SKIP) && (cx >= START+SEGMENT*32-SKIP) && (cx <= START+SEGMENT*32
))
        DataIn <= background;

//Skip Column
if ((cy >= START+SEGMENT*32-SKIP) && (cy <= START+SEGMENT*32))
        DataIn <= background;

//Skip
if (cy >= START+SEGMENT*32-SKIP)
        DataIn <= background;

     end
     
endmodule // hdmi_top



