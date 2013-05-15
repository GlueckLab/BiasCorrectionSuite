/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	5/6/12
 
Description:
This program bias corrects the AUC for randomly generated binormal data at different disease 
prevalences over a narrow range.  The motivating example is a screening population where the 
sample consists of cases and non-cases.  There are two screening test scores associated with 
each participant.  The means, variances, and correlations of the test scores are conditional 
on whether the participant is a case or a non-case.

********************************************************************************************/

/*%include "CommonMain.sas";*/
%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas"; /*Added by Aarti */
/*%include "../Modules/CommonMain.sas";*/

%CommonMain( BiasCorrectionTuneUp, ExperimentName, IMLBiasCorrectionLowPowerPrevalence ); 



/*proc printto log = "&OUTPUT_FILE..log";*/
/*run;*/

/* %DecisionErrorTool02( 1066, -99999, 3, 50000, .000001, 500, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1 ); */

 %BiasCorrectionTool06( Example1, -99999, { 65 59 } );


/*%BiasCorrectionTool03( 1066, -99999, 3, 50000, .000001, 500, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1, diseasePrevalence, vector = ( { .01, .025, .05, .075, .1, .125, .15, .175, .2, .225, .25 } ) );*/

/*%IMLBiasCorrectionResults( lib = out01,*/
/*                           din = results,*/
/*                           errorCode = -99999, */
/*                           var = diseasePrevalence, */
/*                           varLabel = Disease Prevalence, */
/*                           ncat = 11 );*/

/*proc printto;*/
/*run;*/
/**/
/*/*numbers for manuscript*/*/
/*/*percent ascertainment and true area under the curves*/*/
/*ods pdf file = "&OUTPUT_FILE.AUC.pdf";*/
/*proc means data = out01.results nolabels;*/
/*	where correctedReject ^= -99999;*/
/*	class diseasePrevalence;*/
/*	var populationAUCT1 populationAUCT2;*/
/*run;*/
/*ods pdf close;*/
/**/
/*data calcPercentAsc;*/
/*	set out01.results;*/
/*	percentAscT1 = ( numberObsCasesQuadrant1 + numberObsCasesQuadrant2 ) / numberObsCases;*/
/*	percentAscT2 = ( numberObsCasesQuadrant1 + numberObsCasesQuadrant3 ) / numberObsCases;*/
/*run;*/
/**/
/*ods pdf file = "&OUTPUT_FILE.percentAscertain.pdf";*/
/*proc means data = calcPercentAsc nolabels;*/
/*	where correctedReject ^= -99999;*/
/*	class diseasePrevalence;*/
/*	var percentAscT1 posT1SSGoldStd percentAscT2 posT2SSGoldStd;*/
/*run;*/
/*ods pdf close;*/
/**/
/*/*numbers for manuscript*/*/
/*/*percent ascertainment and true area under the curves*/*/
/*ods pdf file = "&OUTPUT_FILE.RejectionFraction.pdf";*/
/*proc freq data = out01.results;*/
/*	where correctedReject ^= -99999;*/
/*	tables diseasePrevalence * directionCompleteHypTest diseasePrevalence * directionObservedHypTest */
/*           diseasePrevalence * directionCorrectedHypTest;*/
/*run;*/
/*ods pdf close;*/
