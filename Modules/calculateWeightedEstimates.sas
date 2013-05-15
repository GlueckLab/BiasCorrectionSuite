/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/9/11
 
Description:
Calculate weighted estimates of the parameters of the bivariate normal using estimates of
the bivariate normal probabilities of each quadrant.

The user inputs required for the program are as follows:
f1						estimated bivariate normal probability of quadrants 1, 2, and 3
						(screen positive cases, or cases with pairs of test scores where 
						at least one test score is above a threshold)
f2						estimated bivariate normal probability of quadrant 4 (interval
						cases, or cases with both test scores below a threshold)
mean1ScreenPosCases		sample mean of screen positive cases for variable 1
mean2ScreenPosCases		sample mean of screen positive cases for variable 2
std1ScreenPosCases		sample standard deviation of screen positive cases for variable 1
std2ScreenPosCases		sample standard deviation of screen positive cases for variable 2
corrScreenPosCases		sample correlation of screen positive cases
mean1IntervalCases		sample mean of interval cases for variable 1
mean2IntervalCases		sample mean of interval cases for variable 2
std1IntervalCases		sample standard deviation of interval cases for variable 1
std2IntervalCases		sample standard deviation of interval cases for variable 2
corrIntervalCases		sample correlation of interval cases

********************************************************************************************/

/**assigns pathnames and storage library;*/
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

proc iml;

	start calculateWeightedEstimates( f1, f2, 
									  mean1ScreenPosCases, mean2ScreenPosCases, 
									  std1ScreenPosCases, std2ScreenPosCases, 
									  corrScreenPosCases, 
									  mean1IntervalCases, mean2IntervalCases, 
									  std1IntervalCases, std2IntervalCases, 
									  corrIntervalCases );

/*		*calculate combined estimates using nath estimates;*/
/*		*calculate sample covariance for each area using observed data;*/
		covScreenPosCases = std1ScreenPosCases * std2ScreenPosCases * corrScreenPosCases;
		covIntervalCases = std1IntervalCases * std2IntervalCases * corrIntervalCases;

/*		*mean estimator derived in paper14 using nath inputs;*/
	    weightedMeanT1 = f1 * mean1ScreenPosCases +
			             f2 * mean1IntervalCases;

	    weightedMeanT2 = f1 * mean2ScreenPosCases +
			             f2 * mean2IntervalCases;

/*		*variance estimator derived in paper14 using nath inputs;*/
		weightedVarT1 = mean1ScreenPosCases ** 2 * f1 + 
	                    mean1IntervalCases ** 2 * f2 -

				      ( mean1ScreenPosCases * f1 +
	                    mean1IntervalCases * f2 ) ** 2 +

			            std1ScreenPosCases ** 2 * f1 +
	                    std1IntervalCases ** 2 * f2;

		weightedVarT2 = mean2ScreenPosCases ** 2 * f1 + 
	                    mean2IntervalCases ** 2 * f2 -

				      ( mean2ScreenPosCases * f1 +
	                    mean2IntervalCases * f2 ) ** 2 +

			            std2ScreenPosCases ** 2 * f1 +
	                    std2IntervalCases ** 2 * f2;


/*		*find standard deviation of full distribution from variance;*/
		weightedStdT1 = sqrt( weightedVarT1 );
		weightedStdT2 = sqrt( weightedVarT2 );

/*		*covariance estimator derived in paper14 using nath inputs;*/
		weightedCov =  mean1ScreenPosCases * mean2ScreenPosCases * f1 + 
	                   mean1IntervalCases * mean2IntervalCases * f2 -

				     ( mean1ScreenPosCases * f1 +
	                   mean1IntervalCases * f2 ) *
				     ( mean2ScreenPosCases * f1 +
	                   mean2IntervalCases * f2 ) +

			           covScreenPosCases * f1 +
	                   covIntervalCases * f2;

/*		*find correlation of full distribution from covariance estimator;*/
		weightedCorr = weightedCov / weightedStdT1 / weightedStdT2;

		return( weightedMeanT1 || weightedMeanT2 || weightedStdT1 || weightedStdT2 || weightedCorr );

	finish;

/*	*set storage library;*/
	reset storage = mlib.IMLModules;

/*	*store module;*/
	store;

quit;
