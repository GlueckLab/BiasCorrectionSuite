/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	1/31/13

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

Macro that adds a prefix to some or all variables in a dataset. Copied from 

http://technico.qnownow.com/sas-macro-to-add-a-prefix-to-some-or-all-variables-in-a-data-set/

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

din				input dataset name, format: libName.datasetName
prefix			prefix that you want to assign
dout			output dataset name, format: libName.datasetName
excludevars		vars that you do not want to rename with the prefix

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

%prefix( din = sashelp.buy, 
         prefix = null, 
         dout = work.out, 
         excludeVars = date);

------------------------------------------------------------------------------------------------*/

/*define options and assign pathnames*/
%include "IncludeLibrary.sas";

%IncludeLibrary;

%macro prefix( din, prefix, dout, excludeVars ) / store source;
 
	/* split the excludeVars into individual macro var names for later use*/
	%let num = 1;
	%let excludeVar = %scan( %upcase( &excludeVars ), &num, ' ' );
	%let excludeVar&num = &excludevar;
	 
	%do %while( &excludevar ne );

		%let num = %eval( &num + 1 );
		%let excludevar = %scan( &excludeVars, &num, ' ' );
		%let excludeVar&num = &excludeVar;

	%end;

	%let numkeyvars=%eval(&num - 1); /* this is number of variables given in the exclude vars */
	 
	%let dsid = %sysfunc( open( &din ) ); /* open the dataset and get the handle */
	%let numvars = %sysfunc( attrn( &dsid, nvars) ); /* get the number of variables */

	data &dout;

		set &din( rename =(

			/*rename all the variables that are not in the excludeVars= */
			%do i = 1 %to &numvars;

				%let flag = N;
				%let var&i = %sysfunc( varname( &dsid, &i) );

				%do j = 1 %to &numkeyvars;

					%if %upcase( &&var&i ) eq &&excludeVar&j %then %let flag = Y;

				%end;

				%if &flag eq N %then %do; 

					&&var&i = &prefix&&var&i %end;

			%end; ) );
	 
		%let rc = %sysfunc( close( &dsid ) );

	run;

%mend prefix;
