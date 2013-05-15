*Example DecisionErrorSimulator;

%include "CommonMain.sas";
%include "../Macros/CommonMain.sas";

%CommonMain( FindDistrDmin\SampleDistrDmin1, SampleDistrDmin1 ); 

*Begin Decision Error Simulator Module;
*DecisionErrorSimulator( argument1, argument2,...);

	*Tell the program where to store output for doing the three analyses under the alternative;
	%CommonMain( BiasCorrectionTuneUp, DecisionErrorAlt, DecisionErrorExampleAlt ); 

	*Save the log as a file;
	proc printto log = "&OUTPUT_FILE..log";
	run;

	*generate data and do the three analyses using different parameter values for screeing Test 1 and 2;
	%IMLBiasCorrection( 1066, -99999, 10000, 50000, .000001, 500, 61.1, 62.5, 
	                    1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1, diseasePrevalence, 
	                    vector = ( { .01 } ) );

	*Stop sending the log to a file;
	proc printto;
	run;

	*Now tell the program where to store output for doing the three analyses under the null;
	*We can alter the existing programs so that the alternative and null output can be save in the same folder;
	*For now, they have to be saved in separate folders because the output datasets have the same name;
	%CommonMain( BiasCorrectionTuneUp, DecisionErrorNull, DecisionErrorExampleNull ); 

	*Save the log as a file;
	proc printto log = "&OUTPUT_FILE..log";
	run;

	*now generate data and do the three analyses with the same parameter values for both screening tests;
	%IMLBiasCorrection( 1066, -99999, 10000, 50000, .000001, 500, 61.1, 61.1, 
	                    1, 1, .1, 60, 60, 1, 1, .1, .01, { 65 59 }, .1, diseasePrevalence, 
	                    vector = ( { .01 } ) );

	*Stop sending the log to a file;
	proc printto;
	run;

*End Decision Error Simulator Module;
*finish DecisionErrorSimulator();


