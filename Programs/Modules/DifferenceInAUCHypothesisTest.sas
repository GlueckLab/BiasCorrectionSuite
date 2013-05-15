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

Conduct a hypothesis test for the difference in AUC using the methods of Obuchowski and McClish, 
1997.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode				passed in value of error code variable
cumErrors			passed in value of cumulative errors variable
a1					binormal parameter a for Test 1
b1					binormal parameter b for Test 1
auc1				Test 1 AUC
a2					binormal parameter a for Test 2
b2					binormal parameter b for Test 2
auc2				Test 2 AUC
rhoCases			correlation between Test 1 and 2 scores for cases
rhoNonCases			correlation between Test 1 and 2 scores for non-cases
numberCases			number of cases
numberNonCases		number of non-cases

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = differenceInAUCHypothesisTest( 0, 0, 2, 2, .7, 2, 1.1, .73, .1, .1, 500, 1500 );

where,

errCode				= 0
cumErrors		    = 0
a1					= 2
b1					= 2
auc1				= .7
a2					= 2
b2					= 1.1
auc2				= .73
rhoCases			= .1
rhoNonCases			= .1
numberCases			= 500
numberNonCases		= 1500

------------------------------------------------------------------------------------------------*/

*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;

proc iml;

	*difference in AUC hypothesis test;
	*uses methods of Obuchowski and McClish, 1997;
	*uses equations 3, 4, 5, Table 1, and unlabeled equations that appears after the first 
     paragraph of section 2.; 
	start differenceInAUCHypothesisTest( errCode, cumErrors, a1, b1, auc1, a2, b2, auc2, rhoCases, 
                                         rhoNonCases, numberCases, numberNonCases );

		pi = 3.14159265;

		*equations from Table 1;
		f1 = exp( -a1**2 / 2 / ( 1 + b1**2 ) ) / sqrt( 2 * pi * ( 1 + b1**2 ) );
		f2 = exp( -a2**2 / 2 / ( 1 + b2**2 ) ) / sqrt( 2 * pi * ( 1 + b2**2 ) );
		g1 = -exp( -a1**2 / 2 / ( 1 + b1**2 ) ) * a1 * b1 / sqrt( 2 * pi * ( 1 + b1**2 )**3 );
		g2 = -exp( -a2**2 / 2 / ( 1 + b2**2 ) ) * a2 * b2 / sqrt( 2 * pi * ( 1 + b2**2 )**3 ) ;

		*R is defined in first paragraph beneath equation 5 in Section 2 of the paper;
		R = numberNonCases / numberCases;

		*equation 4;
		V1 = f1**2 * ( 1 + b1**2 / R + a1**2 / 2 ) 
		       + g1**2 * b1**2 * ( 1 + R ) / 2 / R;

		V2 = f2**2 * ( 1 + b2**2 / R + a2**2 / 2 ) 
		       + g2**2 * b2**2 * ( 1 + R ) / 2 / R;

		*equation 5;
		C12 = f1 * f2 * ( rhoCases + rhoNonCases * b1 * b2 / R + rhoCases**2 * a1 * a2 / 2 )
		      + g1 * g2 * b1 * b2 * ( rhoNonCases**2 + R * rhoCases**2 ) / 2 / R
			  + f1 * g2 * rhoCases**2 * a1 * b2 / 2 
			  + f2 * g1 * rhoCases**2 * a2 * b1 / 2;

		*equation 3;
		V = V1 + V2 - 2 * C12;

		*in the text, directly following equation 2;
		var = V / numberCases; 

		*unlabeled equation after the first paragraph of section 2; 
		se = sqrt( var );
		delta = auc1 - auc2;

		*note that we are doing a two-sided test so the probability of a Type I error is split 
		 into two areas: below -z or above z;
		z = abs( delta ) / se;
		p = 2 * ( 1 - probnorm( z ) );

		if p <= 0.05 then reject = 1;
			else reject = 0;

		return( delta || se || z || p || reject );

	finish;

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;

