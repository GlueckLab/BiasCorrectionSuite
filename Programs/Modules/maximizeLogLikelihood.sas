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

Maximize the log likelihood of the bivariate normal.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode					passed in value of error code variable
cumErrors				passed in value of cumulative errors variable
n						number of observations
mu1						best estimate of variable 1 mean
mu2						best estimate of variable 2 mean
sig1					best estimate of variable 1 standard deviation
sig2					best estimate of variable 2 standard deviation
rho						best estimate of correlation between variable 1 and 2
mean1					variable 1 sample mean
mean2					variable 2 sample mean
std1					variable 1 sample standard deviation
std2					variable 2 sample standard deviation
corr					sample correlation between variable 1 and 2

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = maximizeLogLikelihood( 0, 0, 50000, 61.2, 61.1, 1, 1, .1, 66.5, 58.2, .89, .88, .13 );

where

errCode					= 0
cumErrors				= 0
n						= 50000 
mu1						= 61.2 
mu2						= 61.1 
sig1					= 1
sig2					= 1
rho						= .1
mean1					= 66.5
mean2					= 58.2
std1					= .89
std2					= .88
corr					= .13

------------------------------------------------------------------------------------------------*/

*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;

proc iml;

	start maximizeLogLikelihood( errCode, cumErrors, n, mu1, mu2, sig1, sig2, rho, mean1, mean2, 
                                 std1, std2, corr ); 

		*From Nath 1971;
		*simplified so I only have to use summary statistics instead of the data;
		*Note that the G term is missing, so this is the log likelihood for the full 
         distribution;
		firstTermSum = ( n - 1 ) / sig1**2 * std1 + n / sig1**2 * ( mean1 - mu1 )**2;
		middleTermSum = ( n - 1 ) / sig1 / sig2 * corr * sqrt( std1 * std2 ) + n / sig1 / sig2 * 
                        ( mean1 - mu1 ) * ( mean2 - mu2 );
		lastTermSum = ( n - 1 ) / sig2**2 * std2 + n / sig2**2 * ( mean2 - mu2 )**2;

		sum = firstTermSum + middleTermSum + lastTermSum;

		logL = -n * log( sig1 ) - n * log( sig2 ) - .5 * n * log( 1 - rho**2 ) - .5 / 
               ( 1 - rho**2 ) * sum;
	
		return( -n * log( sig1 ) - n * log( sig2 ) - .5 * n * log( 1 - rho**2 ) - .5 / 
                ( 1 - rho**2 ) * sum );

	finish;

	*set storage library;
	reset storage = mlib.IMLModules;

	*store module;
	store;

quit;
