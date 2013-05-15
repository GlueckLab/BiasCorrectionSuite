/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	5/1/13

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

Assigns libnames and options for storing macros, accessing macros, and saving output.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

None
------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

%IncludeLibrary;

------------------------------------------------------------------------------------------------*/

%macro IncludeLibrary;
	
	/*set options;*/
	options mstored sasmstore = mlib fullstimer;
	
	/*assign directory to store macros;*/
	/*the first path is for accessing modules from a main program*/	
	/*the second path is for storing modules*/
	%include "..\Modules\CommonMain.sas";
	%include "CommonMain.sas";

	%CommonMain;

	/*the first path is for accessing modules from a main program*/	
	/*the second path is for storing modules*/
	%include "DefineMacroPath.sas"; 
	%include "..\Modules\DefineMacroPath.sas";
	
	%DefineMacroPath;

	/*put operating system and macro path to log;*/
	%put Operating System: &sysscp;
	%put Macro Vault: &MACRO_VAULT;

	/*libname defined in "DefineOutputPath.sas";*/
	libname out01 "&OUTPUT_PATH";

	/*libname defined in "DefineMacroPath.sas";*/
	libname mlib "&MACRO_VAULT";

%mend;
