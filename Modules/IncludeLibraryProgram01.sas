/********************************************************************************************
Created By:		Brandy Ringham
Creation Date:	8/30/11
Description:	Assigns common libnames and options for storing macros.
********************************************************************************************/

%macro IncludeLibraryProgram01;
	
	/*set options;*/
	options mstored sasmstore = mlib fullstimer;
	
	/*assign directory to store macros;*/
	
	%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas"; /*Added by Aarti */

	%CommonMain;

	%include "CommonMacro.sas";
	%include "../Modules/CommonMacro.sas";

	%CommonMacro;

	%DefineOutputPath( &project_name, &experiment_name, &program_name );

	/*put operating system, output path, and output filename to log;*/
	%put Operating System: &sysscp;
	%put Output Path: &OUTPUT_PATH;
	%put Output File: &OUTPUT_FILE;

	%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\DefineMacroPath.sas"; /*Added by Aarti */

	%DefineMacroPath;

	/*put operating system and macro path to log;*/
	%put Operating System: &sysscp;
	%put Macro Vault: &MACRO_VAULT;

	/*libname defined in "DefineMacroPath.sas";*/
	libname mlib "&MACRO_VAULT";

%mend;
