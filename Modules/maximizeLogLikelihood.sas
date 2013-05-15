/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Maximize the log likelihood of the bivariate normal.

The user inputs required for the program are as follows:
n				number of observations
mu1				best estimate of variable 1 mean
mu2				best estimate of variable 2 mean
sig1			best estimate of variable 1 standard deviation
sig2			best estimate of variable 2 standard deviation
rho				best estimate of correlation between variable 1 and 2
mean1			variable 1 sample mean
mean2			variable 2 sample mean
std1			variable 1 sample standard deviation
std2			variable 2 sample standard deviation
corr			sample correlation between variable 1 and 2

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

proc iml;

	start maximizeLogLikelihood( errCode, cumErrors, n, mu1, mu2, sig1, sig2, rho, mean1, mean2, std1, std2, corr ); 

		*From Nath 1971;
		*simplified so I only have to use summary statistics instead of the data;
		*Note that the G term is missing, so this is the log likelihood for the full distribution;
		firstTermSum = ( n - 1 ) / sig1**2 * std1 + n / sig1**2 * ( mean1 - mu1 )**2;
		middleTermSum = ( n - 1 ) / sig1 / sig2 * corr * sqrt( std1 * std2 ) + n / sig1 / sig2 * ( mean1 - mu1 ) * ( mean2 - mu2 );
		lastTermSum = ( n - 1 ) / sig2**2 * std2 + n / sig2**2 * ( mean2 - mu2 )**2;

		sum = firstTermSum + middleTermSum + lastTermSum;

		logL = -n * log( sig1 ) - n * log( sig2 ) - .5 * n * log( 1 - rho**2 ) - .5 / ( 1 - rho**2 ) * sum;
	
		return( -n * log( sig1 ) - n * log( sig2 ) - .5 * n * log( 1 - rho**2 ) - .5 / ( 1 - rho**2 ) * sum );

	finish;

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;
