/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	12/9/11

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

Calculate the corrected number of cases and non-cases based on estimated bivariate normal
probabilities.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode					passed in value of error code variable
cumErrors				passed in value of cumulative errors variable
f1						estimated bivariate normal probability of quadrants 1, 2, and 3
						(pairs of test scores where at least one test score is above a threshold)
sampSize				total sample size
numberScreenPosCases	number of cases that have at least one test score above its
						respective threshold

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = calcCorrectedNumCasesNonCases( 0, 0, .6, 50000, 500 );

where

errCode 				= 0
cumErrors 				= 0
f1 						= .6,
sampSize 				= 50000
numberScreenPosCases 	= 500

------------------------------------------------------------------------------------------------*/

*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;

proc iml;

	start calcCorrectedNumCasesNonCases( errCode, cumErrors, f1, sampSize, numberScreenPosCases );

		*calculate corrected total number of cases and non-cases;
		correctedNumberCases = numberScreenPosCases / f1;
		correctedNumberNonCases = sampSize - correctedNumberCases;

		return( correctedNumberCases || correctedNumberNonCases );

	finish; 

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;
