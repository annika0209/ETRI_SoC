`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/28 19:16:39
// Design Name: 
// Module Name: tb_RV32I_SoC
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


module tb_RV32I_SoC();

reg     clk_125mhz, btn; 
wire    [3:0] leds;
wire    [7:0] seg_data;
wire    [5:0] seg_com; 

RV32I_SoC   DUT (clk_125mhz, btn, leds, seg_data, seg_com); 

initial begin
    clk_125mhz = 1'b0; 
    btn = 1'b0; //not pressed
    #10000000;
    $stop;
end
     

always begin
    #4; clk_125mhz = ~clk_125mhz; //125MHz clk
end

endmodule
