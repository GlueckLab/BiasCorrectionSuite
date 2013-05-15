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

This macro creates an output table for the BiasCorrectionTool.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The USER INPUTS required for the program are as follows:

lib 			dataset library
din				input dataset
title			title of the table

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

The input dataset should be the results dataset output from BiasCorrectionTool.

Example call:

%BiasCorrectionToolTable( lib = lib, 
                          din = in01, 
                          title = Table 1. Hypothesis Test for a Difference in AUC. );

------------------------------------------------------------------------------------------------*/

/*Assign libnames and options;*/

%include "IncludeLibrary.sas";

%IncludeLibrary;

/*begin macro definition*/
%macro BiasCorrectionToolTable( lib, din, title ) / store source;

	/*delete previous datasets*/
	proc datasets lib = &lib;

		delete BiasCorrectionToolTable;

	run;

	/*create a SAS dataset that contains all the variables needed for the table*/
	/*one row of the dataset holds results for the standard analysis*/
	/*the other row of the dataset holds results for the corrected analysis*/
	data &lib..BiasCorrectionToolTable;

		set &lib..&din ( keep = observedDeltaAUC observedSEDeltaAUC observedZDeltaAUC 
                                observedPDeltaAUC
		                 rename = ( observedDeltaAUC = deltaAUC observedSEDeltaAUC = SE
							        observedZDeltaAUC = Z observedPDeltaAUC = p )
						 in = standard )

			&lib..&din ( keep = correctedDeltaAUC correctedSEDeltaAUC correctedZDeltaAUC 
                                correctedPDeltaAUC
		                 rename = ( correctedDeltaAUC = deltaAUC correctedSEDeltaAUC = SE
							        correctedZDeltaAUC = Z correctedPDeltaAUC = p ) );

		if standard = 1 then analysis = "Standard ";

		else analysis = "Corrected";

	run;


	/*assign a pathname for the table*/
	ods rtf file = "&OUTPUT_FILE..doc";
		
	/*create report table*/;
	ods escapechar = "^";
	proc report data = &lib..BiasCorrectionToolTable nowd 

		style( report ) = { font_face = 'Times' font_size = 12pt frame = hsides rules = groups }
        style( header ) = { background = white };

		title '^S = { leftmargin = 1in font = ( "times",12pt ) just = left }'
			  "&title";

		column analysis  deltaAUC SE Z p;

		define analysis / width = 5 center order = data "Analysis" 
                          style( column ) = { cellwidth = 1.5in };	
		define deltaAUC / format = 5.2 "Difference in AUC^n(Test1 - Test2)" 
                          center style( column ) = [ just = d ] 
                          style( column ) = { cellwidth = 1.5in };
		define SE /       format = 10.2 "Standard Error" center 
                          style( column ) = [ just = d ]
                          style( column ) = { cellwidth = 1in };
		define Z /        format = 10.2 "Z" center style( column ) = [ just = d ] 
                          style( column ) = { cellwidth = 1in };
		define p /        format = 6.4 width = 5 "P-Value^{super 1}" center 
                          style( column ) = [ just = d ]
                          style( column ) = { cellwidth = 1 in };

		footnote '^S = { leftmargin = 1in font = ( "times", 12pt ) just = left } ^{super 1}'
				 "Z-test for a difference in AUC (Obuchowski and McClish, 1997.)"; 

	run;
	quit;

	ods rtf close;

%mend;
