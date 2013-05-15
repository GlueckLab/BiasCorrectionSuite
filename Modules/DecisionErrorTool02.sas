/********************************************************************************************
Created By:		Brandy Ringham     
Creation Date:	8/8/12
 
********************************************************************************************/

%include "CommonMacro.sas";
%include "../Modules/CommonMacro.sas";

options mprint merror mlogic symbolgen source2;

%CommonMacro;

%macro DecisionErrorTool02( seed, errC, nOfreal, samSize, tol, maxIter, mT1ScoC, mT2ScoC, stdT1ScoC, stdT2ScoC, corrT1T2C, mT1ScoNonC, mT2ScoNonC, stdT1ScoNonC, stdT2ScoNonC, corrT1T2NonC, disPrev, cutOffT1T2, rOfSS ) / store source; 

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
				             errorCode = &errC,
							 numberOfrealizations = &nOfreal,
							 sampleSize = &samSize,
							 tolerance = &tol,
							 maxIterations = &maxIter,
							 meanOfTest1ScoresCases = &mT1ScoC,
							 meanOfTest2ScoresCases = &mT2ScoC,
							 stdOfTest1ScoresCases = &stdT1ScoC,
							 stdOfTest2ScoresCases = &stdT2ScoC, 
							 correlationT1T2ForCases = &corrT1T2C, 
							 meanOfTest1ScoresNonCases = &mT1ScoNonC,
							 meanOfTest2ScoresNonCases = &mT2ScoNonC,
							 stdOfTest1ScoresNonCases = &stdT1ScoNonC,
							 stdOfTest2ScoresNonCases = &stdT2ScoNonC,
							 correlationT1T2ForNonCases = &corrT1T2NonC,
							 diseasePrevalence = &disPrev,
							 cutOffT1T2 = &cutOffT1T2,
							 rateOfSignsSymptoms = &rOfSS );

	data work.resultsAlt;

		set work.results;

	run;

	/*null*/
	%DecisionErrorSimulator03( seed = &seed,
				             errorCode = &errC,
							 numberOfrealizations = &nOfreal,
							 sampleSize = &samSize,
							 tolerance = &tol,
							 maxIterations = &maxIter,
							 meanOfTest1ScoresCases = &mT1ScoC,
							 meanOfTest2ScoresCases = &mT1ScoC,
							 stdOfTest1ScoresCases = &stdT1ScoC,
							 stdOfTest2ScoresCases = &stdT1ScoC, 
							 correlationT1T2ForCases = &corrT1T2C, 
							 meanOfTest1ScoresNonCases = &mT1ScoNonC,
							 meanOfTest2ScoresNonCases = &mT1ScoNonC,
							 stdOfTest1ScoresNonCases = &stdT1ScoNonC,
							 stdOfTest2ScoresNonCases = &stdT1ScoNonC,
							 correlationT1T2ForNonCases = &corrT1T2NonC,
							 diseasePrevalence = &disPrev,
							 cutOffT1T2 = &cutOffT1T2,
							 rateOfSignsSymptoms = &rOfSS );

	data work.resultsNull;

		set work.results;

	run;

	/*add Alt prefix to variables in the AltResults dataset*/
	%prefix( din = work.resultsAlt, 
	         prefix = Alt_, 
	         dout = work.resultsAlt, 
	         excludeVars = rep );

	/*add Null prefix to variables in the NullResults dataset*/
	%prefix( din = work.resultsNull,
	         prefix = Null_,
			 dout = work.resultsNull,
			 excludeVars = rep );

	/*combine the two datasets into one permanent results dataset*/
	data out01.results;

		merge work.resultsAlt ( rename = ( alt_diseasePrevalence = diseasePrevalence
                                           alt_rateSignsSymptoms = rateSignsSymptoms
                                           alt_cutoffTest1 = cutoffTest1
                                           alt_cutoffTest2 = cutoffTest2 ) )
              work.resultsNull ( rename = ( null_diseasePrevalence = diseasePrevalence
                                           null_rateSignsSymptoms = rateSignsSymptoms
                                           null_cutoffTest1 = cutoffTest1
                                           null_cutoffTest2 = cutoffTest2 ) );

		by rep diseasePrevalence rateSignsSymptoms cutoffTest1 cutoffTest2;

	run;

	%DecisionErrorToolTable( lib = out01, 
                                         din = results, 
                                         title = Table 1. Simulated Decision Metrics., 
                                         errorcode = &errC );

/*Brandy will insert report code here*/

	proc contents data=resultsAlt;

	proc contents data=resultsNull;

	run;


%mend;


