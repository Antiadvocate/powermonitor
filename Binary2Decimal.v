// ============================================================================
// File function: Transfer Binary value to Decimal value - DC value display
// ============================================================================
module Binary2Decimal(         
	input             wait_measure_done,
	input 		[11:0]bindata,           //12-bit ADC values
	input             run_stop,          //Run/Stop signal
	// output decimal digits
	output reg 	[3:0] dig_5,
	output reg 	[3:0] dig_4, 
	output reg 	[3:0] dig_3, 
	output reg 	[3:0] dig_2, 
	output reg 	[3:0] dig_1,
	output reg 	[3:0] dig_0
);

always@ * begin
	
    if (run_stop)begin  //Stop the transmission and keep it
	 end
    else begin
		//0~4096 scale to 0~4.096V
		dig_0 =  bindata*409600/4096 %10;
      dig_1 = ( bindata*409600/4096 / 10 ) % 10;
      dig_2 = ( bindata*409600/4096 / 100 ) % 10;
      dig_3 = ( bindata*409600/4096 / 1000 ) % 10;
      dig_4 = ( bindata*409600/4096 / 10000 ) % 10;
		dig_5 = ( bindata*409600/4096 / 100000 ) % 10;
	end
end

endmodule