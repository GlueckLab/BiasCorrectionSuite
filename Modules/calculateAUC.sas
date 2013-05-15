/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Calculate the AUC assuming it is distributed binormal.  Uses the method described in Zhou, 
pgs. 122, 139.

The user inputs required for the program are as follows:
muCases				mean for cases
muNonCases			mean for non-cases
sigCases			standard deviation for cases
sigNonCases			standard deviation for non-cases

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

proc iml;

	*calculate AUC;
	start calculateAUC( errCode, cumErrors, muCases, muNonCases, sigCases, sigNonCases );
		*From Zhou pg. 139:;
		*a = ( muc - mun ) / sigc;
		*b = ( sign / sigc );

		*From Zhou pg. 122:; 
		*area = phi( a / ( sqrt( 1 + b**2 ) ) );
		a = ( muCases - muNonCases ) / sigCases;
		b = ( sigNonCases / sigCases );
		auc = probnorm( a / ( sqrt( 1 + b**2 ) ) );

		return( a || b || auc );

	finish;

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;
