// CPU top Operation Codes
`define OP_R        7'b0110011
`define OP_I_ARITH  7'b0010011
`define OP_I_LOAD   7'b0000011
`define OP_JALR     7'b1100111
`define OP_S        7'b0100011
`define OP_B        7'b1100011
`define OP_LUI      7'b0110111
`define OP_AUIPC    7'b0010111
`define OP_JAL      7'b1101111

// ALU Operation Codes
`define ALU_ADD   5'b0_0000
`define ALU_SUB   5'b0_0001
`define ALU_XOR   5'b0_0010
`define ALU_OR    5'b0_0011
`define ALU_AND   5'b0_0100
`define ALU_SLL   5'b0_0101
`define ALU_SRL   5'b0_0110
`define ALU_SRA   5'b0_0111
`define ALU_SLT   5'b0_1000
`define ALU_SLTU  5'b0_1001

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module rv32i_cpu(
        input   clk, 
        input   rst,
        output reg [31:0]  pc, //program counter (address for instruction)
        input   [31:0]  inst, //instruction from memory
        output  MemWen, 	
        output  [31:0]  MemAddr, 
        output  [31:0]  MemWdata, 
        input   [31:0]  MemRdata 
    );

///////////////////////////////////////////////////////////////////////////////Type Definition///////////////////////////////////////////////////////////////

    wire [6:0] opcode; 
    wire [4:0] rs1, rs2, rd;
    wire [31:0] rs1_data, rs2_data, rd_data;     
    wire [6:0] funct7; 
    wire [2:0] funct3;

    reg [31:0] alusrc1, alusrc2;    
    wire [31:0] aluout; 
    reg [4:0] alucontrol;   
    reg alusrc, regwrite, lui, memwrite, memread;
    wire flag_eq, flag_lt ,flag_ltu;

    wire Nflag, Zflag, Cflag, Vflag; 
    
    //mux1
    wire [31:0] mux1_data_o;
    wire [31:0] ResultSrc_o;
    wire [31:0] pc_plus_4;
    wire [ 1:0] m1_select_i;
    reg [1:0] m1_select;

    //mux2
    wire [31:0] mux2_data_o;
    wire [31:0] ext_12_added;
    wire [31:0] ext_20_added;
    wire [ 1:0] m2_select_i, pc_sel;
    reg  [1:0]  m2_select;
    reg branch, jalr, jal;

    //mux3
    //alusrc, rs2_data, {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0}
////////////////////////////////////////////////////////////////////////////Registers//////////////////////////////////////////////////////////////////////

// register for pc

    always @ (posedge clk, posedge rst)
    begin
        if (rst)
            pc <= 0; 
        else
            pc <= mux2_data_o;// !!  pc <= pc+4; 
    end

////////////////////////////////////////////////////    
           
    // register file
    regfile regfile_inst( 
        .clk(clk), 
        .we(regwrite),
        .rst(rst),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );  
////////////////////////////////////////////////////////wiring between instruction_memory  -> regfile //////////////////////////////////////////////////////

    assign rs1 = inst[19:15]; 
    assign rs2 = inst[24:20];
    assign rd = inst[11:7];

   

//////////////////////wiring between instruction_memory -> control_unit///////////////////////

    assign opcode = inst[6:0];
    assign funct7 = inst[31:25];
    assign funct3 = inst[14:12];

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////ALU_controller ?????? 0710////////////////////////////////////// 
    always @* begin
    case (opcode)
        `OP_R: begin // R-type
            case ({funct7, funct3})
                10'b0000000_000: alucontrol = `ALU_ADD; // ADD
                10'b0100000_000: alucontrol = `ALU_SUB; // SUB
                10'b0000000_100: alucontrol = `ALU_XOR; // XOR
                10'b0000000_110: alucontrol = `ALU_OR;  // OR
                10'b0000000_111: alucontrol = `ALU_AND; // AND
                10'b0000000_001: alucontrol = `ALU_SLL; // SLL
                10'b0000000_101: alucontrol = `ALU_SRL; // SRL
                10'b0100000_101: alucontrol = `ALU_SRA; // SRA
                10'b0000000_010: alucontrol = `ALU_SLT; // SLT
                10'b0000000_011: alucontrol = `ALU_SLTU;// SLTU
                default:         alucontrol = `ALU_ADD;
            endcase
        end
        `OP_I_ARITH: begin // I-type Arithmetic
            case (funct3)
                3'b000: alucontrol = `ALU_ADD; // ADDI
                3'b100: alucontrol = `ALU_XOR; // XORI
                3'b110: alucontrol = `ALU_OR;  // ORI
                3'b111: alucontrol = `ALU_AND; // ANDI
                3'b001: alucontrol = `ALU_SLL; // SLLI
                3'b101: begin
                    if (funct7[5]) alucontrol = `ALU_SRA; // SRAI
                    else           alucontrol = `ALU_SRL; // SRLI
                end
                3'b010: alucontrol = `ALU_SLT; // SLTI
                3'b011: alucontrol = `ALU_SLTU;// SLTIU
                default: alucontrol = `ALU_ADD;
            endcase
        end
        `OP_I_LOAD, `OP_S,  `OP_LUI, `OP_AUIPC, `OP_JALR, `OP_JAL : alucontrol = `ALU_ADD; // ?????, AUIPC, JALR, JAL, LUI ***
        
        `OP_B: begin // Branch
            alucontrol = `ALU_SUB;
        end
    //         case (funct3)
    //             3'b000: alucontrol = `ALU_SUB; // BEQ
    //             3'b001: alucontrol = `ALU_SUB; // BNE
    //             3'b100: alucontrol = `ALU_SUB; // BLT
    //             3'b101: alucontrol = `ALU_SUB; // BGE
    //             3'b110: alucontrol = `ALU_SUB;// BLTU
    //             3'b111: alucontrol = `ALU_SUB;// BGEU
    //             default: alucontrol = `ALU_SUB;
    //         endcase
    //     end
    //     default: alucontrol = `ALU_ADD;
    endcase
end

    
////////////////////////////////////////ALU_controller ???? ????////////////////////////////////////// 
    //generate constrol signal for alu 
//    always @* begin
//        case (opcode)
//            `OP_R: //R-type
//                case ({funct7,funct3}) 
//                    10'b0000000_000: alucontrol = 5'b0_0000; 
//                    default: alucontrol = 5'b0_0000;
//                endcase
//            `OP_I_ARITH: //I-Type Arithemtic
//                case (funct3)
//                    3'b000 : alucontrol = 5'b0_0000; 
//                    default: alucontrol = 5'b0; 
//                endcase
//            `OP_LUI, //LUI
//            `OP_S: //S-type
//                alucontrol = 5'b0;
//            default: 
//                alucontrol = 5'b0;
//        endcase
//    end

/////////////////////////////////////Control_Unit///////////////////////////////////////// 0709
    //generate various control signals according to opcode
    always @* begin
        case (opcode)
            `OP_R: begin //R-type
                alusrc = 1'b0; 
                regwrite = 1'b1;
                lui = 1'b0; 
                memwrite = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0; 
                memread = 1'b0;
            end 
            `OP_I_ARITH: begin //I-type
                alusrc = 1'b1; 
                regwrite = 1'b1;
                lui = 1'b0; 
                memwrite = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
                memread = 1'b0;
            end
            `OP_I_LOAD: begin   //???????
                alusrc = 1'b1; 
                regwrite = 1'b1;
                lui = 1'b0; 
                memwrite = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
                memread = 1'b1;
            end
            `OP_LUI: begin
                alusrc = 1'b0; //????X 0710
                regwrite = 1'b1;
                lui = 1'b1; 
                memwrite = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
                memread = 1'b0;
             end
             `OP_S: begin
                 alusrc = 1'b0; 
                 regwrite = 1'b0;
                 lui = 1'b0; 
                 memwrite = 1'b1;
                 branch = 1'b0;
                 jal = 1'b0;
                 jalr = 1'b0;
                 memread = 1'bx;
                 end
             `OP_B: begin           //B ???
                 alusrc = 1'b0; 
                 regwrite = 1'b0;
                 lui = 1'b0; 
                 memwrite = 1'b0;
                branch = 1'b1;         //B ????? ?????? ???? ??? ???...******
                    
                
                 jalr = 1'b0;
                 memread = 1'bx;
                 end
             `OP_JAL: begin     //??????? 
                 alusrc = 1'b0; 
                 regwrite = 1'b1;
                 lui = 1'b0; 
                 memwrite = 1'b0;
                 branch = 1'b0;
                 jal = 1'b1;
                 jalr = 1'b0;
                 memread = 1'bx;
             end
             `OP_JALR: begin  //??????? 
                 alusrc = 1'b1; 
                 regwrite = 1'b1;
                 lui = 1'b0; 
                 memwrite = 1'b0;
                 branch = 1'b0;
                 jal = 1'b0;
                 jalr = 1'b1;
                 memread = 1'b0;
             end
             default: begin
                alusrc = 1'b0;
                regwrite = 1'b0;
                lui = 1'b0;
                memwrite = 1'b0;
                branch = 1'b0;
                jal = 1'b0;
                jalr = 1'b0;
                memread = 1'b0;
            end
         endcase
    end 
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  alusrc1 ---> |
//               |       |   
//                    >  | ---> 
//               |       |
//  alusrc2 ---> |
/////////////////////////////////////nMUX_32b for the first ALU input/////////////////////////////////////////



/////////////////////////////////////nMUX_32b+concetanation block for the second ALU input ==> I-type////////////////////////////////////////

    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////ALU module//////////////////////////////////////////////
      
    alu alu_inst(
          .a(alusrc1), 
          .b(alusrc2),
          .control(alucontrol),
          .result(aluout),
          .N(Nflag),
          .Z(Zflag),
          .C(Cflag),
          .V(Vflag)
    );   
    
    //Flag input, branch output Logic



////////////////////////////////////////////////////mux////////////////////////////////////////////////////////// 0709
    //*************************mux1*************************
     always @(*) begin
        if(regwrite) begin
            casex({MemtoReg, jal, jalr})
                3'b001 :    m1_select = 2'b00;  //jalr
                3'b100 :    m1_select = 2'b01;  //lw 
                3'b010 :    m1_select = 2'b10;  //jal
                3'b000 :    m1_select = 2'b11;  //default
                default:    m1_select = 2'b11;
            endcase 
        end
        else m1_select = 2'b11;
    end
    
    mux4in mux1_inst(
    .data1_i(pc_plus_4),   //jalr  00   //??????? 0711 aluout --> pc_plus_4
    .data2_i(MemRdata), //load  01
    .data3_i(pc_plus_4),         //jal  10
    .data4_i(aluout),            
    .select_i(m1_select_i),
    .data_o(mux1_data_o)
    );
    
    //*************************mux2*************************
    always @(*) begin
        casex({btaken, jal, jalr})
        3'b000 :    m2_select = 2'b00;
        3'b100 :    m2_select = 2'b01;  //B
        3'b001 :    m2_select = 2'b10;  //jalr
        3'b010 :    m2_select = 2'b11;  //jal
        default:    m2_select = 2'b00;
        endcase 
    end
    
    mux4in mux2_inst(
    .data1_i(pc_plus_4),        //generally...  00
    .data2_i(ext_12_added),     //B             01  ext_12_added
    .data3_i(aluout),           //jalr          10  aluout
    .data4_i(ext_20_added),     //jal           11
    .select_i(m2_select_i),
    .data_o(mux2_data_o)
    );
    
    //*************************mux3*************************{{20{Instr[31]}}, Instr[31:25], Instr[11:7]};                  s
    wire btaken;
    always @* begin
        if (alusrc) alusrc2 = {{20{inst[31]}}, inst[31:20]};                     //I
        else if (lui) alusrc2 = {inst[31:12], 12'b0};                            //U        ????
        else if (memwrite) alusrc2 = {{20{inst[31]}}, inst[31:25], inst[11:7]};  //S
        else if (branch) alusrc2 = rs2_data; //B
        else alusrc2 = rs2_data;                                                 //R ?
    end
    
    assign btaken =   branch && ( ((funct3==3'b000) & Zflag)|              // BEQ
                            ((funct3==3'b001) & ~Zflag)|             // BNE
                            ((funct3==3'b100) & Nflag ^ Vflag)|      // BLT
                            ((funct3==3'b101) & ~(Nflag ^ Vflag))|   // BGE
                            ((funct3==3'b110) & ~Cflag)|             // BLTU
                            ((funct3==3'b111) & Cflag)) ;              // BGEU
    //*************************mux4*************************
    //for alusrc1, alusrc2
    always @* begin
        if (lui) alusrc1 = 0; 
        else alusrc1 = rs1_data; 
    end
    
    
///////////////////////////////////////////////////wiring of output ports with the internal wires/////////////////0709//////////////////////////////////////////
    
    assign rd_data = mux1_data_o;// ?????? assign rd_data = aluout;
    assign MemAddr = aluout;        //sw
    assign MemWdata = rs2_data;     //sw
    assign MemWen = memwrite; 
    assign pc_plus_4 = pc+4;
//    assign m2_select_i = pc_sel;    //?????? ???
//    assign mux2_data_o = pc;
    assign ext_12_added = pc + ({{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0});  //B, jalr(I)x   //??? ??????? ????
    assign ext_20_added = pc + ({{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0});  //JAL, auipc?
    assign m2_select_i = m2_select;
    assign m1_select_i = m1_select;
    assign MemtoReg = memread;
    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
