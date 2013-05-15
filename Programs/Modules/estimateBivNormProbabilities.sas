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

Estimate bivariate normal probabilties from estimated mean, variance, and correlation.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode			passed in value of error code variable
cumErrors		passed in value of cumulative errors variable
co1				cutoff for variable 1
co2				cutoff for variable 2
mu1				best estimate of variable 1 mean
mu2				best estimate of variable 2 mean
sig1			best estimate of variable 1 standard deviation
sig2			best estimate of variable 2 standard deviation
rho				best estimate of correlation between variable 1 and 2
errorCode		error code

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = estimateBivNormProbabilities( 0, 0, 65, 58, 61.2, 61.1, 1, 1, .1, -99999 );

where

errCode 				= 0
cumErrors 				= 0
co1						= 65
co2 					= 58
mu1 					= 61.2
mu2 					= 61.1
sig1 					= 1
sig2 					= 1
rho 					= .1 
errorCode 				= -99999

------------------------------------------------------------------------------------------------*/

*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;



proc iml;

	start estimateBivNormProbabilities( errCode, cumErrors, co1, co2, mu1, mu2, sig1, sig2, rho, 
                                        errorCode );

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
