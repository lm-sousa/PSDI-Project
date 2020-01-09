/*

Simulation model of the ultrasonic wind sensor main signal processing path.
 
jca@fe.up.pt, Dec 2019

    This simulation model simulates the data flow through the signmal procssing path
	using the data files generated by the Matlab simulation model

	This Verilog code is property of University of Porto
	Its utilization beyond the scope of the course Digital Systems Design
	(Projeto de Sistemas Digitais) of the Integrated Master in Electrical 
	and Computer Engineering requires explicit authorization from the author.
 
*/

`timescale 1ns/1ps

module winddirectionXY
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
				  output reg           speeden      // 1-clock pulse to sync with speedX/Y updates
			   );
parameter MAXSIMDATA = 2000;

// The filenames with data created by the simulation of the Matlab scripts:			   
/*parameter
  // Imaginary components of the input signals, 13 bits signed:
  imaguwX_filename = "../simdata/imag_rx2.hex", // upwind along X (left receiver)
  imagdwX_filename = "../simdata/imag_rx4.hex", // downwind along X (right receiver)
  imaguwY_filename = "../simdata/imag_rx3.hex", // upwind along Y (bottom receiver)
  imagdwY_filename = "../simdata/imag_rx1.hex", // downwind along Y (top receiver)

  // Real components of the input signals, 13 bits signed:
  realuwX_filename = "../simdata/real_rx2.hex", // upwind along X (left receiver)
  realdwX_filename = "../simdata/real_rx4.hex", // downwind along X (right receiver)
  realuwY_filename = "../simdata/real_rx3.hex", // upwind along Y (bottom receiver)
  realdwY_filename = "../simdata/real_rx1.hex", // downwind along Y (top receiver)

  // real-time phase, 19 bits signed
  phaseuwX_filename= "../simdata/phase_rx2.hex", // upwind along X (left receiver)
  phasedwX_filename= "../simdata/phase_rx4.hex", // downwind along X (right receiver)
  phaseuwY_filename= "../simdata/phase_rx3.hex", // upwind along Y (bottom receiver)
  phasedwY_filename= "../simdata/phase_rx1.hex", // downwind along Y (top receiver)

  // real-time phase difference, 19 bits signed:
  phasediffX_filename = "../simdata/phasediff_X.hex", // phase difference along X: rx4 - rx2
  phasediffY_filename = "../simdata/phasediff_Y.hex", // phase difference along X: rx1 - rx3
  
  // wind speed X and Y components, 16 bits signed:
  speedX_filename = "../simdata/speed_X.hex",  // wind speed along X (positive from left to right)
  speedY_filename = "../simdata/speed_Y.hex";  // wind speed along Y (positive from bottom to top)
	


// arrays for simulation data:		
// Imaginary components of the input signals, 13 bits signed:
reg signed [12:0]  vimaguwX[0:MAXSIMDATA-1]; 
reg signed [12:0]  vimagdwX[0:MAXSIMDATA-1]; 
reg signed [12:0]  vimaguwY[0:MAXSIMDATA-1]; 
reg signed [12:0]  vimagdwY[0:MAXSIMDATA-1]; 

// Real components of the input signals, 13 bits signed:
reg signed [12:0]  vrealuwX[0:MAXSIMDATA-1];  // upwind along X (left receiver)
reg signed [12:0]  vrealdwX[0:MAXSIMDATA-1];  // downwind along X (right receiver)
reg signed [12:0]  vrealuwY[0:MAXSIMDATA-1];  // upwind along Y (bottom receiver)
reg signed [12:0]  vrealdwY[0:MAXSIMDATA-1];  // downwind along Y (top receiver)

// real-time phase, 19 bits signed
reg signed [18:0]  vphaseuwX[0:MAXSIMDATA-1];  // upwind along X (left receiver)
reg signed [18:0]  vphasedwX[0:MAXSIMDATA-1];  // downwind along X (right receiver)
reg signed [18:0]  vphaseuwY[0:MAXSIMDATA-1];  // upwind along Y (bottom receiver)
reg signed [18:0]  vphasedwY[0:MAXSIMDATA-1];  // downwind along Y (top receiver)

// real-time phase difference, 19 bits signed:
reg signed [18:0]  vphasediffX[0:MAXSIMDATA-1];  // phase difference along X: rx4 - rx2
reg signed [18:0]  vphasediffY[0:MAXSIMDATA-1];  // phase difference along X: rx1 - rx3

// wind speed X and Y components, 16 bits signed:
reg signed [15:0]  vspeedX[0:MAXSIMDATA-1]; // wind speed along X (positive from left to right)
reg signed [15:0]  vspeedY[0:MAXSIMDATA-1]; // wind speed along Y (positive from bottom to top)
											
 // Load simulation data files:
initial
begin
  $readmemh( imaguwX_filename, vimaguwX );
  $readmemh( imagdwX_filename, vimagdwX );
  $readmemh( imaguwY_filename, vimaguwY );
  $readmemh( imagdwY_filename, vimagdwY );

  $readmemh( realuwX_filename, vrealuwX );
  $readmemh( realdwX_filename, vrealdwX );
  $readmemh( realuwY_filename, vrealuwY );
  $readmemh( realdwY_filename, vrealdwY );

  $readmemh( phaseuwX_filename, vphaseuwX );
  $readmemh( phasedwX_filename, vphasedwX );
  $readmemh( phaseuwY_filename, vphaseuwY );
  $readmemh( phasedwY_filename, vphasedwY );

  $readmemh( phasediffX_filename, vphasediffX );
  $readmemh( phasediffY_filename, vphasediffY );

  $readmemh( speedX_filename, vspeedX );
  $readmemh( speedY_filename, vspeedY );
  
end*/

// The functional model:
// index variables to access the data vectors:
integer i1=0;//, i2=0, i3=0, i4=0;

wire signed [12:0]  rXimaguw; 
wire signed [12:0]  rXimagdw; 
wire signed [12:0]  rYimaguw; 
wire signed [12:0]  rYimagdw; 

// Real components of the input signals, 13 bits signed:
wire signed [12:0]  rXrealuw;  // upwind along X (left receiver)
wire signed [12:0]  rXrealdw;  // downwind along X (right receiver)
wire signed [12:0]  rYrealuw;  // upwind along Y (bottom receiver)
wire signed [12:0]  rYrealdw;  // downwind along Y (top receiver)

// real-time phase, 19 bits signed
wire signed [18:0]  rXphaseuw;  // upwind along X (left receiver)
wire signed [18:0]  rXphasedw;  // downwind along X (right receiver)
wire signed [18:0]  rYphaseuw;  // upwind along Y (bottom receiver)
wire signed [18:0]  rYphasedw;  // downwind along Y (top receiver)

// real-time phase difference, 19 bits signed:
wire signed [18:0]  rXphasediff;  // phase difference along X: rx4 - rx2
wire signed [18:0]  rYphasediff;  // phase difference along X: rx1 - rx3

// wind speed X and Y components, 16 bits signed:
wire signed [15:0]  rXspeed; // wind speed along X (positive from left to right)
wire signed [15:0]  rYspeed; // wind speed along Y (positive from bottom to top)

/*reg signed [12:0]  dummy_rXimaguw; 
reg signed [12:0]  dummy_rXimagdw; 
reg signed [12:0]  dummy_rYimaguw; 
reg signed [12:0]  dummy_rYimagdw; 

// Real components of the input signals, 13 bits signed:
reg signed [12:0]  dummy_rXrealuw;  // upwind along X (left receiver)
reg signed [12:0]  dummy_rXrealdw;  // downwind along X (right receiver)
reg signed [12:0]  dummy_rYrealuw;  // upwind along Y (bottom receiver)
reg signed [12:0]  dummy_rYrealdw;  // downwind along Y (top receiver)

// real-time phase, 19 bits signed
reg signed [18:0]  dummy_rXphaseuw;  // upwind along X (left receiver)
reg signed [18:0]  dummy_rXphasedw;  // downwind along X (right receiver)
reg signed [18:0]  dummy_rYphaseuw;  // upwind along Y (bottom receiver)
reg signed [18:0]  dummy_rYphasedw;  // downwind along Y (top receiver)

// real-time phase difference, 19 bits signed:
reg signed [18:0]  dummy_rXphasediff;  // phase difference along X: rx4 - rx2
reg signed [18:0]  dummy_rYphasediff;  // phase difference along X: rx1 - rx3

// wind speed X and Y components, 16 bits signed:
reg signed [15:0]  dummy_rXspeed; // wind speed along X (positive from left to right)
reg signed [15:0]  dummy_rYspeed; // wind speed along Y (positive from bottom to top)*/


// when reset is released force all index variables to zero:
/*always @(negedge reset)
begin
  i1 <= 0;
  i2 <= 0;
  i3 <= 0;
  i4 <= 0;
end*/

//----------------------------------------------------------------
// Simulate module real2cpx:
// whenever a new sample arrives, wait N1 clock cycles and output
// the real and imag parts. N1 (N1 < 20) simulates the number of clocks 
// this module requires to compute the outputs

real2cpx real2cpx_X_uw (
	.clock(clock),
	.IN(rx2),
	.EN(1'b1),
	.reset(reset),
	.Re(rXrealuw),
	.Im(rXimaguw)
);

real2cpx real2cpx_X_dw (
	.clock(clock),
	.IN(rx4),
	.EN(1'b1),
	.reset(reset),
	.Re(rXrealdw),
	.Im(rXimagdw)
);

real2cpx real2cpx_Y_uw (
	.clock(clock),
	.IN(rx3),
	.EN(1'b1),
	.reset(reset),
	.Re(rYrealuw),
	.Im(rYimaguw)
);

real2cpx real2cpx_Y_dw (
	.clock(clock),
	.IN(rx1),
	.EN(1'b1),
	.reset(reset),
	.Re(rYrealdw),
	.Im(rYimagdw)
);


always @(posedge clock) begin
	if (reset) begin
		i1 <= 0;
	end
	else if (endata) begin
		i1 <= i1 + 1;
	end
end

/*always @(posedge endata)
begin
  repeat( 15 )
    @(posedge clock); // wait 15 clocks (something less than 20!)*/
  // Load the output registers with imag/real data read from sim files:
  /*dummy_rXimaguw <= vimaguwX[i1];
  dummy_rXimagdw <= vimagdwX[i1];
  dummy_rYimaguw <= vimaguwY[i1];
  dummy_rYimagdw <= vimagdwY[i1];
              
  dummy_rXrealuw <= vrealuwX[i1];
  dummy_rXrealdw <= vrealdwX[i1];
  dummy_rYrealuw <= vrealuwY[i1];
  dummy_rYrealdw <= vrealdwY[i1];
  
  i1 <= i1 + 1;
end*/

//----------------------------------------------------------------
// Simulate module phasecalc :
// whenever a new sample arrives, wait N2 clock cycles 
// and output the real-time phases: N2 (N2 < 20) simulates the number of clocks 
// this module requires to compute the outputs

wire phasecalc_X_uw_start = endata && (i1>0);
wire phasecalc_X_dw_start = phasecalc_X_uw_start;
wire phasecalc_Y_uw_start = phasecalc_X_uw_start;
wire phasecalc_Y_dw_start = phasecalc_X_uw_start;

wire phasecalc_X_uw_busy;
wire phasecalc_X_dw_busy;
wire phasecalc_Y_uw_busy;
wire phasecalc_Y_dw_busy;

phasecalc phasecalc_X_uw (
	.clock(clock),
	.reset(reset),
	.start(phasecalc_X_uw_start),
	.busy(phasecalc_X_uw_busy),
	.x(rXrealuw),
	.y(rXimaguw),
	.angle(rXphaseuw)
);

phasecalc phasecalc_X_dw (
	.clock(clock),
	.reset(reset),
	.start(phasecalc_X_dw_start),
	.busy(phasecalc_X_dw_busy),
	.x(rXrealdw),
	.y(rXimagdw),
	.angle(rXphasedw)
);

phasecalc phasecalc_Y_uw (
	.clock(clock),
	.reset(reset),
	.start(phasecalc_Y_uw_start),
	.busy(phasecalc_Y_uw_busy),
	.x(rYrealuw),
	.y(rYimaguw),
	.angle(rYphaseuw)
);

phasecalc phasecalc_Y_dw (
	.clock(clock),
	.reset(reset),
	.start(phasecalc_Y_dw_start),
	.busy(phasecalc_Y_dw_busy),
	.x(rYrealdw),
	.y(rYimagdw),
	.angle(rYphasedw)
);

/*always @(posedge endata)
begin
  if ( i1 > 0 )   // wait for the output of the previous module
  begin
    repeat( 17 )
      @(posedge clock); // wait 18 clock transitions (something less than 20!)
    // Load the output registers with the phase data read from sim files:
    dummy_rXphaseuw <= vphaseuwX[i2];
    dummy_rXphasedw <= vphasedwX[i2];
    dummy_rYphaseuw <= vphaseuwY[i2];
    dummy_rYphasedw <= vphasedwY[i2];
    i2 <= i2 + 1;  
  end

end*/

//----------------------------------------------------------------
// Simulate module phasediff:
// whenever a new sample arrives, wait N3 clock cycles 
// and output the real-time phase differences: N3 (N3 < 20) simulates 
// the number of clocks this module requires to compute the outputs
reg phasediff_X_sample;// = phasecalc_X_uw_busy && (i1>1);
reg phasediff_Y_sample;// = phasecalc_Y_uw_busy && (i1>1);
reg [2:0] cntX;
reg [2:0] cntY;

initial begin
	phasediff_X_sample = 1'b0;
	phasediff_Y_sample = 1'b0;
	cntX = 0;
	cntY = 0;
end

always @(posedge clock) begin
	if (phasecalc_X_uw_busy && (i1>1) && !cntX) begin
		phasediff_X_sample = 1'b1;
		cntX <= 3'b100;
	end
	else if (cntX) begin
		phasediff_X_sample = 1'b0;
		cntX <= cntX - 3'd1;
	end
end

always @(posedge clock) begin
	if (phasecalc_Y_uw_busy && (i1>1) && !cntY) begin
		phasediff_Y_sample = 1'b1;
		cntY <= 3'b100;
	end
	else if (cntY) begin
		phasediff_Y_sample = 1'b0;
		cntY <= cntY - 3'd1;
	end
end

wire phasediff_X_ready;
wire phasediff_Y_ready;

phasediff phasediff_X (
	.clock(clock),
	.reset(reset),
	.sample(phasediff_X_sample),
	.A(rXphasedw),
	.B(rXphaseuw),
	.out(rXphasediff),
	.ready(phasediff_X_ready)
);

phasediff phasediff_Y (
	.clock(clock),
	.reset(reset),
	.sample(phasediff_Y_sample),
	.A(rYphasedw),
	.B(rYphaseuw),
	.out(rYphasediff),
	.ready(phasediff_Y_ready)
);

/*always @(posedge endata)
begin
  if ( i2 > 0 )   // wait for the output of the previous module
  begin
    repeat( 4 )
      @(posedge clock); // wait 4 clock transitions (something less than 20!)
    // Load the output registers with the phasediff data read from sim files:
    rXphasediff <= vphasediffX[i3];
    rYphasediff <= vphasediffY[i3];
    i3 <= i3 + 1;
  end
end*/

//----------------------------------------------------------------
// Simulate module phase2speed:
// whenever a new sample arrives, wait less than 20 clock cycles 
// and output the averaged speed computed from the phase difference:

wire phase2speed_X_ready;
wire phase2speed_Y_ready;

phase2speed phase2speed_X (
	.clock(clock),
	.reset(reset),
	.sample(phasediff_X_ready),
	.meanlen(spdmeanlen),
	.phase(rXphasediff),
	.speed(rXspeed),
	.ready(phase2speed_X_ready)
);

phase2speed phase2speed_Y (
	.clock(clock),
	.reset(reset),
	.sample(phasediff_Y_ready),
	.meanlen(spdmeanlen),
	.phase(rYphasediff),
	.speed(rYspeed),
	.ready(phase2speed_Y_ready)
);

initial
begin
  speeden = 1'b0;
end

always @(posedge clock) begin
	speeden <= phase2speed_X_ready;
end
  
  /*@( posedge reset );
  #1
  @( negedge reset ); // wait for reset release
  
  forever
  begin
    repeat (1 << spdmeanlen) // wait 2^spdmeanlen sampling periods
      @(posedge endata);

    @(posedge clock); // 
    // Load the output registers with the speedX/Y data read from sim files:
    rXspeed = vspeedX[i4];
    rYspeed = vspeedY[i4];
  
    speeden = 1'b1;    // Set speed enable pulse for one clock period
    @(posedge clock); 
    speeden = 1'b0;
  
    i4 = i4 + 1;
  end
end*/

assign speedX = rXspeed;
assign speedY = rYspeed;

endmodule

				  