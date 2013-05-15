/********************************************************************************************
Created By:		Brandy Ringham     
Creation Date:	8/8/12
 
********************************************************************************************/

%include "CommonMacro.sas";
%include "../Modules/CommonMacro.sas";

options mprint merror mlogic symbolgen source2;

%CommonMacro;

%macro DecisionErrorTool01( seed, errorCode, numberOfrealizations, sampleSize, tolerance, maxIterations, meanOfTest1ScoresCases, meanOfTest2ScoresCases, stdOfTest1ScoresCases, stdOfTest2ScoresCases, correlationT1T2ForCases, meanOfTest1ScoresNonCases, meanOfTest2ScoresNonCases, stdOfTest1ScoresNonCases, stdOfTest2ScoresNonCases, correlationT1T2ForNonCases, diseasePrevalence, cutOffT1T2, rateOfSignsSymptoms ) / store source; 

	/*delete any old datasets of the same name in the out01 library*/
	proc datasets lib = out01;

		delete results;

	run;

/*	delete any old datasets of the same name in the work library*/
	proc datasets lib = work;

		delete resultsAlt resultsNull;

	run;

	/*alternative*/
	%DecisionErrorSimulator03( seed = &seed,
				             errorCode = &errorCode,
							 numberOfrealizations = &numberOfrealizations,
							 sampleSize = &sampleSize,
							 tolerance = &tolerance,
							 maxIterations = &maxIterations,
							 meanOfTest1ScoresCases = &meanOfTest1ScoresCases,
							 meanOfTest2ScoresCases = &meanOfTest2ScoresCases,
							 stdOfTest1ScoresCases = &stdOfTest1ScoresCases,
							 stdOfTest2ScoresCases = &stdOfTest2ScoresCases, 
							 correlationT1T2ForCases = &correlationT1T2ForCases, 
							 meanOfTest1ScoresNonCases = &meanOfTest1ScoresNonCases,
							 meanOfTest2ScoresNonCases = &meanOfTest2ScoresNonCases,
							 stdOfTest1ScoresNonCases = &stdOfTest1ScoresNonCases,
							 stdOfTest2ScoresNonCases = &stdOfTest2ScoresNonCases,
							 correlationT1T2ForNonCases = &correlationT1T2ForNonCases,
							 diseasePrevalence = &diseasePrevalence,
							 cutOffT1T2 = &cutOffT1T2,
							 rateOfSignsSymptoms = &rateOfSignsSymptoms );

	data work.resultsAlt;

		set work.results;

	run;

	/*null*/
	%DecisionErrorSimulator03( seed = &seed,
				             errorCode = &errorCode,
							 numberOfrealizations = &numberOfrealizations,
							 sampleSize = &sampleSize,
							 tolerance = &tolerance,
							 maxIterations = &maxIterations,
							 meanOfTest1ScoresCases = &meanOfTest1ScoresCases,
							 meanOfTest2ScoresCases = &meanOfTest1ScoresCases,
							 stdOfTest1ScoresCases = &stdOfTest1ScoresCases,
							 stdOfTest2ScoresCases = &stdOfTest1ScoresCases,
							 correlationT1T2ForCases = &correlationT1T2ForCases, 
							 meanOfTest1ScoresNonCases = &meanOfTest1ScoresNonCases,
							 meanOfTest2ScoresNonCases = &meanOfTest1ScoresNonCases,
							 stdOfTest1ScoresNonCases = &stdOfTest1ScoresNonCases,
							 stdOfTest2ScoresNonCases = &stdOfTest1ScoresNonCases,
							 correlationT1T2ForNonCases = &correlationT1T2ForNonCases,
							 diseasePrevalence = &diseasePrevalence,
							 cutOffT1T2 = &cutOffT1T2,
							 rateOfSignsSymptoms = &rateOfSignsSymptoms );

	data work.resultsNull;

		set work.results;

	run;

	/*add Alt prefix to variables in the AltResults dataset*/
	%prefix( din = work.resultsAlt, 
	         prefix = Alt_, 
	         dout = work.resultsAlt, 
	         excludeVars = rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2 );

	/*add Null prefix to variables in the NullResults dataset*/
	%prefix( din = work.resultsNull,
	         prefix = Null_,
			 dout = work.resultsNull,
			 excludeVars = rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2 );

	/*combine the two datasets into one permanent results dataset*/
	data out01.results;

		merge work.resultsPower work.resultsNull;
		by rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2;

	run;

/*Brandy will insert report code here*/

%mend;
