/*

Template interface of the ultrasonic wind sensor main signal processing path.
 
jca@fe.up.pt, Dec 2019

    This simulation model simulates the data flow through the signmal procssing path
	using the data files generated by the Matlab simulation model

	This Verilog code is property of University of Porto
	Its utilization beyond the scope of the course Digital Systems Design
	(Projeto de Sistemas Digitais) of the Integrated Master in Electrical 
	and Computer Engineering requires explicit authorization from the author.
 
*/

`timescale 1ns/1ps

module winddirection
               (
                  input clock,
				  input reset,
				  input endata,
				  input signed [11:0] rx1,          // Input channels
				  input signed [11:0] rx2,
				  input signed [11:0] rx3,
				  input signed [11:0] rx4,

				  input [3:0]          spdmeanlen,  // The log2(length) of the speed averaging
				  output signed [15:0] speedX,      // wind speed along X, 16 bits, 10 fractional
				  output signed [15:0] speedY,      // wind speed along X, 16 bits, 10 fractional
				  output               speeden      // 1-clock pulse to sync with speedX/Y updates
			   );


wire wind_1_ready;
wire wind_2_ready;

assign speeden = wind_1_ready && wind_2_ready;

wind wind_1 (
	 .clock(clock),
    .reset(reset),
	 .enable(1'b1),
	 .sample(endata),
    .rxA(rx1),
    .rxB(rx3),
	 .meanlen(spdmeanlen),
    .speed(speedY),
	 .ready(wind_1_ready)
);

wind wind_2 (
	 .clock(clock),
    .reset(reset),
	 .enable(1'b1),
	 .sample(endata),
    .rxA(rx2),
    .rxB(rx4),
	 .meanlen(spdmeanlen),
    .speed(speedX),
	 .ready(wind_2_ready)
);

endmodule

				  