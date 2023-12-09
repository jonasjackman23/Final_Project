module DFlipFlop (D, reset, clk, Q);
    input logic [1023:0]D;
    input logic reset;
    input logic clk;

    output logic [1023:0]Q;

    always @(posedge clk) 
    begin
        Q <= D; 
    end 
endmodule


module GameOfLife(seed, clk, reset, pause, start, out_grid);
    logic run;
    logic [1023:0]grid;
    logic [1023:0]grid_evolve;
    logic [1023:0] mux1; 
    logic [1023:0] r2m;
    output logic [1023:0]out_grid;
    input logic [1023:0] seed;
    input logic clk;
   
    input logic reset;
    input logic start;
    input logic pause;
    
    
    assign out_grid = mux1;
    

    datapath GameOfLifeDatapath (grid, grid_evolve);
    mux2 FirstMultiplexor (seed, mux1, run, grid);
    DFlipFlop FirstRegister (grid_evolve, reset, clk, r2m);
    mux2 SecondMultiplexor (seed, r2m, run, mux1);
    fsm StateMachine(clk, reset, pause, start, run);
    

endmodule

module fsm(clk, reset, pause, start, run);
    input logic clk;
    //input logic select;
    input logic reset;
    input logic pause;
    input logic start;
    output logic run;

 typedef enum logic [2:0] {S0, S1, S2} statetype;
    statetype state, nextstate;

always_ff @(posedge clk, posedge reset)
    if (~start) state <= S0;
    else if (reset) state <= S0;
    else if (start) state <= S1;
    else if (pause) state <= S0;
    else    state <= nextstate;

always_comb
    case(state)
        S0: begin
            run = 1'b0;
            if (reset) nextstate <= S0;
            else if (start) nextstate <= S1;
        end

        S1: begin
            run = 1'b1;
            if (reset) nextstate <= S0;
            else if (pause) nextstate <= S0;
            else if (~start) nextstate <= S0;
            else nextstate <= S1;
        end
    endcase
endmodule