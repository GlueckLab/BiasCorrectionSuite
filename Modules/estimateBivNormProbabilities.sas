/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Estimate bivariate normal probabilties from estimated mean, variance, and correlation.

The user inputs required for the program are as follows:
co1				cutoff for variable 1
co2				cutoff for variable 2
mu1				best estimate of variable 1 mean
mu2				best estimate of variable 2 mean
sig1			best estimate of variable 1 standard deviation
sig2			best estimate of variable 2 standard deviation
rho				best estimate of correlation between variable 1 and 2

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

proc iml;

	start estimateBivNormProbabilities( errCode, cumErrors, co1, co2, mu1, mu2, sig1, sig2, rho, errorCode );

		f1 = errorCode;
		f2 = errorCode;

		*probability of being observed by quadrant using bivariate probabilities;
		*use nath estimates of the mean, variance, correlation;
		*first form normalized inputs to probabilities;
		norm1 = ( co1 - mu1 ) / sig1;
		norm2 = ( co2 - mu2 ) / sig2;

		f2 = probbnrm( norm1, norm2, rho );
		f1 = 1 - f2;

		return( f1 || f2 );

	finish;

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;
