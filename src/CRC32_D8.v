//===========================================================================
//calu mode is big endian, the first serial bit is D[7].
//crc generation polynomial is:
//	32 26 23 22 16 12 11 10 8 7 5 4 2 1 0 
//===========================================================================

module crc32_d8(C,D,C_OUT);

	input [31:0]	C;	//reset value of C_OUT
	input [7:0]	D;
	output [31:0]	C_OUT;

	assign C_OUT[ 0] =	C[24] ^ C[30] ^ D[ 0] ^ D[ 6];
	assign C_OUT[ 1] =	C[24] ^ C[25] ^ C[30] ^ C[31] ^ D[ 0] ^ D[ 1] ^ D[ 6] ^ D[ 7];
	assign C_OUT[ 2] =	C[24] ^ C[25] ^ C[26] ^ C[30] ^ C[31] ^ D[ 0] ^ D[ 1] ^ D[ 2] ^ 
						D[ 6] ^ D[ 7];
	assign C_OUT[ 3] =	C[25] ^ C[26] ^ C[27] ^ C[31] ^ D[ 1] ^ D[ 2] ^ D[ 3] ^ D[ 7];
	assign C_OUT[ 4] =	C[24] ^ C[26] ^ C[27] ^ C[28] ^ C[30] ^ D[ 0] ^ D[ 2] ^ D[ 3] ^ 
						D[ 4] ^ D[ 6];
	assign C_OUT[ 5] =	C[24] ^ C[25] ^ C[27] ^ C[28] ^ C[29] ^ C[30] ^ C[31] ^ D[ 0] ^ 
						D[ 1] ^ D[ 3] ^ D[ 4] ^ D[ 5] ^ D[ 6] ^ D[ 7];
	assign C_OUT[ 6] =	C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30] ^ C[31] ^ D[ 1] ^ D[ 2] ^ 
						D[ 4] ^ D[ 5] ^ D[ 6] ^ D[ 7];
	assign C_OUT[ 7] =	C[24] ^ C[26] ^ C[27] ^ C[29] ^ C[31] ^ D[ 0] ^ D[ 2] ^ D[ 3] ^ 
						D[ 5] ^ D[ 7];
	assign C_OUT[ 8] =	C[ 0] ^ C[24] ^ C[25] ^ C[27] ^ C[28] ^ D[ 0] ^ D[ 1] ^ D[ 3] ^ 
						D[ 4];
	assign C_OUT[ 9] =	C[ 1] ^ C[25] ^ C[26] ^ C[28] ^ C[29] ^ D[ 1] ^ D[ 2] ^ D[ 4] ^ 
						D[ 5];
	assign C_OUT[10] =	C[ 2] ^ C[24] ^ C[26] ^ C[27] ^ C[29] ^ D[ 0] ^ D[ 2] ^ D[ 3] ^ 
						D[ 5];
	assign C_OUT[11] =	C[ 3] ^ C[24] ^ C[25] ^ C[27] ^ C[28] ^ D[ 0] ^ D[ 1] ^ D[ 3] ^ 
						D[ 4];
	assign C_OUT[12] =	C[ 4] ^ C[24] ^ C[25] ^ C[26] ^ C[28] ^ C[29] ^ C[30] ^ D[ 0] ^ 
						D[ 1] ^ D[ 2] ^ D[ 4] ^ D[ 5] ^ D[ 6];
	assign C_OUT[13] =	C[ 5] ^ C[25] ^ C[26] ^ C[27] ^ C[29] ^ C[30] ^ C[31] ^ D[ 1] ^ 
						D[ 2] ^ D[ 3] ^ D[ 5] ^ D[ 6] ^ D[ 7];
	assign C_OUT[14] =	C[ 6] ^ C[26] ^ C[27] ^ C[28] ^ C[30] ^ C[31] ^ D[ 2] ^ D[ 3] ^ 
						D[ 4] ^ D[ 6] ^ D[ 7];
	assign C_OUT[15] =	C[ 7] ^ C[27] ^ C[28] ^ C[29] ^ C[31] ^ D[ 3] ^ D[ 4] ^ D[ 5] ^ 
						D[ 7];
	assign C_OUT[16] =	C[ 8] ^ C[24] ^ C[28] ^ C[29] ^ D[ 0] ^ D[ 4] ^ D[ 5];
	assign C_OUT[17] =	C[ 9] ^ C[25] ^ C[29] ^ C[30] ^ D[ 1] ^ D[ 5] ^ D[ 6];
	assign C_OUT[18] =	C[10] ^ C[26] ^ C[30] ^ C[31] ^ D[ 2] ^ D[ 6] ^ D[ 7];
	assign C_OUT[19] =	C[11] ^ C[27] ^ C[31] ^ D[ 3] ^ D[ 7];
	assign C_OUT[20] =	C[12] ^ C[28] ^ D[ 4];
	assign C_OUT[21] =	C[13] ^ C[29] ^ D[ 5];
	assign C_OUT[22] =	C[14] ^ C[24] ^ D[ 0];
	assign C_OUT[23] =	C[15] ^ C[24] ^ C[25] ^ C[30] ^ D[ 0] ^ D[ 1] ^ D[ 6];
	assign C_OUT[24] =	C[16] ^ C[25] ^ C[26] ^ C[31] ^ D[ 1] ^ D[ 2] ^ D[ 7];
	assign C_OUT[25] =	C[17] ^ C[26] ^ C[27] ^ D[ 2] ^ D[ 3];
	assign C_OUT[26] =	C[18] ^ C[24] ^ C[27] ^ C[28] ^ C[30] ^ D[ 0] ^ D[ 3] ^ D[ 4] ^ 
						D[ 6];
	assign C_OUT[27] =	C[19] ^ C[25] ^ C[28] ^ C[29] ^ C[31] ^ D[ 1] ^ D[ 4] ^ D[ 5] ^ 
						D[ 7];
	assign C_OUT[28] =	C[20] ^ C[26] ^ C[29] ^ C[30] ^ D[ 2] ^ D[ 5] ^ D[ 6];
	assign C_OUT[29] =	C[21] ^ C[27] ^ C[30] ^ C[31] ^ D[ 3] ^ D[ 6] ^ D[ 7];
	assign C_OUT[30] =	C[22] ^ C[28] ^ C[31] ^ D[ 4] ^ D[ 7];
	assign C_OUT[31] =	C[23] ^ C[29] ^ D[ 5];

endmodule
