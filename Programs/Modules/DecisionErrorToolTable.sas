/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal
Creation Date:	2/4/13

Copyright (C) 2010 Regents of the University of Colorado.

This program is free software; you can redistribute it and/or modify it under the terms of the 
GNU General Public License as published by the Free Software Foundation; either version 2 of the 
License, or (at your option) any later version. This program is distributed in the hope that it 
will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You 
should have received a copy of the GNU General Public License along with this program; if not, 
write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
02110-1301, USA.
 
------------------------------------------------------------------------------------------------
									   DESCRIPTION
------------------------------------------------------------------------------------------------

This macro creates an output table for the DecisionErrorTool.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

lib 			dataset library
din				input dataset
title			title of the table
errorCode		value used to denote an error in the results datasets from the DecisionErrorTool

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

The input dataset should be the results dataset output from DecisionErrorTool.

Example call:

%DecisionErrorToolTable( lib = out01, 
                         din = results, 
                         title = Table 1. Simulated Decision Metrics.,
                         errorcode = -99999 );

------------------------------------------------------------------------------------------------*/

/*Assign libnames and options;*/
%include "IncludeLibrary.sas";

%IncludeLibrary;

/*begin macro definition*/
%macro DecisionErrorToolTable( lib, din, title, errorCode )/ store source ;

	/*delete previous datasets*/
	proc datasets lib = work;

		delete DirectionCompNull DirectionObsNull DirectionCorrNull
		       DirectionCompAlt DirectionObsAlt DirectionCorrAlt
			   true obs corr table;

	run;

	proc datasets lib = &lib;

		delete DecisionErrorSimulatorTable;

	run;

	/*calculate type I error rate for each analysis*/
	/*since the null is true, each of these frequency tables should have only 1's and 0's*/
	/*indicating either reject or fail to reject*/
	/*do not include realizations where bias correction failed*/
	/*those will be output as a separate table*/

	/*complete analysis when the null is true*/
	proc freq data = &lib..&din noprint;
		
		where alt_directionCompleteHypTest ^= &errorCode;
		tables null_directionCompleteHypTest / out = DirectionCompNull;

	run;

	/*observed analysis when the null is true*/
	proc freq data = &lib..&din noprint;

		where alt_directionObservedHypTest ^= &errorCode;
		tables null_directionObservedHypTest / out = DirectionObsNull;

	run;

	/*corrected analysis when the null is true*/
	proc freq data = &lib..&din noprint;

		where alt_directionCorrectedHypTest ^= &errorCode;
		tables null_directionCorrectedHypTest / out = DirectionCorrNull;

	run;

	/*calculate frequency of rejection in correct direction and in reverse direction*/
	/*when the alternative is true*/
	/*these frequency tables will have either a 1, 0, or -1 depending on whether the*/
	/*hypothesis test rejected in the correct direction, failed to reject, or 
	  rejected in the wrong direction, respectively*/
	/*do not include realizations where bias correction failed*/
	/*those will be output as a separate table*/

	/*complete analysis when the alternative is true*/
	proc freq data = &lib..&din noprint;

		where alt_directionCompleteHypTest ^= &errorCode;
		tables alt_directionCompleteHypTest / out = DirectionCompAlt;

	run;

	/*observed analysis when the alternative is true*/
	proc freq data = &lib..&din noprint;

		where alt_directionObservedHypTest ^= &errorCode;
		tables alt_directionObservedHypTest / out = DirectionObsAlt;

	run;

	/*corrected analysis when the alternative is true*/
	proc freq data = &lib..&din noprint;

		where alt_directionCorrectedHypTest ^= &errorCode;
		tables alt_directionCorrectedHypTest / out = DirectionCorrAlt;

	run;

	/*calculate the t1 error, correct rejection fraction, and wrong rejection 
	  fraction for the complete analysis*/
	data true;

		set directionCompNull ( in = t1 
                                rename = ( null_directionCompleteHypTest = direction )
                                where = ( direction = 1 ) 
                                keep = null_directionCompleteHypTest percent )
			directionCompAlt  ( in = crf 
                                rename = ( alt_directionCompleteHypTest = direction )
                                where = ( direction = 1 ) 
                                keep = alt_directionCompleteHypTest percent )
			directionCompAlt  ( in = wrf 
                                rename = ( alt_directionCompleteHypTest = direction )
                                where = ( direction = -1 ) 
                                keep = alt_directionCompleteHypTest percent );

		propTrue = percent / 100;

		decisionError = "Unassigned                ";

		if t1 = 1 then do;

			decisionError = "Type I Error^{super 1}";
			order = 1;

		end;

		if crf = 1 then do;

			decisionError = "Correct Rejection Fraction";
			order = 2;

		end;
			
		if wrf = 1 then do;

			decisionError = "Wrong Rejection Fraction";
			order = 3;

		end;

	run;

	/*calculate the t1 error, correct rejection fraction, and wrong rejection 
	  fraction for the observed analysis*/
	data obs;

		set directionObsNull ( in = t1 
							   rename = ( null_directionObservedHypTest = direction )
                               where = ( direction = 1 ) 
                               keep = null_directionObservedHypTest percent )
			directionObsAlt  ( in = crf 
                               rename = ( alt_directionObservedHypTest = direction )
                               where = ( direction = 1 ) 
                               keep = alt_directionObservedHypTest percent )
			directionObsAlt  ( in = wrf rename = ( alt_directionObservedHypTest = direction )
                               where = ( direction = -1 ) 
                               keep = alt_directionObservedHypTest percent );

		propObs = percent / 100;

		decisionError = "Unassigned                ";

		if t1 = 1 then do;

			decisionError = "Type I Error^{super 1}";
			order = 1;

		end;

		if crf = 1 then do;

			decisionError = "Correct Rejection Fraction";
			order = 2;

		end;
			
		if wrf = 1 then do;

			decisionError = "Wrong Rejection Fraction";
			order = 3;

		end;

	run;

	/*calculate the t1 error, correct rejection fraction, and wrong rejection 
	  fraction for the corrected analysis*/
	data corr;

		set directionCorrNull ( in = t1 
                                rename = ( null_directionCorrectedHypTest = direction )
                                where = ( direction = 1 ) 
                                keep = null_directionCorrectedHypTest percent )
			directionCorrAlt  ( in = crf 
                                rename = ( alt_directionCorrectedHypTest = direction )
                                where = ( direction = 1 ) 
                                keep = alt_directionCorrectedHypTest percent )
			directionCorrAlt  ( in = wrf 
                                rename = ( alt_directionCorrectedHypTest = direction )
                                where = ( direction = -1 ) 
                                keep = alt_directionCorrectedHypTest percent );

		propCorr = percent / 100;

		decisionError = "Unassigned                ";

		if t1 = 1 then do;

			decisionError = "Type I Error^{super 1}";
			order = 1;

		end;

		if crf = 1 then do;

			decisionError = "Correct Rejection Fraction";
			order = 2;

		end;
			
		if wrf = 1 then do;

			decisionError = "Wrong Rejection Fraction";
			order = 3;

		end;

	run;

	/*sort datasets for merging*/
	proc sort data = true;
			
		by decisionError;

	run;

	proc sort data = obs;

		by decisionError;

	run;

	proc sort data = corr;

		by decisionError;

	run;

	/*merge datasets*/
	/*create order variable so the observations can be properly ordered 
	  when we make the report*/
	data table;

		merge true obs corr;
		by decisionError;

		keep order decisionError propTrue propObs propCorr;

	run;

	/*save the table as a permanent SAS dataset, excluding the order variable*/
	data &lib..DecisionErrorSimulatorTable;

		set table;

		drop order;

		if propTrue = . then propTrue = 0;
		if propObs = . then propObs = 0;
		if propCorr = . then propCorr = 0;

	run;

	/*sort the table into the proper order (t1 error first, crf second, 
	  wrf third*/
	proc sort data = table;

		by order;

	run;
	
	/*missing values become zeros*/
	options missing = 0;

	/*assign a pathname for the report table*/
	ods rtf file = "&OUTPUT_FILE..doc";
		
	/*create report table*/;
	ods escapechar = "^";
	proc report data = table nowd 

    	style( report ) = { font_face = 'Times' font_size = 12pt frame = hsides 
                            rules = groups }
	    style( header ) = { background = white };
	
		title '^S = { leftmargin = 1in font = ( "times", 12pt ) just = left }'
			  "&title";
	
		column decisionError propTrue propObs propCorr;
	
		define decisionError /	right order = data "Decision Metric" 
	                      		style( column ) = { cellwidth = 2.5in };	
		define propTrue / 		format = 5.2 "True" 
	                       		center style( column ) = [ just = d ] 
                                style( column ) = { cellwidth = 1in };
		define propObs /   		format = 5.2 "Standard" center 
                                style( column ) = [ just = d ]
	                      		style( column ) = { cellwidth = 1in };
		define propCorr /  		format = 5.2 "Corrected" center 
                                style( column ) = [ just = d ] 
                                style( column ) = { cellwidth = 1in };

		footnote '^S = { leftmargin = 1in font = ( "times", 12pt ) just = left }'
			     "^{super 1}Screening Test 1 parameter values are used for both screening tests.";
		
	run;
	quit;
	
	ods rtf close;

%mend;
