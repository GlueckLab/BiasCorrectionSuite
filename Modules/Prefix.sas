/*
Date:			1/31/13
Created By:		Brandy Ringham
Description:	Macro that adds a prefix to some or all variables in a dataset.
				Copied from 
				http://technico.qnownow.com/sas-macro-to-add-a-prefix-to-some-or-all-variables-in-a-data-set/
Arguments:
din				input dataset name libname.dsnname
prefix			prefix that you want to assign
dout			output dataset name libname.dsnname
excludevars		vars that you do not want to rename with the prefix

Usage:
%prefix( sashelp.buy, null, work.out, excludeVars = date);

*/

%include "CommonMacro.sas";
%include "../Modules/CommonMacro.sas";

%CommonMacro;

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
	 
		%let rc = %sysfunc(close(&dsid));

	run;

%mend prefix;

%prefix( sashelp.buy, null, work.out, excludeVars = date);
