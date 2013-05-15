/********************************************************************************************
Created By:	Brandy Ringham
Creation Date:	8/29/11
Description:	Choose pathname for macro library.  Format depends on the type of
                operating system.
********************************************************************************************/

*Set macro library file location for bias correction process;
*Auto-identify the operating system and choose the correct pathname format;
%macro DefineMacroPath;
%global MACRO_VAULT;

	/*Windows operating system pathname format;*/
	%if &sysscp = WIN %then %do;
		%let MACRO_VAULT = ..\MacroVault;
/*		%let MACRO_VAULT = C:\Ringham\Macro Vault;*/
	%end;

	/*LINUX operating system pathname format;*/
	%else %if &sysscp = LIN X64 or &sysscp = LINUX %then %do;
		%let MACRO_VAULT = ~/macroVault;
	%end;

	%else %do;
		%put "Unrecognized OS - check OS pathname requirements and revise DefineMacroPath.sas";
	%end;
	
%mend;
