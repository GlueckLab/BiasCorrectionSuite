/********************************************************************************************
Created By:		Brandy Ringham
Creation Date:	8/30/11
Description:	Assigns common libnames and options for storing macros.
********************************************************************************************/

%macro CommonMacro;
	
	/*set options;*/
	options mstored sasmstore = mlib fullstimer;
	
	/*assign directory to store macros;*/
	%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\DefineMacroPath.sas"; /*Added by Aarti */


	%DefineMacroPath;

	/*put operating system and macro path to log;*/
	%put Operating System: &sysscp;
	%put Macro Vault: &MACRO_VAULT;

	/*libname defined in "DefineMacroPath.sas";*/
	libname mlib "&MACRO_VAULT";

%mend;
