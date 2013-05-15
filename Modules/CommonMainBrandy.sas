/********************************************************************************************
Created By:		Brandy Ringham
Creation Date:	8/30/11
Description:	Assigns common libnames and options for SAS main programs.

Inputs:
project_name		project name - no spaces allowed for UNIX systems
experiment_name		experiment name - no spaces allowed for UNIX systems
program_name		program name - no spaces allowed

********************************************************************************************/

%macro CommonMain( project_name, experiment_name, program_name );
 
	options fullstimer notes source source2 spool errors = max mprint symbolgen mlogic mstored sasmstore = mlib;

	%include "../Modules/DefineOutputPath.sas";

	%DefineOutputPath( &project_name, &experiment_name, &program_name );

	/*put operating system, output path, and output filename to log;*/
	%put Operating System: &sysscp;
	%put Output Path: &OUTPUT_PATH;
	%put Output File: &OUTPUT_FILE;

	%include "../Modules/DefineMacroPath.sas";

	%DefineMacroPath;

	/*put operating system and macro path to log;*/
	%put Operating System: &sysscp;
	%put Macro Vault: &MACRO_VAULT;

	/*libname defined in "DefineOutputPath.sas";*/
	libname out01 "&OUTPUT_PATH";

	/*libname defined in "DefineMacroPath.sas";*/
	libname mlib "&MACRO_VAULT";

	footnote1 "&PROGRAM";
	footnote2 "&sysdate";

%mend;
