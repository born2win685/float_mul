module float_mul(input [0:15] num1,input [0:15] num2,output [0:15] out);//,output wire [0:10] mask,output wire [0:9] exp);
  
    wire s1,s2;
    wire [0:7] ex1,ex2;
    wire [0:8] m1,m2;
    
    wire s;
    wire [0:9] exp;
    wire [0:10] mant;
    wire [0:10] mask;
    wire [0:9] exponent;
    wire [0:6] mantissa;
    
    assign s1=num1[0];
    assign s2=num2[0];
    assign ex1=num1[1:8];
    assign ex2=num2[1:8];
    assign m1={2'b01,num1[9:15]};//mantissa is not signed so we add 0 so that booth multiplier considers both as positive numbers
    assign m2={2'b01,num2[9:15]};//1 is added because only decimal value is written in mantissa
    
    
    sign_exp se(s1,s2,ex1,ex2,s,exp);
    prec_ctrl pc(exp,mask);
    booth_mul bm(m1,m2,mask,mant);
    normal nz(mant,exp,exponent,mantissa);
    
    assign out={s,exponent[2:9],mantissa};
endmodule

module sign_exp(input s1,input s2,input [0:7] ex1,input [0:7] ex2,output s,output [0:9] exp);
    assign s=s1^s2;
    assign exp={2'b0,ex1}+{2'b0,ex2}-10'd254;    
endmodule

module normal(input [0:10] mant,input [0:9] exp,output [0:9] exponent,output [0:6] mantissa);
   assign mantissa=mant[2:8];
   assign exponent=exp+1'b1+10'd127;
endmodule

module prec_ctrl(input [0:9] exp,output reg [0:10] mask);
    wire [0:3] rg;
    assign rg=exp[2:5];
    always@(*) begin
    case(rg) 
    4'b0000:mask=11'b11111111111;
    4'b0001:mask=11'b11111111110;
    4'b0010:mask=11'b11111111100;
    4'b0011:mask=11'b11111111000;
    4'b0100:mask=11'b11111110000;
    4'b0101:mask=11'b11111100000;
    4'b0110:mask=11'b11111000000;
    4'b0111:mask=11'b11110000000;
    4'b1000:mask=11'b11110000000;
    4'b1001:mask=11'b11111000000;
    4'b1010:mask=11'b11111100000;
    4'b1011:mask=11'b11111110000;
    4'b1100:mask=11'b11111111000;
    4'b1101:mask=11'b11111111100;
    4'b1110:mask=11'b11111111110;
    4'b1111:mask=11'b11111111111;
    default:mask=11'b11111111111;
    endcase
    end
endmodule


module booth_mul(input wire [8:0] A,input wire [8:0] B,input [10:0] mask,output wire [10:0] P);//,output wire [10:0] pro);//,output [15:0] pp1,output [15:0] pp2,output [15:0] pp3,output [15:0] pp4);//,output [10:0] p1,output [10:0] p2,output [10:0] p3,output [10:0] p4 );
        reg [2:0] bits[4:0];
        reg [9:0] pp[4:0];
        
        //wire [10:0] p1,p2,p3,p4;
        wire [8:0] A_;//minus A
        wire [15:0] pp1;
        wire [15:0] pp2;
        wire [15:0] pp3;
        wire [15:0] pp4;
        wire [15:0] pp5;
        integer m1;
        assign A_=~A+1;
        
        always@(A or B or A_) begin
        
        bits[0]={B[1],B[0],1'b0};
        bits[4]=3'b001;
        
        for(m1=1;m1<4;m1=m1+1)
            bits[m1]={B[2*m1+1],B[2*m1],B[2*m1-1]};
        
        for(m1=0;m1<5;m1=m1+1) begin
            case(bits[m1])
            
            3'b001:pp[m1]={1'b0,A};
            3'b010:pp[m1]={1'b0,A};
            3'b011:pp[m1]={A,1'b0};
            3'b100:pp[m1]={A_,1'b0};
            3'b101:pp[m1]={A_[8],A_};
            3'b110:pp[m1]={A_[8],A_};
            default:pp[m1]=0;
                        
            endcase
        end
        end
        
        assign pp1={{6{pp[0][9]}},pp[0]};
        assign pp2={{4{pp[1][9]}},pp[1],2'b0};
        assign pp3={{2{pp[2][9]}},pp[2],4'b0};
        assign pp4={pp[3],6'b0};
        assign pp5={pp[4][7:0],8'b0};
        //assign P=pp1+pp2+pp3+pp4;
        pp_adder ppa(mask,pp1,pp2,pp3,pp4,pp5,P);//,p1,p2,p3,p4);
        
endmodule

module pp_adder(input [10:0] mask, input [15:0] pp1,input [15:0] pp2,input [15:0] pp3,input [15:0] pp4,input [15:0] pp5,output [10:0] prod);//,output [10:0] actual_prod);//,output [10:0] p1,output [10:0] p2,output [10:0] p3,output [10:0] p4);
    wire [10:0] p1,p2,p3,p4,p5;
    //wire [11:0] pr;
    assign p1 = pp1[15:5] & mask;
    assign p2 = pp2[15:5] & mask;
    assign p3 = pp3[15:5] & mask;
    assign p4 = pp4[15:5] & mask;
    assign p5 = pp5[15:5] & mask;   
    
    assign prod=pp1[15:5]+pp2[15:5]+pp3[15:5]+pp4[15:5]+pp5[15:5];
endmodule
