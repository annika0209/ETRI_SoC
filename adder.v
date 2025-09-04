
//N-Bit Full adder module 
module adder  #(parameter N = 32)
   (input [N-1:0] a, b,
    input cin,
    output [N-1:0] sum,
    output [N-1:0] cout
);

genvar i;

generate
for(i=0; i<N-1; i=i+1)
begin: Full_adder_block
  if(i==0)
      One_bit_FA fa0(a[i],b[i],cin,cout[0],sum[0]);
    
  else
      One_bit_FA fa(a[i],b[i],cout[i-1],cout[i],sum[i]);

end
endgenerate

One_bit_FA fa1(a[N-1],b[N-1],cout[N-2],cout[N-1],sum[N-1]);

endmodule

//1-Bit Full adder module
module One_bit_FA(
    input a,b,
    input cin,
    output cout,sum);
	
    assign sum  = a^b^cin;
    assign cout = (a&b)|(b&cin)|(cin&a);
endmodule
