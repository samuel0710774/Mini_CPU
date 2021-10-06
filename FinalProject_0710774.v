module proc(
	// Input signals
	DIN,
	Reset,
	Clock,
	Run,
	// Output signals
	Done,
	Bus,
	R0,
	R1,
	R2,
	R3,
	R4,
	R5,
	R6,
	R7
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION                         
//---------------------------------------------------------------------
input [7:0]DIN;
input Reset, Clock, Run;
output Done;
output [7:0]Bus;
output [7:0]R0, R1, R2, R3, R4, R5, R6, R7;

//---------------------------------------------------------------------
//  STRUCTURE CODING                         
//---------------------------------------------------------------------

wire [7:0] Gd,Gq,Aq,IRq;
wire [7:0] Rin,Rout;
wire [1:0] step;

wire clear,IRin,Gin,Gout,DINOut,AIn,add_sub;

//register assign:clock/enable/wire/data
Register_8bits r0(Clock,Rin[0],Bus,R0); 
Register_8bits r1(Clock,Rin[1],Bus,R1);
Register_8bits r2(Clock,Rin[2],Bus,R2);
Register_8bits r3(Clock,Rin[3],Bus,R3);
Register_8bits r4(Clock,Rin[4],Bus,R4);
Register_8bits r5(Clock,Rin[5],Bus,R5);
Register_8bits r6(Clock,Rin[6],Bus,R6);
Register_8bits r7(Clock,Rin[7],Bus,R7);

//Add_sub unit
Register_8bits A(Clock,AIn,Bus,Aq);
Register_8bits G(Clock,Gin,Gd,Gq);
Add_Sub Addsub(add_sub,Aq,Bus,Gd);

multiplexer M(Rout,Gout,DINOut,DIN,R0,R1,R2,R3,R4,R5,R6,R7,Gq,Bus);

Register_8bits ir(Clock,IRin,DIN,IRq); //get Instruction

Count_step stepUpdate(Clock,clear,step); 

control_Unit CU(IRq,Run,Reset,step,clear,IRin,Rout,Gout,DINOut,Rin,AIn,Gin,add_sub,Done);

endmodule


module Register_8bits(clk,enable,d,q);
input clk,enable;
input [7:0]d;
output reg[7:0]q;

always @(posedge clk) begin
	if(enable)
		q<=d;
	else
		q<=q;
end

endmodule


module Count_step(clk,clear,Q);
input clk,clear;
output reg[1:0] Q;

always @(posedge clk) begin
	if(clear==1'b1)
		Q<=Q+1;
	else
		Q<=0;
end

endmodule


module multiplexer(Rout,Gout,DINout,DIN,R0,R1,R2,R3,R4,R5,R6,R7,G,BUS);
input [7:0]Rout,G,DIN,R0,R1,R2,R3,R4,R5,R6,R7;
input Gout,DINout;
output reg[7:0]BUS;

always @(*) begin
	if(Gout) 
		BUS<=G;
	else if(DINout)
		BUS<=DIN;
	else if(Rout[0])
		BUS<=R0;
	else if(Rout[1])
		BUS<=R1;
	else if(Rout[2])
		BUS<=R2;
	else if(Rout[3])
		BUS<=R3;
	else if(Rout[4])
		BUS<=R4;
	else if(Rout[5])
		BUS<=R5;
	else if(Rout[6])
		BUS<=R6;
	else if(Rout[7])
		BUS<=R7;
	else BUS<=BUS;
end

endmodule
		

module Add_Sub(add_sub,A,B,sum);
input add_sub;
input [7:0]A,B;
output reg[7:0]  sum;

//add_sub=0 --> ADD
//add_sub=1 --> SUB
always @(add_sub,A,B) begin
	if(!add_sub)
		sum <= A+B;
	else
		sum <= A-B;
end

endmodule

module control_Unit(Ir,Run,resetN,step,clear,IRin,Rout,Gout,DINout,Rin,AIn,Gin,add_sub,Done);
input [7:0] Ir; //instruction
input Run,resetN;
input[1:0] step;
output clear,IRin,Gout,DINout,AIn,Gin,add_sub,Done;
output[7:0] Rout,Rin;

wire[7:0]x,y,rXOut,rYOut;
wire [1:0]op;

assign op = Ir[7: 6];

//one hot code
hot_code3_8 xIndex(Ir[5: 3],x); 
hot_code3_8 yIndex(Ir[2: 0],y);

assign rXOut = {8{step==1}}&{8{op[1]}}&x;
assign rYOut = ({8{step==1}}&{8{op==2'b00}}&y)|({8{step==2}}&{8{op[1]}}&y);
assign IRin = ((step==0)&Run) & resetN;
assign clear = resetN&(~((step==0)&(~Run)))&(~Done);
assign Gout = ((step==3)&(op[1]))&resetN;
assign DINout = ((step==1)&(op==2'b01))&resetN;
assign AIn = ((step==1)&(op[1]))& resetN;
assign Gin = ((step==2)&(op[1]))&resetN;
assign add_sub = (step==2)&(op==2'b11);
assign Done = ((~op[1])&(step==1))|((op[1])&(step==3));
assign Rout = (rXOut | rYOut) &{8{resetN}};
assign Rin = (({8{step==1}}&{8{~op[1]}}&x)|({8{step==3}}&{8{op[1]}}&x))&{8{resetN}};

endmodule

module hot_code3_8(d, y);
input[2: 0] d;
output reg[7: 0] y;

always @(d) begin
    case(d)
        3'b000: y=8'b00000001;
        3'b001: y=8'b00000010;
        3'b010: y=8'b00000100;
        3'b011: y=8'b00001000;
        3'b100: y=8'b00010000;
        3'b101: y=8'b00100000;
        3'b110: y=8'b01000000;
        3'b111: y=8'b10000000;
		  default:y=8'b00000000;
    endcase
end

endmodule
