module DE1_SoC_ADC(

      ///////// ADC /////////
      output              ADC_CONVST,
      output             ADC_DIN,
      input              ADC_DOUT,
      output             ADC_SCLK,

     
      ///////// CLOCK2 /////////
      input              CLOCK2_50,

      ///////// CLOCK3 /////////
      input              CLOCK3_50,

      ///////// CLOCK4 /////////
      input              CLOCK4_50,
		input       [9:0]  SW,
      ///////// CLOCK /////////
      input              CLOCK_50,
		      ///////// GPIO /////////
      inout     [35:0]         GPIO_0,
      inout     [35:0]         GPIO_1,
 

      ///////// HEX0 /////////
      output      [6:0]  HEX0,

      ///////// HEX1 /////////
      output      [6:0]  HEX1,

      ///////// HEX2 /////////
      output      [6:0]  HEX2,

      ///////// HEX3 /////////
      output      [6:0]  HEX3,

      ///////// HEX4 /////////
      output      [6:0]  HEX4,

      ///////// HEX5 /////////
      output      [6:0]  HEX5
     
);


//===========================================================================================
//  Structural coding
//===========================================================================================

//-------------------------------------------------------------------------------------------
//  Part 1: ADC value measuing & display 
//-------------------------------------------------------------------------------------------

	//Variables for measuing 12-bit ADC Values
	wire ADC_clk;             //ADC clock: 40MHz
	wire wait_measure_done;   //ADC value ready flag

	//Reg/Wire declarations
	 
   reg conv;
    reg rdy;
    reg [3:0] count;
    //reg [11:0] ADCout;
    reg [11:0] tmp;
	wire [11:0] ADCout;  //Raw ADC value 12 bits
    //The clock counter. Starts at 0, so clock is from 0-15 instead of 1-16.
    always @ (posedge CLOCK_50)
        begin
            count <= count + 1;
        end
    
    //Assert the CONV signal
    always @ (negedge CLOCK_50)
        begin
            if ((count == 15))
                conv = 1'b0;
            else 
                conv = 1'b1;
        end                
    
    //Read the serial data into a 12-bit register. Afterwards, convert it to parallel if the count is 13 (end of data stream)
    always @ (negedge CLOCK_50)
        begin
            if (count == 14)
                tmp <= ADCout;
            case (count)
                1: ADCout[11] <= serial_data;
                2: ADCout[10] <= serial_data;
                3: ADCout[9] <= serial_data;
                4: ADCout[8] <= serial_data;
                5: ADCout[7] <= serial_data;
                6: ADCout[6] <= serial_data;
                7: ADCout[5] <= serial_data;
                8: ADCout[4] <= serial_data;
                9: ADCout[3] <= serial_data;
                10: ADCout[2] <= serial_data;
                11: ADCout[1] <= serial_data;
                12: ADCout[0] <= serial_data;
            endcase

        end
		  
	/* Reserved for Part 2
	wire [15:0] ADC_16_in;   //16 bits ADC data:input into SDRAM
	wire [15:0] ADC_16_out;  //16 bits ADC data:output from SDRAM
	wire [11:0] ADC_12_out;  //16 bits ADC data:output from SDRAM

	assign ADC_16_in = {4'b0,ADCout};
	assign ADC_12_out = ADC_16_out;
	*/

	wire adc_reset_n;     //reset control signals
	wire [3:0]  wH5,wH4,wH3,wH2,wH1,wH0 ;  //decimal values
	 
	 //1.1 12 bits ADC data converts to 6 digits voltage value
	 //The least two bits are reserved
	 Binary2Decimal transfer(  
		.wait_measure_done(wait_measure_done),
		.bindata(ADCout),
		.run_stop(SW[8]),
		
		.dig_5(wH5),
		.dig_4(wH4),
		.dig_3(wH3), 
		.dig_2(wH2), 
		.dig_1(wH1), 
		.dig_0(wH0)
	);
	
	//1.2 Restart ADC: reset the ADC convertor(LTC2308fb) for next value
	ADC_Measure_time ADC_con(
		.clock_in(CLOCK_50),         //ADC Clock:50MHz
		.adc_reset_n(adc_reset_n)
	);

	Seg7 s0(.num(wH0),.seg(HEX0),.rst(adc_reset_n));
	Seg7 s1(.num(wH1),.seg(HEX1),.rst(adc_reset_n));
	Seg7 s2(.num(wH2),.seg(HEX2),.rst(adc_reset_n));
	Seg7 s3(.num(wH3),.seg(HEX3),.rst(adc_reset_n));
	Seg7 s4(.num(wH4),.seg(HEX4),.rst(adc_reset_n));
	Seg7 s5(.num(wH5),.seg(HEX5),.rst(adc_reset_n));


	
	
	
	
	/* DE1_SoC_QSYS u_top (
        .clk_clk                        (CLOCK_50),    //Original Reference clock:50MHz    
        .reset_reset_n                  (1'b1),        //reset signal for whole system: KEY0  
		  .sw_ADC_pin_select  				 (SW[2:0]),

		  //-----------ADC module connection----------------------------------------------------
		  .ADCout                         (ADCout),
		  .adc_reset_n                    (adc_reset_n),
		  
		  //
		  .pll_sys_outclk1_clk            (ADC_clk),
		  .wait_measure_done              (wait_measure_done),
		  
		  .adc_ltc2308_conduit_end_CONVST (ADC_CONVST), // adc_ltc2308_conduit_end.CONVST
        .adc_ltc2308_conduit_end_SCK    (ADC_SCLK),   // .SCK
        .adc_ltc2308_conduit_end_SDI    (ADC_DIN),    // .SDI
        .adc_ltc2308_conduit_end_SDO    (ADC_DOUT),   // .SDO
		  //------------------------------------------------------------------------------------
		  
		  //-----------SDRAM -------------------------------------------------------------------
		  .pll_sys_outclk0_clk            (clk_100),    //100MHz clock for SDRAM
		  //------------------------------------------------------------------------------------
		  
		  //-------------VGA--------------------------------------------------------------------
		  .pll_sys_outclk2_clk            (clk_25)      //25MHz clock for VGA display
		  //------------------------------------------------------------------------------------
    );
 */
wire sink_ready;
wire source_valid;
wire        source_sop;   //       .source_sop
wire        source_eop;   //       .source_eop
wire [22:0] source_real;  //       .source_real
wire [22:0] source_imag;  //       .source_imag
wire [10:0] fftpts_out;   //       .fftpts_out
wire [1:0] source_error;
	 
	     fftipcore u0 (
        .clk          (CLOCK_50),          //    clk.clk
        .reset_n      (1'b1)),      //    rst.reset_n
        .sink_valid   (1'b1),   //   sink.sink_valid
        .sink_ready   (sink_ready),   //       .sink_ready
        .sink_error   (1'b1),   //       .sink_error
        .sink_sop     (1'b1),     //       .sink_sop
        .sink_eop     (1'b1),     //       .sink_eop
        .sink_real    (ADCout),    //       .sink_real
        .sink_imag    (ADCout),    //       .sink_imag
        .fftpts_in    (1024),    //       .fftpts_in
        .inverse      (0'b1),      //       .inverse
        .source_valid (source_valid), // source.source_valid
        .source_ready (1'b1), //       .source_ready
        .source_error (source_error), //       .source_error
        .source_sop   (source_sop),   //       .source_sop
        .source_eop   (source_eop),   //       .source_eop
        .source_real  (source_real),  //       .source_real
        .source_imag  (source_imag),  //       .source_imag
        .fftpts_out   (fftpts_out)    //       .fftpts_out
    );
	 
endmodule