// ALU Operation Codes
`define ALU_ADD   5'b0_0000 // addition (a + b)             : ADD, ADDI, LW, SW, etc.
`define ALU_SUB   5'b0_0001 // subtraction (a - b)          : SUB, BEQ, BNE, BLT, BGE, BLTU, BGEU, etc.
`define ALU_XOR   5'b0_0010 // bitwise XOR                  : XOR, XORI, etc.
`define ALU_OR    5'b0_0011 // bitwise OR                   : OR, ORI, etc.
`define ALU_AND   5'b0_0100 // bitwise AND                  : AND, ANDI, etc.
`define ALU_SLL   5'b0_0101 // logical left shift           : SLL, SLLI, etc.
`define ALU_SRL   5'b0_0110 // logical right shift          : SRL, SRLI, etc.
`define ALU_SRA   5'b0_0111 // arithmetic right shift       : SRA, SRAI, etc.
`define ALU_SLT   5'b0_1000 // signed less than             : SLT, SLTI, etc.
`define ALU_SLTU  5'b0_1001 // unsigned less than           : SLTU, SLTIU, etc.

// `define ALU_BEQ   5'b0_1010 // branch if equal
// `define ALU_BNE   5'b0_1011 // branch if not equal
// `define ALU_BLT   5'b0_1100 // branch if less than
// `define ALU_BGE   5'b0_1101 // branch if greater than or equal
// `define ALU_BLTU  5'b0_1110 // branch if less than unsigned
// `define ALU_BGEU  5'b0_1111 // branch if greater than or equal unsigned


module alu(
    input   [31:0]  a, b,
    input   [4:0]   control,
    output   reg [31:0]  result,
    output   N,
    output   Z,
    output   C,
    output   V
    );
    
    //var
    wire [31:0] c0;
    wire [32:0] c1;  //overflow
    
    wire [31:0] Add;
    wire [31:0] Sub, inv_b;
    
/********************************************************************************/


// case statements
// use addsub module in digital system course
    always @(*) begin
        case (control)
            `ALU_ADD:   result = Add;
            `ALU_SUB:   result = Sub;
            `ALU_XOR:   result = a ^ b;                              
            `ALU_OR:    result = a | b;                           
            `ALU_AND:   result = a & b;                           
            `ALU_SLL:   result = a << b[4:0];                         
            `ALU_SRL:   result = a >> b[4:0];                         
            `ALU_SRA:   result = $signed(a) >>> b[4:0];         
            `ALU_SLT:   result = ($signed(a) < $signed(b)) ? 1 : 0;   
            `ALU_SLTU:  result = (a < b) ? 1 : 0;                    
            default:    result = 0;                            
            
        endcase
    end

    
/********************************************************************************/
assign N = result[31];
assign Z = (result == 32'b0);
assign C = c1[32];
assign V = c1[31] ^ c1[32];

assign inv_b = b^{32{1'b1}};    // ~b


/********************************************************************************/
adder u_add32 (.a(a),.b(b),.cin(1'b0),.cout(c0[31:0]),.sum(Add));
adder u_sub32 (.a(a),.b(inv_b),.cin(1'b1),.cout(c1[32:1]),.sum(Sub));

endmodule
