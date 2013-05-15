/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	8/8/12

Copyright (C) 2010 Regents of the University of Colorado.

This program is free software; you can redistribute it and/or modify it under the terms of the 
GNU General Public License as published by the Free Software Foundation; either version 2 of the 
License, or (at your option) any later version. This program is distributed in the hope that it 
will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You 
should have received a copy of the GNU General Public License along with this program; if not, 
write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
02110-1301, USA.
 
------------------------------------------------------------------------------------------------
									   DESCRIPTION
------------------------------------------------------------------------------------------------

The DecisionErrorTool module simulates data from a paired screening trial with Gaussian
outcomes.  The hypothesis of interest is whether or not there is a difference in the areas 
under the curves of the two screening tests.  The macro simulates data under both the null and 
alternative hypotheses and calculates Type I error and power for three analyses: a standard 
analysis, a bias-corrected analysis, and a complete analysis. The standard analysis is based on 
the methods of Obuchowski and McClish (1997).  The bias-corrected analysis uses the method of 
Ringham et al. (in review) to correct for paired screening trial bias.  The complete analysis is 
a reference analysis that assumes we know the true disease status of all participants.

Note:  For the function, nathAlgorithm, we fix the total number of iterations 
(i.e., maxIterations) and the tolerance at 500 and 0.000001, respectively.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

seed        					seed for random number generation
errC							code for undefined entries - missing value not allowed
                				avoid values that could be misconstrued as a data point
nOfreal     					number of realizations of the study
samSize							sample size in each study
mT1ScoC    						mean of test 1 scores for cases
mT2ScoC    						mean of test 2 scores for cases
stdT1ScoC   					standard deviation of test 1 scores for cases
stdT2ScoC   					standard deviation of test 2 scores for cases
corrT1T2C    					correlation between test 1 and 2 scores for cases
mT1ScoNonC    					mean of test 1 scores for non-cases
mT2ScoNonC    					mean of test 2 scores for non-cases
stdT1ScoNonC   					standard deviation of test 1 scores for non-cases
stdT2ScoNonC   					standard deviation of test 2 scores for non-cases 
corrT1T2NonC    				correlation between test 1 and 2 scores for non-cases
disPrev      					disease prevalence
cutOffT1T2						cutoffs for tests 1 and 2
rOfSS							rate of signs and symptoms

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

%DecisionErrorTool( seed = 1066,
                    errC = -99999, 
                    nOfreal = 10000, 
                    samSize = 50000,
                    mT1ScoC = 62.1, 
                    mT2ScoC = 61.2, 
                    stdT1ScoC = 1, 
                    stdT2ScoC = 1, 
                    corrT1T2C = .1, 
                    mT1ScoNonC = 60, 
                    mT2ScoNonC = 59.1, 
                    stdT1ScoNonC = 1, 
                    stdT2ScoNonC = 1, 
                    corrT1T2NonC = .1, 
                    disPrev = .01, 
                    cutOffT1T2 = { 65 59 }, 
                    rOfSS = .1 ); 
 
------------------------------------------------------------------------------------------------*/

/*set options*/
options mprint merror mlogic symbolgen source2;

/*include stored modules and define pathname to save output*/
%include "IncludeLibrary.sas";

%IncludeLibrary;

%macro DecisionErrorTool( seed, errC, nOfreal, samSize, mT1ScoC, mT2ScoC, stdT1ScoC, stdT2ScoC, 
                          corrT1T2C, mT1ScoNonC, mT2ScoNonC, stdT1ScoNonC, stdT2ScoNonC, 
                          corrT1T2NonC, disPrev, cutOffT1T2, rOfSS ) / store source; 

	/*delete any old datasets of the same name in the out01 library*/
	proc datasets lib = out01;

		delete resultsDE;

	run;

	/*delete any old datasets of the same name in the work library*/
	proc datasets lib = work;

		delete resultsAlt resultsNull;

	run;

	/*alternative*/
	%DecisionErrorSimulator( seed = &seed,
				             errorCode = &errC,
							 numberOfrealizations = &nOfreal,
							 sampleSize = &samSize,
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
	%DecisionErrorSimulator( seed = &seed,
				             errorCode = &errC,
							 numberOfrealizations = &nOfreal,
							 sampleSize = &samSize,
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
	data out01.resultsDE;

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

	/*create summary report*/
	%DecisionErrorToolTable( lib = out01, 
                             din = resultsDE, 
                             title = Table 1. Simulated Decision Metrics., 
                             errorcode = &errC );

%mend;


