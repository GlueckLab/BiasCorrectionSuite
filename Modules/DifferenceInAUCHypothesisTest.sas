/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Conduct a hypothesis test for the difference in AUC using the methods of Obuchowski and
McClish, 1997.

The user inputs required for the program are as follows:
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

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

proc iml;

	*difference in AUC hypothesis test;
	*uses methods of Obuchowski and McClish, 1997;
	*uses equations 3, 4, 5, Table 1, and unlabeled equations that appears after the first paragraph of section 2.; 
	start differenceInAUCHypothesisTest( errCode, cumErrors, a1, b1, auc1, a2, b2, auc2, rhoCases, rhoNonCases, numberCases, numberNonCases );

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
		*note that we are doing a two-sided test so the probability of a Type I error is split into two areas:;
		*below -z or above z;
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

