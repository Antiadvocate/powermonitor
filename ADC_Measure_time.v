// ============================================================================
// File function: Reset ADC module for exploiting the ADC converter
// ============================================================================
module ADC_Measure_time(
	input 			clock_in,
	output reg     adc_reset_n
	);
	
	//#1.6 us for each ADC data. So for 20ns clock(50MHz), 
	//#80 cycles are required for ADC data
	//#counter should be 7 bits 128
	//now 1.6us for one data; Sample rate 625K
	reg  [6:0] counter; //1.6 us for one ADC data 
	
	always @ (posedge clock_in) begin
		if (counter == 7'b0) begin
			adc_reset_n <= 1'b0;
		end
		else begin
			adc_reset_n <= 1'b1;
		end
	end
	
	always @ (posedge clock_in) begin
		counter <= counter + 1;
		if (counter >= 7'd80) begin
			counter <= 7'd0;
		end
		else begin
		end
	end
	
endmodule
