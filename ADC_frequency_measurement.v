// ============================================================================
// File function: Freuency Calculation 
// ============================================================================
module ADC_frequency_measurement(
	input 			  ADC_clk,           //ADC clock: 40MHz
	input            rst,               //reset signal
	input            DC_or_AC,          //Input signal selection AC/DC
	input            wait_measure_done, //
	input  [11:0]    ADC_source_data,   //Raw ADC value 
	input  [9:0]     trigger_voltage,   //Trigger value as reference
	input            run_stop,          //Run/stop control signal
	
	//calculating results
	output reg  [2:0] unit,
	
	output reg 	[3:0] freq_dig_5,  //5-the hightest bit
	output reg 	[3:0] freq_dig_4, 
	output reg 	[3:0] freq_dig_3, 
	output reg 	[3:0] freq_dig_2, 
	output reg 	[3:0] freq_dig_1,
	output reg 	[3:0] freq_dig_0   //the least bit 
	);
	//Variables for referred voltage for frequency calculation
	reg  [11:0] trigger_voltage_12_temp;
	reg  [11:0] trigger_voltage_12_high;
	reg  [11:0] trigger_voltage_12_low;
	// ADC value memory
	reg  [11:0] ADCmem;
	// counters for calculation
	reg   [3:0] counter_freq;
	reg   [3:0] counter_freq_comparison;
	reg   [3:0] counter_freq_index;
	reg   [3:0] counter_freq_index_temp;
	reg         freq_comparison_finish_flag;
	
	reg  ADCdata_ready_flag;
	reg  Measure_result_ready_flag;
	
	reg  [63:0] Measure_counter;      //???why 64 bits???
	reg  [63:0] Measure_freq_temp;
	reg  [63:0] Measure_result_freq;
	
	reg  [63:0] Measure_result_count;
	reg  [63:0] clk_value;
	reg  [3:0] state;
	
	reg  mem_start_flag;
	reg  Measure_counter_start_flag;
	
	reg delay_finish_flag;
	
	// Variables for updating referred Trigger values
	reg [3:0] trigger_counter;
	reg trigger_finish_flag;
	// Trigger value calculation - Trigger value x 10
	// Since Trigger: 0 ~ 410; ADC value: 0~4096
	always @ (posedge ADC_clk) begin
		if(!rst) begin
			trigger_voltage_12_temp <= 12'b0;
			trigger_counter <= 4'b0;
			trigger_finish_flag <= 1'b0;
		end
		else begin
			if (trigger_counter < 4'd10) begin
				trigger_counter <= trigger_counter + 4'b0001;
				trigger_voltage_12_temp <= trigger_voltage_12_temp + trigger_voltage;
				trigger_finish_flag <= 1'b0;
			end
			else if (trigger_counter < 4'd15) begin
				trigger_counter <= trigger_counter + 4'b0001;
				trigger_finish_flag <= 1'b1;
			end
			else begin
				trigger_voltage_12_temp <= 12'b0;
				trigger_finish_flag <= 1'b0;
				trigger_counter <= 4'b0;
			end
		end
	end

	//Storing ADC value in memory
	always @ (posedge ADC_clk) begin
		if(!rst) begin
			ADCdata_ready_flag <= 1'b0;
		end
		else begin
			if ((~wait_measure_done)&&(mem_start_flag)) begin
				ADCmem <= ADC_source_data;
				ADCdata_ready_flag <= 1'b1;
			end
			else begin
				ADCdata_ready_flag <= 1'b0;
			end
		end
	end
	
	//Main Counter for measurement
	always @ (posedge ADC_clk) begin
		if (!rst) begin
			Measure_counter <= 64'b0;
		end
		else begin
			if (Measure_counter_start_flag) begin
				Measure_counter <= Measure_counter +1;
			end
			else begin
				Measure_counter <= 64'b0;
			end
		end
	
	end

	//State machine for frequency calculation
	always @ (posedge ADC_clk) begin
		if (!rst) begin
			state <= 4'b0;
			mem_start_flag <= 1'b0;
			Measure_counter_start_flag <= 1'b0;
			Measure_result_count <= 64'b0;
			Measure_result_ready_flag <= 1'b0;
			
			trigger_voltage_12_high <= 12'b0;
			trigger_voltage_12_low <= 12'b0;	
		end
		else begin
			case(state)
				4'd0 : begin
							if (DC_or_AC) begin
								state <= 4'd1;
							end
							else begin
								state <= 4'd0;
							end
						 end
				4'd1 : begin   //updating trigger voltage
							if (trigger_finish_flag) begin
								trigger_voltage_12_high <= trigger_voltage_12_temp + 12'd10;
								trigger_voltage_12_low  <= trigger_voltage_12_temp - 12'd10;
								state <= 4'd2;
							end
							else begin
								state <= 4'd1;
							end
						 end
				4'd2 : begin
                       //Start storing data into memory
							state <= 4'd3;              
							mem_start_flag <= 1'b1;
					    end
				4'd3 : begin     //Wait for one ADC data Stored in memory
							if (ADCdata_ready_flag) begin
								state <= 4'd4;
							end
							else begin
								state <= 4'd3;
							end
						 end
				4'd4 : begin
							 if (ADCmem > trigger_voltage_12_high) begin
								 state <= 4'd5;
							 end
							 else begin
								 state <= 4'd8;
							 end
						 end
				4'd5 : begin
							 if (ADCmem < trigger_voltage_12_low) begin
								 Measure_counter_start_flag <= 1'b1;
								 state <= 4'd6;
							 end
							 else begin
								 state <= 4'd5;
							 end
						 end
				4'd6 : begin
							 if (ADCmem > trigger_voltage_12_high) begin
								 state <= 4'd7;	
							 end
							 else begin
								 state <= 4'd6;
							 end
						 end
				4'd7 : begin
							if (ADCmem < trigger_voltage_12_low) begin
								mem_start_flag <= 1'b0;
								Measure_counter_start_flag <= 1'b0;
								Measure_result_count <= Measure_counter;
								state <= 4'd11;
							end
							else begin
								state <= 4'd7;
							end
						 end
				4'd8 : begin
							 if (ADCmem > trigger_voltage_12_high) begin
								 Measure_counter_start_flag <= 1'b1;
								 state <= 4'd9;
							 end
							 else begin
								 state <= 4'd8;
							 end
						 end
				4'd9 : begin
							 if (ADCmem < trigger_voltage_12_low) begin
								 state <= 4'd10;	
							 end
							 else begin
								 state <= 4'd9;
							 end
						 end
				4'd10: begin
							if (ADCmem > trigger_voltage_12_high) begin
								mem_start_flag <= 1'b0;
								Measure_counter_start_flag <= 1'b0;
								Measure_result_count <= Measure_counter;
								state <= 4'd11;
							end
							else begin
								state <= 4'd10;
							end
						 end
				4'd11: begin
							 if (!run_stop) begin
								Measure_result_ready_flag <= 1'b1;
								state <= 4'd12;
							 end
							 else begin
								state <= 4'd0;
							 end
						 end
				4'd12: begin
							 if(delay_finish_flag) begin
								 state <= 4'd0;
								 Measure_result_ready_flag <= 1'b0;
							 end
							 else begin
								 state <= 4'd12;
							 end
				       end
				default : state <= 4'd0;
			endcase
		end
	end
	
	//delay for waiting the dividor
	// The result is 1000 times of the accurate value for displaying three digits after the decimal point
	always @ (posedge ADC_clk) begin   //1000 times frequency
		if (!rst) begin
			Measure_freq_temp <= 64'b0;
			delay_finish_flag <= 1'b0;
			clk_value <= 64'd40000000000;
			counter_freq <= 4'b0;
		end
		else begin
			if(Measure_result_ready_flag) begin
				clk_value <= clk_value - Measure_result_count;  //Dividor built by subtractor
				if (clk_value >= Measure_result_count) begin
					Measure_freq_temp <= Measure_freq_temp + 1;
				end
				else begin
					Measure_result_freq <= Measure_freq_temp;
					delay_finish_flag <= 1'b1;
					counter_freq <= counter_freq + 4'b0001;
				end		
			end
			else begin
				clk_value <= 64'd40000000000;
				Measure_freq_temp <=64'b0;
				delay_finish_flag <= 1'b0;
			end
		end
	end

	//Count digits of the final result
	always @ * begin
		if 	  (Measure_result_freq < 64'd10000) 			unit = 3'd0;	
		else if (Measure_result_freq < 64'd100000) 			unit = 3'd1;
		else if (Measure_result_freq < 64'd1000000) 			unit = 3'd2;
		else if (Measure_result_freq < 64'd10000000) 		unit = 3'd3;
		else if (Measure_result_freq < 64'd100000000) 		unit = 3'd4;
		else if (Measure_result_freq < 64'd1000000000) 		unit = 3'd5;
		else 																unit = 3'd6;
	end
	//Transfer Binary result to Decimal values
	always @ * begin
		if (Measure_result_freq < 64'd1000000) begin        //Result with Hz
			freq_dig_0 =  Measure_result_freq % 10;
			freq_dig_1 = (Measure_result_freq/10) % 10;
			freq_dig_2 = (Measure_result_freq/100) % 10;
			freq_dig_3 = (Measure_result_freq/1000) % 10;
			freq_dig_4 = (Measure_result_freq/10000) % 10;
			freq_dig_5 = (Measure_result_freq/100000) % 10;
		end
		else begin                                          //Result with KHz
			freq_dig_0 = (Measure_result_freq/1000) % 10;
			freq_dig_1 = (Measure_result_freq/10000) % 10;
			freq_dig_2 = (Measure_result_freq/100000) % 10;
			freq_dig_3 = (Measure_result_freq/1000000) % 10;
			freq_dig_4 = (Measure_result_freq/10000000) % 10;
			freq_dig_5 = (Measure_result_freq/100000000) % 10;
		end
	end
endmodule
