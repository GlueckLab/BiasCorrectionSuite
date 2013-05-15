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

Calculate the AUC assuming test scores are bivariate Gaussian.  Uses the method described in 
Zhou, pgs. 122, 139.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode				passed in value of error code variable
cumErrors			passed in value of cumulative errors variable
muCases				mean for cases
muNonCases			mean for non-cases
sigCases			standard deviation for cases
sigNonCases			standard deviation for non-cases

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

x = calculateAUC( errCode, cumErrors, 61.1, 60, 1, 1 );

where

errCode					= 0
cumErrors				= 0
muCases					= 61.1
muNonCases				= 60
sigCases				= 1
sigNonCases				= 1

------------------------------------------------------------------------------------------------*/

*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;

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
