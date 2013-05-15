/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	2/4/13
 
Description:
This program creates a reference dataset to compare to the new version of the 
DecisionErrorSimulatorTool.

********************************************************************************************/

/*%include "CommonMain.sas";*/
%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas"; /*Added by Aarti */
/*%include "../Modules/CommonMain.sas";*/

%CommonMain( BiasCorrectionTuneUp, DecisionErrorSimulatorReference, DecisionErrorSimulatorReference ); 

proc printto log = "&OUTPUT_FILE..log";
run;

/*Alternative*/
%IMLBiasCorrectionDecisionError( 1066, -99999, 3, 50000, .000001, 500, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1, diseasePrevalence, vector = ( { .01 } ) );

/*rename dataset*/
/*rename variables that are too long*/
data resultsAlt;

	set out01.results;

run;

/*add Alt prefix to variables in the ResultsAlt dataset*/
/*for some reason the prefix macro only excludes the first variable in the list*/
%prefix( din = resultsAlt, 
         prefix = Alt_, 
         dout = out01.resultsAlt, 
         excludeVars = rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2 );

/*Null*/
/*Test 2 values the same as Test 1 values*/
%IMLBiasCorrectionDecisionError( 1066, -99999, 3, 50000, .000001, 500, 61.1, 61.1, 1, 1, .1, 60, 60, 1, 1, .1, .01, { 65 59 }, .1, diseasePrevalence, vector = ( { .01 } ) );

/*rename dataset*/
/*rename variables that are too long*/
data resultsNull;

	set out01.results;

run;

/*add Null prefix to variables in the ResultsNull dataset*/
/*for some reason the prefix macro only excludes the first variable in the list*/
%prefix( din = resultsNull, 
         prefix = Null_, 
         dout = out01.resultsNull, 
         excludeVars = rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2 );

/*combine the two datasets into one permanent results dataset*/
data out01.results;

	merge out01.resultsAlt ( rename = ( alt_diseasePrevalence = diseasePrevalence alt_rateSignsSymptoms = rateSignsSymptoms 
                                        alt_cutoffTest1 = cutoffTest1 alt_cutoffTest2 = cutoffTest2 ) )
          out01.resultsNull ( rename = ( null_diseasePrevalence = diseasePrevalence null_rateSignsSymptoms = rateSignsSymptoms 
                                        null_cutoffTest1 = cutoffTest1 null_cutoffTest2 = cutoffTest2 ) );

	by rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2;

run;

proc printto;

run;

proc contents data=out01.results;

