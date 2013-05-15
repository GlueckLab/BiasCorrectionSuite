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

Define pathname for the SAS dataset library.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

project_name		project name
experiment_name		experiment name
program_name		name of the main program

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

%DefineOutputPath( project_name = Project1, 
                   experiment_name = Experiment1, 
                   program_name = Program1 );

------------------------------------------------------------------------------------------------*/

*Set SAS dataset library file location for bias correction process;
*Auto-identify the operating system and choose the correct pathname format;

%macro DefineOutputPath( project_name, experiment_name, program_name );

	%global OUTPUT_PATH;
	%global OUTPUT_FILE;
	%global PROGRAM;

	*set program name as a global variable so it can be used in main programs to name files;
	%let PROGRAM = &program_name;

	/*Windows operating system pathname format;*/
	%if &sysscp = WIN %then %do;

		%let OUTPUT_PATH = ..\..\Output\&project_name\&experiment_name;
		%let OUTPUT_FILE = &OUTPUT_PATH\&program_name;

	%end;

	%else %do;

		%put "Unrecognized OS - check OS pathname requirements and revise DefineOutputPath.sas";

	%end;
	
%mend;
