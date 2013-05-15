/********************************************************************************************
Created By:		Brandy Ringham
Creation Date:	8/30/11
Description:	Choose pathname for the SAS dataset library.  Format depends on the type of
                operating system.

Inputs:
project_name		project name - no spaces allowed for UNIX systems
experiment_name		experiment name - no spaces allowed for UNIX systems
program_name		program name - no spaces allowed

********************************************************************************************/

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
			%let OUTPUT_PATH = C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\output\&project_name\&experiment_name;/*Added by Aarti */
			/*%let OUTPUT_PATH = ..\..\output\&project_name\&experiment_name;*/
/*		%let OUTPUT_PATH = C:\Ringham\Dropbox\Glueck Lab\Biostatistics PhD Project\Bias Correction R03 - paired\Process\&project_name\&experiment_name;*/
		%let OUTPUT_FILE = &OUTPUT_PATH\&program_name;
	%end;

	/*LINUX operating system pathname format;*/
	%else %if &sysscp = LIN X64 or &sysscp = LINUX %then %do;
		%let OUTPUT_PATH = ~/output/&project_name/&experiment_name;
		%let OUTPUT_FILE = &OUTPUT_PATH/&program_name;
	%end;

	%else %do;
		%put "Unrecognized OS - check OS pathname requirements and revise DefineOutputPath.sas";
	%end;
	
%mend;
