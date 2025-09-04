`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/09 19:55:35
// Design Name: 
// Module Name: mux1
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


module mux4in(
    input  wire [31:0] data1_i,
    input  wire [31:0] data2_i,
    input  wire [31:0] data3_i,
    input  wire [31:0] data4_i,
    input  wire [ 1:0] select_i,
    output reg  [31:0] data_o
    );

    always @(*)
    begin
        case (select_i)
            2'b00: data_o = data1_i;           
            2'b01: data_o = data2_i;
            2'b10: data_o = data3_i;
            2'b11: data_o = data4_i;
        endcase
    end 

endmodule
