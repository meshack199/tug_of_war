//Shawnna Cabanday
//February 24, 2018 Last update: 7:57PM

//computer is the "left player"
//humanPlayer is the right player: Press KEY[0]

//** Primary instantiating module **
module tugofwarlab6(CLOCK_50, SW, LEDR, KEY, HEX0, HEX5); 
	input CLOCK_50; 
	input [9:0] SW;
	input [3:0] KEY;
	output logic [9:0] LEDR;
	output logic [6:0] HEX0, HEX5;
	
	
	assign LEDR[0] = 1'b0;	//skip LEDR[0]
	
	//connecting wires
	wire right,left;		//used to connect FSMs on left to right
	wire winR, winL;		//pings win signal to point system
	wire [2:0] counterL, counterR;	//used to communicate point system
	wire [9:0] randomConnector;    //connects created randomNum to compare mod
	wire computerSignal; 			//connects output of compare mod to computer input
	
	//clock divider
//	wire[31:0] clk;
//	parameter whichClock = 0;				//testbenches = 0
//	clock_divider cdiv (CLOCK_50, clk);
	
	//generate random number
	LFSR genRandomNum (.Clock(CLOCK_50), .Reset(SW[9]), .LFSROut(randomConnector)); 
	
	//boolean comparison
	compare10 compare (.A10(SW[8:0]), .B10(randomConnector[9:0]), .Alarger(computerSignal)); 
	
	// buttons for the two different players 
	userInput humanPlayer (.Clock(CLOCK_50) , .Reset(SW[9]), .pressed(~KEY[0]), .set(right));	//player 1 presses KEY[0]
	userInput computer (.Clock(CLOCK_50) , .Reset(SW[9]), .pressed(computerSignal), .set(left));	//computerSignal triggers press
	
	//player1 set value is true when rightmost input is true (player 1 = right)
	//player2 set value is true when leftmost input is true (player 2 = left)
	
	
	// instantiations of normal lights and center lights (skips LEDR[0])
	normalLight n1(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[2]), .NR(1'b0), .lightOn(LEDR[1]));
	normalLight n2(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[3]), .NR(LEDR[1]), .lightOn(LEDR[2]));
	normalLight n3(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[4]), .NR(LEDR[2]), .lightOn(LEDR[3]));
	normalLight n4(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[5]), .NR(LEDR[3]), .lightOn(LEDR[4]));
	
	//centerLight resets if wire is triggered to be true for left or right player
	centerLight c1(.Clock(CLOCK_50), .Reset(SW[9] | winR | winL), .L(left), .R(right), .NL(LEDR[6]), .NR(LEDR[4]), .lightOn(LEDR[5]));
	
	normalLight n6(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[7]), .NR(LEDR[5]), .lightOn(LEDR[6]));
	normalLight n7(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[8]), .NR(LEDR[6]), .lightOn(LEDR[7]));
	normalLight n8(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(LEDR[9]), .NR(LEDR[7]), .lightOn(LEDR[8]));
	normalLight n9(.Clock(CLOCK_50), .Reset(SW[9]), .L(left), .R(right), .NL(1'b0),    .NR(LEDR[8]), .lightOn(LEDR[9]));
	
	//checksWinner to reset 
	checkWinner whoWon(LEDR[9], LEDR[1], left, right, winL, winR); //leftMostLight: LEDR[9], rightMostLight: LEDR[1]
	
	//FSMs for communicating to hexdisplay
	counter leftCount(.Clock(CLOCK_50), .Reset(SW[9] | (counterL == 3'b111) | (counterR == 3'b111)), .Signal(winL), .out(counterL));
	counter rightCount(.Clock(CLOCK_50), .Reset(SW[9]| (counterL == 3'b111) | (counterR == 3'b111)), .Signal(winR), .out(counterR));
		
	// displays score count 
	hexdisplay display (.Clock(CLOCK_50), .Reset(SW[9]), .player1Counter(counterL), .player2Counter(counterR), .player1Light(HEX5), .player2Light(HEX0));
	   
endmodule //tugOfWarDriver


// divided_clocks[0] = 25MHz, [1] = 12.5MHz, [23] = 3Hz, [24] 1.5Hz,
// [25] = 0.75 Hz
module clock_divider (clock, divided_clocks);
	input clock;
	output [31:0] divided_clocks;
	reg [31:0] divided_clocks;
	
	
	initial
		divided_clocks <= 0;
		
	always @(posedge clock)
		divided_clocks <= divided_clocks + 1;
		
endmodule 

module counter(Clock, Reset, Signal, out);
	input Clock, Reset;
	input Signal;
	logic [2:0] PS, NS;
	output logic [2:0] out;
	
	parameter [2:0] 	zero = 	3'b000, 
							one = 	3'b001, 
							two = 	3'b010,
							three = 	3'b011, 
							four = 	3'b100, 
							five = 	3'b101,
							six =	 	3'b110, 
							seven = 	3'b111; 
	
	always_comb begin
		case(PS)
		zero: if(Signal) 	NS = one;
				else 			NS = zero;
		one: if(Signal) 	NS = two;
				else 			NS = one;
		two: if(Signal) 	NS = three;
				else 			NS = two;
		three: if(Signal) NS = four;
				else 			NS = three;
		four: if(Signal) 	NS = five;
				else 			NS = four;
		five: if(Signal) 	NS = six;
				else			NS = five;
		six: if(Signal)	NS = seven;
				else			NS = six;
		seven: if(Signal)	NS = zero;
				else			NS = seven;
		endcase
	end

	always @(posedge Clock) begin
		if (Reset) begin
				PS <= zero; 
		end
		else
				PS <= NS;
				out <= NS;
	end

endmodule

module counter_testbench();
	logic clk, rst, test;
	wire[2:0] Out;
	
	counter dut (.Clock(clk), .Reset(rst), .Signal(test), .out(Out));
	
	parameter CLOCK_PERIOD = 100;
	
	initial clk = 1;
	always begin
			#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin

		rst <= 1; 	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						
		rst <= 0;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						
		test <= 1;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk); 
						@(posedge clk);
						@(posedge clk);
						
		rst <= 1;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);	
		rst <= 0;	@(posedge clk);
						@(posedge clk);
						
						
		test <= 0;	@(posedge clk); 
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);				
						
		rst <= 1; 	@(posedge clk); 
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						
		rst <= 0;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
		$stop;
	end
endmodule	

module LFSR (Clock, Reset, LFSROut);
	input Clock, Reset;
	output [9:0] LFSROut;
	logic [9:0] PS, NS;
	reg temp;
	
	always @(*) begin 
		temp = ~(PS[6] ^ PS[8]);
		NS = {PS[8:0], temp};
	end
	
	assign LFSROut = PS;
	
	always @(posedge Clock)
		if(Reset)
			PS <= 10'b0000000000;
		else
			PS <= NS;
endmodule

module LFSR_testbench();
	logic clk, rst;
	wire [8:0] Out;
	
	LFSR dut (.Clock(clk), .Reset(rst), .LFSROut(Out));
	
	
	parameter CLOCK_PERIOD = 100;
	
	initial clk = 1;
	always begin
			#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin

		rst <= 1; 	@(posedge clk);
		rst <= 0;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						
		rst <= 1; 	@(posedge clk);	//reset check			
		rst <= 0;	@(posedge clk);
						@(posedge clk);
						@(posedge clk);
						@(posedge clk);
	
		$stop;
	end
endmodule	

module compare1(A,B, Equal, Alarger);
	input logic A, B;
	output logic Equal, Alarger;
	
	assign Equal = (A&B) | (~A&~B);
	assign Alarger = (A&~B); 
//	assign Blarger = (~A&B); 
endmodule

module compare10(A10, B10, Alarger);
	input logic [9:0] A10, B10; 
	output logic Alarger;
	
	wire e0, e1, e2, e3, e4, e5, e6, e7, e8, e9;
	wire AC0, AC1, AC2, AC3, AC4, AC5, AC6, AC7, AC8, AC9;
//	wire BC0, BC1, BC2, BC3, BC4, BC5, BC6, BC7, BC8, BC9;
	
	compare1 digit0 (A10[0], B10[0], e0, AC0);
	compare1 digit1 (A10[1], B10[1], e1, AC1);
	compare1 digit2 (A10[2], B10[2], e2, AC2);
	compare1 digit3 (A10[3], B10[3], e3, AC3);
	compare1 digit4 (A10[4], B10[4], e4, AC4);
	compare1 digit5 (A10[5], B10[5], e5, AC5);
	compare1 digit6 (A10[6], B10[6], e6, AC6);
	compare1 digit7 (A10[7], B10[7], e7, AC7);
	compare1 digit8 (A10[8], B10[8], e8, AC8);
	compare1 digit9 (A10[9], B10[9], e9, AC9);
	
//	assign Equal = (e0 & e1 & e2 & e3 & e4 & e5 & e6 & e7 & e8 & e9);
	assign Alarger = (	AC9 
							| (AC8 & e9) 
							| (AC7 & e9 & e8)
							| (AC6 & e9 & e8 & e7) 
							| (AC5 & e9 & e8 & e7 & e6)
							| (AC4 & e9 & e8 & e7 & e6 & e5)
							| (AC3 & e9 & e8 & e7 & e6 & e5 & e4)
							| (AC2 & e9 & e8 & e7 & e6 & e5 & e4 & e3)
							| (AC1 & e9 & e8 & e7 & e6 & e5 & e4 & e3 & e2)
							| (AC1 & e9 & e8 & e7 & e6 & e5 & e4 & e3 & e2 & e1) 	
							);
//	assign Blarger = (~Alarger & ~Equal);
endmodule

module compare10_testbench();
	logic clk;
	logic [9:0] testA10, testB10;
	logic Alarger, Blarger;
	logic Equal;
	
	compare10 dut (.A10(testA10), .B10(testB10), .Equal(Equal), .Alarger(Alarger), .Blarger(Blarger));
	
	
	parameter CLOCK_PERIOD = 100;
	
	initial clk = 1;
	always begin
			#(CLOCK_PERIOD/2);
		clk = ~clk;
	end
	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin

		testA10 <= 10'b0000000000; testB10 <= 10'b0000000001; 	@(posedge clk);	//B bigger than A
																					@(posedge clk);
		testA10 <= 10'b0000000010; testB10 <= 10'b0000000000; 	@(posedge clk); //A bigger than B
																					@(posedge clk);
		testA10 <= 10'b0000000000; testB10 <= 10'b0000000000; 	@(posedge clk); //equal
																					@(posedge clk);
		testA10 <= 10'b0001000000; testB10 <= 10'b0000000001; 	@(posedge clk); //A bigger than B
																					@(posedge clk);																				
		testA10 <= 10'b1100000000; testB10 <= 10'b000011000; 		@(posedge clk); // A bigger than B
																					@(posedge clk);	
		testA10 <= 10'b0000000000; testB10 <= 10'b0000100101; 	@(posedge clk); //B bigger than A
																					@(posedge clk);	
																					
		testA10 <= 10'b0000100000; testB10 <= 10'b1101100001; 	@(posedge clk);	//B bigger than A
																					@(posedge clk);
		testA10 <= 10'b1000000010; testB10 <= 10'b0110000000; 	@(posedge clk); //A bigger than B
																					@(posedge clk);
		testA10 <= 10'b0000011000; testB10 <= 10'b0000011000; 	@(posedge clk); //equal
																					@(posedge clk);
		testA10 <= 10'b1111000000; testB10 <= 10'b0001100001; 	@(posedge clk); //A bigger than B
																					@(posedge clk);																				
		testA10 <= 10'b1111111000; testB10 <= 10'b0000111111; 	@(posedge clk); // A bigger than B
																					@(posedge clk);	
		testA10 <= 10'b000100; testB10 <= 10'b1111111111; 			@(posedge clk); //B bigger than A
																					@(posedge clk);						
		$stop;
	end
endmodule	


module hexdisplay(Clock, Reset, player1Counter, player2Counter, player1Light, player2Light);
	input Clock, Reset;
	input [2:0] player1Counter, player2Counter;
	logic [6:0] PS, NS;
	output logic [6:0] player1Light, player2Light;
	
	//								    	6543210
	parameter [6:0]	zero = 	7'b1000000,	//hex displays for counting (active low)
							one =  	7'b1111001,
							two =  	7'b0100100,
							three = 	7'b0110000,
							four =	7'b0011001,
							five =	7'b0010010,
							six = 	7'b0000010,
							seven =	7'b1111000;
							
	always @(*) begin
		case(player1Counter)
			3'b000: 	player1Light = zero;
			3'b001:	player1Light = one; 
			3'b010:	player1Light = two;
			3'b011:	player1Light = three;
			3'b100:	player1Light = four;
			3'b101:	player1Light = five;
			3'b110:	player1Light = six; 
			3'b111:	player1Light = seven;
		endcase
		
		case(player2Counter)
			3'b000: player2Light = zero;
			3'b001: player2Light = one;
			3'b010: player2Light = two;
			3'b011: player2Light = three;
			3'b100: player2Light = four;
			3'b101: player2Light = five;
			3'b110: player2Light = six; 
			3'b111: player2Light = seven;
		endcase			
	end
	
//	always @(posedge Clock) begin
//		if(Reset) begin
//			player1Light <= zero;
//			player2Light <= zero;
//			end
//		else if(player1Light == zero) begin
//			player2Light <= zero; 
//			end
//		else if(player2Light == zero) begin
//			player1Light <= zero;
//			end
//	end
endmodule	//hexdisplay
 
module centerLight (Clock, Reset, L, R, NL, NR, lightOn);
	input Clock, Reset;
	input	L, R, NL, NR;
	output logic lightOn;
	
		
	// L is true when left key is pressed
	// R is true when the right key is pressed
	// NL is true when the light on the left is on
	// NR is true when the light on the right is on
	//	lightOn is true -- centerLight is on
	
	//**FSM Logic Block for centerLight**
	//Cases for off to on: 
	//left light on, press right, lightOn
	//right light on, press left, lightOn
		
	//Cases for on to off: 
	//lightOn, press left, light turns off
	//lightOn, press right, light turns off
	
	logic PS, NS;
	parameter off = 1'b0, on = 1'b1;

	always @(*)
		case(PS)
			off:	if (NL & R) 		NS = on;           
					else if (NR & L)	NS = on;
					else 					NS = off;
			on:	if (R ^ L) NS = off;
					else 					NS = on;
		default: NS = 1'bx;	
	endcase

	always @(*)
		case(PS)
			off: lightOn = off;
			on: lightOn = on;
			default: lightOn = 1'bx;	
	endcase

	always @(posedge Clock)
		if (Reset)
			PS <= on; // reset should turn the center light on
		else
			PS <= NS;

endmodule		//centerLight

//testing values of centerLight module
module centerLight_testbench();

	logic Clk, Reset;
	logic [9:0] LEDR;
	logic [9:0] SW;	
	logic NL, NR, L, R;
	
	//instantiating centerLight module for test 
	centerLight dut(.Clock(Clk), .Reset(Reset), .L(L), .R(R), .NL(NL), .NR(NR), .lightOn(LEDR[5]));


	parameter CLOCK_PERIOD = 100;

	initial Clk = 1;
	always begin
			#(CLOCK_PERIOD/2);
		Clk = ~Clk;
	end
	// Set up the inputs to the design. Each line is a clock cycle.
	initial begin

		Reset <= 1; @(posedge Clk);
						@(posedge Clk);
						
		Reset <= 0;	@(posedge Clk);
						@(posedge Clk);
						
		L <= 1;		@(posedge Clk);
						@(posedge Clk);
						
		NR <= 1;		@(posedge Clk); 
						@(posedge Clk);
						
		NR <= 0;		@(posedge Clk);
						@(posedge Clk);
						
		L <= 0;		@(posedge Clk); 
						@(posedge Clk);

		R <= 1;		@(posedge Clk);
						@(posedge Clk);					
						
		NL <= 1; 	@(posedge Clk); 
						@(posedge Clk);
						
		NL <= 0;		@(posedge Clk);
						@(posedge Clk);
												
		R <= 0;		@(posedge Clk);
						@(posedge Clk);
										
		$stop;
	end
endmodule		//centerLight_testbench

module normalLight (Clock, Reset, L, R, NL, NR, lightOn);
	input Clock, Reset;
	// L is true when left key is pressed
	// R is true when the right key is pressed
	// NL is true when the light on the left is on
	// NR is true when the light on the right is on
	//	lightOn is true -- normalLight is on
	
	//**FSM Logic Block for normalLight**
	//see notes for centerLight, they are mostly the same
	
	input L, R, NL, NR;
	logic PS, NS; 
	parameter off = 1'b0, on = 1'b1;
	// when lightOn is true, the normal light should be on.
	output reg lightOn;

	// while
	always @(*)
	case(PS)
		off:	if (NL & R) NS = on;           
				else if (NR & L) NS = on;
				else NS = off;
		on:	if (R ^ L) NS = off;
				else NS = on;
		default: NS = 1'bx;	
	endcase


	always @(*)
		case(PS)
			off: lightOn = 0;
			on: lightOn = 1;
			default: NS = 1'bx;	
	endcase


	always @(posedge Clock)
		if (Reset)
			PS <= off; // normal light should be turned off when reset
		else
			PS <= NS;

	endmodule //normalLight

module normalLight_testbench();
	logic clk, Reset; 
	logic LEDR[3];
	logic L, R, NL, NR;
	
	normalLight dut (.Clock(clk), .Reset(Reset), .L(L), .R(R), .NL(NL), .NR(NR), .lightOn(LEDR[3]));
	
	//Set up the clock.
	parameter CLOCK_PERIOD = 100; 
		initial begin 
			clk <= 0;
			forever #(CLOCK_PERIOD/2) clk <= ~clk;
		end
	
	//Set up the inputs to the design. Each line is a clock cycle.
	initial begin
		Reset <= 1;
															@(posedge clk);
															@(posedge clk);
															
		Reset <= 0;  									@(posedge clk);
															@(posedge clk);
															
										L<=1;				@(posedge clk);
															@(posedge clk);
															
											NR <= 1;		@(posedge clk);
															@(posedge clk);
															
										 NR <= 0;		@(posedge clk);
															@(posedge clk);
															
		L <= 0;											@(posedge clk);
															@(posedge clk);
															
				  R <= 1;								@(posedge clk);
															@(posedge clk);
															
							  NL <= 1;       			@(posedge clk);
															@(posedge clk);
														
			NL <= 0;										@(posedge clk);
															@(posedge clk);
															
			R <= 0;										@(posedge clk);												
															@(posedge clk);
		$stop; //End the simulation.
	end
endmodule //normalLight_testbench
	

//utilizing metastability with truth tables (user input)
module userInput(Clock, Reset, pressed, set);
	input Clock, Reset;
	input pressed;
	output reg set;
	logic [1:0] PS, NS;
	parameter [1:0] on = 2'b00, hold = 2'b01, off = 2'b10;
	
	always @(*)
	case(PS)
		on:	if (pressed) NS = hold;
				else NS = off;
		hold:	if (pressed) NS = hold;
				else NS = off;
		off: 	if (pressed) NS = on;
				else NS = off;
		default: NS = 2'bxx;
	endcase
	
	always @(*)
	case(PS)
		on: set = 1;
		hold: set = 0;
		off: set = 0;
		default: set = 1'bx;
	endcase
		
	always_ff @(posedge Clock)
		if (Reset) 
			PS <= off;
		else
			PS <= NS;
	
endmodule

module checkWinner(leftMostLight, rightMostLight, left, right, winL, winR);
	input leftMostLight, rightMostLight, left, right; 
	output winL, winR;
	
	assign winL = leftMostLight & left & ~right;
	assign winR = rightMostLight & right & ~left;
endmodule

module tugOfWarLab6_testbench(); //CLOCK_50, KEY, SW, LEDR, HEX0
	logic CLOCK_50;
	logic [9:0] SW;
	logic [3:0] KEY;
	logic [9:0] LEDR;
	logic [6:0] HEX0, HEX5;
	

	//instantiating tugOfWarDriver
	tugofwarlab6 dut (CLOCK_50, SW, LEDR, KEY, HEX0, HEX5);
	
	initial CLOCK_50 = 1;
	parameter CLOCK_PERIOD = 100;
	
	always begin
			#(CLOCK_PERIOD/2);
		CLOCK_50 = ~CLOCK_50;
	end

	
	
	initial begin			//only toggles with the player 1&2 keys 
				SW[9] <= 1; @(posedge CLOCK_50);
								@(posedge CLOCK_50);
				SW[9] <= 0;	@(posedge CLOCK_50);
								@(posedge CLOCK_50);
								
		SW[8:0] <= 9'b111000000; @(posedge CLOCK_50); 
														
		KEY[0] <= 1; 		@(posedge CLOCK_50); //checking scoreBoard for counter1
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);	
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);	//1
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);	
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);	//2
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50); //3
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50); //4
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50); //5
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50); //6
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);	// should restart game here!
		KEY[0] <= 1;		@(posedge CLOCK_50); //7
		
		KEY[0] <= 1; 		@(posedge CLOCK_50); //another evaluation round...
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50); 
		
		KEY[0] <= 1; 		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
		KEY[0] <= 0;		@(posedge CLOCK_50);
		KEY[0] <= 1;		@(posedge CLOCK_50);
								
		SW[9] <= 1;			@(posedge CLOCK_50); //reset
								@(posedge CLOCK_50);
		SW[9] <= 0;			@(posedge CLOCK_50);
								@(posedge CLOCK_50);
								
		KEY[3] <= 1; 		@(posedge CLOCK_50); //checking scoreBoard for counter2
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		
		KEY[3] <= 1; 		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
		KEY[3] <= 0;		@(posedge CLOCK_50);
		KEY[3] <= 1;		@(posedge CLOCK_50);
								
		SW[9] <= 1;			@(posedge CLOCK_50); //reset
								@(posedge CLOCK_50);
		SW[9] <= 0;			@(posedge CLOCK_50);
								@(posedge CLOCK_50);
	
		$stop;
	end
endmodule
