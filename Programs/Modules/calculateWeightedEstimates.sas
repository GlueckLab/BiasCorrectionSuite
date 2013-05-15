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

Calculate weighted estimates of the parameters of the bivariate normal using estimates of
the bivariate normal probabilities of each quadrant.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode					passed in value of error code variable
cumErrors				passed in value of cumulative errors variable
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

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = calculateWeightedEstimates( 0, 0, .4, .6, 61.2, 61.1, 1, 1, .1, 60, 59, 1, 1, .1 );

where

errCode					= 0
cumErrors				= 0
f1						= .4
f2						= .6
mean1ScreenPosCases		= 61.2
mean2ScreenPosCases		= 61.1
std1ScreenPosCases		= 1
std2ScreenPosCases		= 1
corrScreenPosCases		= .1
mean1IntervalCases		= 60
mean2IntervalCases		= 59
std1IntervalCases		= 1
std2IntervalCases		= 1
corrIntervalCases		= .1

------------------------------------------------------------------------------------------------*/

/*assigns pathnames and storage library;*/
%include "IncludeLibrary.sas";

%IncludeLibrary;

proc iml;

	start calculateWeightedEstimates( errCode, cumErrors, f1, f2, 
									  mean1ScreenPosCases, mean2ScreenPosCases, 
									  std1ScreenPosCases, std2ScreenPosCases, 
									  corrScreenPosCases, 
									  mean1IntervalCases, mean2IntervalCases, 
									  std1IntervalCases, std2IntervalCases, 
									  corrIntervalCases );

		/*calculate combined estimates using nath estimates;*/
		/*calculate sample covariance for each area using observed data;*/
		covScreenPosCases = std1ScreenPosCases * std2ScreenPosCases * corrScreenPosCases;
		covIntervalCases = std1IntervalCases * std2IntervalCases * corrIntervalCases;

		/*mean estimator derived in paper14 using nath inputs;*/
	    weightedMeanT1 = f1 * mean1ScreenPosCases +
			             f2 * mean1IntervalCases;

	    weightedMeanT2 = f1 * mean2ScreenPosCases +
			             f2 * mean2IntervalCases;

		/*variance estimator derived in paper14 using nath inputs;*/
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


		/*find standard deviation of full distribution from variance;*/
		weightedStdT1 = sqrt( weightedVarT1 );
		weightedStdT2 = sqrt( weightedVarT2 );

		/*covariance estimator derived in paper14 using nath inputs;*/
		weightedCov =  mean1ScreenPosCases * mean2ScreenPosCases * f1 + 
	                   mean1IntervalCases * mean2IntervalCases * f2 -

				     ( mean1ScreenPosCases * f1 +
	                   mean1IntervalCases * f2 ) *
				     ( mean2ScreenPosCases * f1 +
	                   mean2IntervalCases * f2 ) +

			           covScreenPosCases * f1 +
	                   covIntervalCases * f2;

		/*find correlation of full distribution from covariance estimator;*/
		weightedCorr = weightedCov / weightedStdT1 / weightedStdT2;

		return( weightedMeanT1 || weightedMeanT2 || weightedStdT1 || weightedStdT2 || weightedCorr );

	finish;

	/*set storage library;*/
	reset storage = mlib.IMLModules;

	/*store module;*/
	store;

quit;
