/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	8/29/11

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

Defines pathname for macro library.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

None

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example call;

%DefineMacroPath

------------------------------------------------------------------------------------------------*/

*Set macro library file location for bias correction process;
%macro DefineMacroPath;
%global MACRO_VAULT;

	/*Windows operating system pathname format;*/
	%if &sysscp = WIN %then %do;

		%let MACRO_VAULT = ..\Library;

	%end;

	%else %do;

		%put "Unrecognized OS - check OS pathname requirements and revise DefineMacroPath.sas";

	%end;
	
%mend;
