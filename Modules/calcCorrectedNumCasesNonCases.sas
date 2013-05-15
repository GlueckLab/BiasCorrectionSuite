/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Calculate the corrected number of cases and non-cases based on estimated bivariate normal
probabilities.

The user inputs required for the program are as follows:
f1						estimated bivariate normal probability of quadrants 1, 2, and 3
						(pairs of test scores where at least one test score is above a threshold)
sampSize				total sample size
numberScreenPosCases	number of cases that have at least one test score above its
						respective threshold

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

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
