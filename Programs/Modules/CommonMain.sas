/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	8/30/11

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

Assigns libnames and options for SAS main programs.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

project_name		project name
experiment_name		experiment name
program_name		program name

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

%CommonMain( project_name = Project1, 
             experiment_name = Experiment1, 
             program_name = Program1 );

------------------------------------------------------------------------------------------------*/

%macro CommonMain( project_name, experiment_name, program_name );
 
	options fullstimer notes source source2 spool errors = max mprint symbolgen mlogic mstored 
            sasmstore = mlib;

	/*this statement works when the module is used when storing other modules*/
	%include "DefineOutputPath.sas"; 

	/*this statement works when the module is used in a main program*/
	%include "..\Modules\DefineOutputPath.sas"; 

	%DefineOutputPath( &project_name, &experiment_name, &program_name );

	/*put operating system, output path, and output filename to log;*/
	%put Operating System: &sysscp;
	%put Output Path: &OUTPUT_PATH;
	%put Output File: &OUTPUT_FILE;

	%include "DefineMacroPath.sas"; 
	%include "..\Modules\DefineMacroPath.sas"; 

	/*libname defined in "DefineOutputPath.sas";*/
	libname out01 "&OUTPUT_PATH";

	footnote1 "&PROGRAM";
	footnote2 "&sysdate";

%mend;
