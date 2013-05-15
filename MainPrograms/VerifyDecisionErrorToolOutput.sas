/*
Created By:		Brandy Ringham    
Creation Date:	1/28/13
*/

title1 "VerifyBLAH.sas";
title2 "Unit test of the module CompareDatasets.sas";
title3 "The ""Different"" pdf file compares two different example datasets";
title4 "The ""Same"" pdf file compares two datasets that are exactly the same";

/*%include "../Modules/CommonMain.sas";*/
%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas";

%CommonMain( BiasCorrectionTuneUp, VerifyDecisionErrorToolOutput, VerifyDecisionErrorToolOutput );

libname in01 "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\output\BiasCorrectionTuneUp\DecisionErrorSimulatorReference";
libname in02 "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\output\BiasCorrectionTuneUp\ExperimentName";

%CompareDatasets( 	data1 = in01.results, /* refers to the reference run dataset */
						data2 = in02.results, /* refers to the decision error simulator dataset */
						outputFile = &OUTPUT_FILE..pdf );
