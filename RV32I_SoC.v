//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/28 17:18:21
// Design Name: 
// Module Name: RV32I_System
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RV32I_SoC(
    input   clk_125mhz, 
    input   btn,    // active high rst when button is pressed
    output [3:0] leds,  
/************** For 7 Seg LED Array (6 HEX)***************/
    output reg [7:0]   seg_data, 
    output reg [5:0]   seg_com
/**********************************************************/
/************** For Pmod SSD (2 HEX)***************/
//    output [6:0] ssd, 
//    output reg ssdcat
/************** For Pmod SSD (2 HEX)***************/    
    );
    
    wire clk, clk90, clk180;        //main clk, inst
    reg rst;
    wire [31:0] fetch_addr, data_addr, inst, write_data;
    wire [31:0] read_data_mem, read_data_gpio;
    reg [31:0] read_data;  
    wire cs_mem, cs_gpio, data_we, locked; 
    wire [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    reg [15:0] seg_cnt;
    reg [5:0]  seg_com; reg [7:0] seg_data;//0709 추가
    
    ram_2port_2048x32_2 iMEM (        //similar to ROM
    //Program MEM
        .clka (clk90),  //phase 90
        .ena (1'b1), 
        .wea (1'b0), 
        .addra (fetch_addr[12:2]),      //memory aligned to 4bytes
        .dina (32'b0), 
        .douta (inst), 
    //Data MEM
        .clkb (clk180), 
        .enb (cs_mem), 
        .web ({4{data_we}}),        //.--> prevent the BRAM from reading the memory by a byte.
        .addrb(data_addr[12:2]), 
        .dinb (write_data), 
        .doutb (read_data_mem)
  );
  
    clk_wiz_0 iPLL ( 
        .clk0(clk), 
        .clk90(clk90),
        .clk180(clk180), 
        .reset(btn),        //active high 
        .locked(locked),    //'1' after clock becomes stable
        .clk_in1(clk_125mhz)
    );
   
    always @ (posedge clk_125mhz) begin
        rst <= (~locked) | btn; //'1' when clock is not stable or btn is pressed. 
    end      
    
    ////////////////////////////////////////////////cpu////////////////////////////////////////////////////
    rv32i_cpu iCPU(
        .clk(clk),  
        .rst(rst),        //active high reset
        //Instruction Set interface
        .pc(fetch_addr),  
        .inst(inst), 
        //Data MEM interface
        .MemWen(data_we), 
        .MemAddr(data_addr), 
        .MemWdata(write_data),  
        .MemRdata(read_data) 
       );
       ////////////////////////////////////////////////////////////////////////////////////////////////////
       
    ////////////////////////////////////////////////////////////////////////////////////////////////////   
    always @* begin // more peripherals can be added
        if (cs_gpio) read_data = read_data_gpio;
        else read_data = read_data_mem; 
    end
    ////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //////////////////////////////////////////////////making the chip selection signal "cs_mem", "cs_gpio", ... //////////////////////////////////////////////////
    Addr_Decoder iDec( //chip select
        .addr(data_addr), 
        .cs_mem(cs_mem),
        .cs_gpio(cs_gpio)
        //else where...
    );
    
    GPIO iGPIO(
        .clk(clk), 
        .rst(rst), 
        .CS(cs_gpio),       //chip selection signal
        .REN(~data_we),
        .WEN(data_we),
        .Addr(data_addr[11:0]),  
        .DataIn(write_data),    //decoding????????????
        .DataOut(read_data_gpio),
        .HEX0(HEX0),
        .HEX1(HEX1),        
        .HEX2(HEX2),
        .HEX3(HEX3),        
        .HEX4(HEX4),
        .HEX5(HEX5),
        .LEDS(leds)        
        );
        

    always @ (posedge clk, posedge rst)
    begin  
        if (rst) seg_cnt <= 0; 
        else if (seg_cnt[15] == 1'b1) seg_cnt <= 0; 
        else seg_cnt <= seg_cnt +1; 
    end

/************** For 7 Seg LED Array (6 HEX)***************/ //0709 주석 해제
   
    always @ (posedge clk, posedge rst)
    begin  
        if (rst) seg_com <= 6'b100000;
        else if (seg_cnt[15] == 1'b1) seg_com <= {seg_com[0], seg_com[5:1]};
    end
        
    always @* begin
        case (seg_com)
            6'b000001 : seg_data = {HEX0, 1'b0};          
            6'b000010 : seg_data = {HEX1, 1'b0};
            6'b000100 : seg_data = {HEX2, 1'b0};
            6'b001000 : seg_data = {HEX3, 1'b0};
            6'b010000 : seg_data = {HEX4, 1'b0};
            6'b100000 : seg_data = {HEX5, 1'b0};
            default: seg_data = 8'b0;       
        endcase
    end
/**************************************************************/

/************** For Pmod SSD (2 HEX)***************/
//    always @ (posedge clk, posedge rst)
//    begin  
//        if (rst) ssdcat <= 1'b0;
//        else if (seg_cnt[15] == 1'b1) ssdcat <= ~ssdcat; 
//    end

//    assign ssd = (ssdcat == 0)? HEX0 : HEX1; 
/**************************************************************/
            
endmodule
