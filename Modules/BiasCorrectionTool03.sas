/*  *******************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/12/11
 
----------------------------------------------------------------------------------------------------------------
									DESCRIPTION OF TOOL
----------------------------------------------------------------------------------------------------------------

The BiasCorrectionTool module corrects the AUC for user data. There are two screening test 
scores associated with each participant.  The means, variances, and correlations of the 
test scores are conditional on whether the participant is a case or a non-case.

The BiasCorrectionTool defines three submodules, as briefly described below: 

standardAnalysis: performs the standard (or observed) analysis, and 
biasCorrectionAnalysis: performs the (bias) corrected analysis.

In addition to the three analysis submodule listed above, the BiasCorrectionTool also defines two other submodules, as described below:

setErrorCodes: sets error codes for several parameters based on the results of the performed analysis and 
nathInAllQuadrants: checks if the quadrants are empty and SO much more.

----------------------------------------------------------------------------------------------------------------
										USER INPUTS
----------------------------------------------------------------------------------------------------------------


The USER INPUTS required for the program are as follows:
seed        					seed for random number generation
errorCode						code for undefined entries - missing value not allowed, 
                				avoid values that could be misconstrued as a data point
numberOfrealizations     		number of realizations of the study
sampleSize 						sample size in each study
tolerance						tolerance of Nath algorithm
maxIterations					maximum number of iterations allowed for Nath algorithm
meanOfTest1ScoresCases    		mean of test 1 scores for cases
meanOfTest2ScoresCases    		mean of test 2 scores for cases
stdOfTest1ScoresCases   		standard deviation of test 1 scores for cases
stdOfTest2ScoresCases   		standard deviation of test 2 scores for cases
correlationT1T2ForCases    		correlation between test 1 and 2 scores for cases
meanOfTest1ScoresNonCases    	mean of test 1 scores for non-cases
meanOfTest2ScoresNonCases    	mean of test 2 scores for non-cases
stdOfTest1ScoresNonCases   		standard deviation of test 1 scores for non-cases
stdOfTest2ScoresNonCases   		standard deviation of test 2 scores for non-cases 
correlationT1T2ForNonCases    	correlation between test 1 and 2 scores for non-cases
diseasePrevalence      			disease prevalence
cutOffT1T2						cutoffs for tests 1 and 2
rateOfSignsSymptoms				rate of signs and symptoms
changer							variable that changes, choices are:  diseasePrevalence, rateSignsSymptoms, 
                				populationRhoCases, populationRhoNonCases, cutoffs
vector							vector or matrix of values for the changing variable


----------------------------------------------------------------------------------------------------------------
												USAGE 
----------------------------------------------------------------------------------------------------------------

The DecisionErrorSimulator module can be run via following command:

%DecisionErrorSimulator(1066, -99999, 3, 50000, .000001, 500, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1, diseasePrevalence, vector = ( { .01, .025, .05, .075, .1, .125, .15, .175, .2, .225, .25 } )); 

where, the values listed in the command above correspond to the following input parameters (in order):

seed 									= 			1066, 
errorCode 								= 			-99999, 
numberOfrealizations 					= 			3, 
sampleSize 								= 			50000, 
tolerance								= 			.000001, 
maxIterations 							= 			500, 
meanOfTest1ScoresCases 					= 			61.1, 
meanOfTest2ScoresCases 					= 			62.5, 
stdOfTest1ScoresCases 					= 			1, 
stdOfTest2ScoresCases 					= 			5, 
correlationT1T2ForCases 				= 			.1, 
meanOfTest1ScoresNonCases 				= 			60, 
meanOfTest2ScoresNonCases 				= 			58, 
stdOfTest1ScoresNonCases 				= 			1, 
stdOfTest2ScoresNonCases 				= 			5, 
correlationT1T2ForNonCases 				= 			.1, 
diseasePrevalence 						= 			.01, 
cutOffT1T2 								= 			{ 65 59 }, 
rateOfSignsSymptoms 					= 			.1, 
changer  								= 			diseasePrevalence, 
vector 									= ( { .01, .025, .05, .075, .1, .125, .15, .175, .2, .225, .25 } ) 

******************************************************************************************* */


/* ************************** Assigns pathnames and storage library ************************** */

 
%include "CommonMacro.sas";
%include "../Modules/CommonMacro.sas";

%CommonMacro;

/* **************************** DecisionErrorSimulator MACRO DEFINITION  *********************************************************************** */
/* *************************************************************************************************** */
 

%macro BiasCorrectionTool03( seed, errorCode, numberOfrealizations, sampleSize, tolerance, maxIterations, meanOfTest1ScoresCases, meanOfTest2ScoresCases, stdOfTest1ScoresCases, stdOfTest2ScoresCases, correlationT1T2ForCases, meanOfTest1ScoresNonCases,
                         meanOfTest2ScoresNonCases, stdOfTest1ScoresNonCases, stdOfTest2ScoresNonCases, correlationT1T2ForNonCases, diseasePrevalence, cutOffT1T2, rateOfSignsSymptoms, changer, vector ) / store source; 

/* **************************** clear dataset ************************************** */  

	proc datasets lib = out01 nolist;
		delete results;  
	run;
	quit;


/* **************************** create empty file with preferred characteristics ******************* */

	
	data out01.results ( compress = no );


/* **************************** Define Input Parameters ************************************** */

		attrib   

		rep								length = 8 label = "Dataset ID"
		
		obsError						length = 8 label = "Less than 2 observed cases or non-cases"
		nathError						length = 8 label = "Nath algorithm did not converge in any quadrant"
		weighted						length = 8 label = "Source of corrected estimates (1 = weighted, 0 = nath )"
		correctedNumberCasesError		length = 8 label = "Corrected Number of Cases Exceeded Total Sample Size"
		
		empty123						length = 8 label = "Less than 2 observed cases in quadrants 1, 2, and 3 together"
		emptyQuad1						length = 8 label = "Less than 2 observed cases in quadrant 1"
		emptyQuad2						length = 8 label = "Less than 2 observed cases in quadrant 2"
		emptyQuad3						length = 8 label = "Less than 2 observed cases in quadrant 3"
		emptyQuad4						length = 8 label = "Less than 2 observed cases in quadrant 4"
		
		cutoffTest1						length = 8 label = "Cutoff for Test 1"
		cutoffTest2						length = 8 label = "Cutoff for Test 2"
		
		nathMaxIterations				length = 8 label = "Maximum Number of Iterations for Nath Algorithm"
		nathTolerance					length = 8 label = "Tolerance for Nath Algorithm"
		sampleSize						length = 8 label = "Sample Size"
		
		numberObsCases					length = 8 label = "Number of Observed Cases"
		meanT1ObsCases					length = 8 label = "Test 1 Mean for Observed Cases"
	    meanT2ObsCases         			length = 8 label = "Test 2 Mean for Observed Cases"
	    stdT1ObsCases          			length = 8 label = "Test 1 Standard Deviation for Observed Cases"
	    stdT2ObsCases					length = 8 label = "Test 2 Standard Deviation for Observed Cases"
	    corrObsCases					length = 8 label = "Correlation Between Observed Cases"
		numberObsNonCases				length = 8 label = "Number of Observed Non-Cases"
		meanT1ObsNonCases				length = 8 label = "Test 1 Mean for Observed Non-Cases"
	    meanT2ObsNonCases         		length = 8 label = "Test 2 Mean for Observed Non-Cases"
	    stdT1ObsNonCases          		length = 8 label = "Test 1 Standard Deviation for Observed Non-Cases"
	    stdT2ObsNonCases				length = 8 label = "Test 2 Standard Deviation for Observed Non-Cases"
	    corrObsNonCases					length = 8 label = "Correlation Between Observed Non-Cases"
		
		numberObsCasesQuadrant1			length = 8 label = "Number of Observed Cases in Quadrant 1"
		meanT1ObsCasesQuadrant1			length = 8 label = "Test 1 Mean for Observed Cases in Quadrant 1"
	    meanT2ObsCasesQuadrant1     	length = 8 label = "Test 2 Mean for Observed Cases in Quadrant 1"
	    stdT1ObsCasesQuadrant1      	length = 8 label = "Test 1 Standard Deviation for Observed Cases in Quadrant 1"
	    stdT2ObsCasesQuadrant1	    	length = 8 label = "Test 2 Standard Deviation for Observed Cases in Quadrant 1"
	    corrObsCasesQuadrant1	    	length = 8 label = "Correlation Between Observed Cases in Quadrant 1"
		numberObsCasesQuadrant2			length = 8 label = "Number of Observed Cases in Quadrant 2"
		meanT1ObsCasesQuadrant2			length = 8 label = "Test 1 Mean for Observed Cases in Quadrant 2"
	    meanT2ObsCasesQuadrant2     	length = 8 label = "Test 2 Mean for Observed Cases in Quadrant 2"
	    stdT1ObsCasesQuadrant2      	length = 8 label = "Test 1 Standard Deviation for Observed Cases in Quadrant 2"
	    stdT2ObsCasesQuadrant2	    	length = 8 label = "Test 2 Standard Deviation for Observed Cases in Quadrant 2"
	    corrObsCasesQuadrant2	    	length = 8 label = "Correlation Between Observed Cases in Quadrant 2"
		numberObsCasesQuadrant3			length = 8 label = "Number of Observed Cases in Quadrant 3"
		meanT1ObsCasesQuadrant3			length = 8 label = "Test 1 Mean for Observed Cases in Quadrant 3"
	    meanT2ObsCasesQuadrant3     	length = 8 label = "Test 2 Mean for Observed Cases in Quadrant 3"
	    stdT1ObsCasesQuadrant3      	length = 8 label = "Test 1 Standard Deviation for Observed Cases in Quadrant 3"
	    stdT2ObsCasesQuadrant3	    	length = 8 label = "Test 2 Standard Deviation for Observed Cases in Quadrant 3"
	    corrObsCasesQuadrant3	    	length = 8 label = "Correlation Between Observed Cases in Quadrant 3"
		numberObsCasesQuadrant4			length = 8 label = "Number of Observed Cases in Quadrant 4"
		meanT1ObsCasesQuadrant4			length = 8	label = "Test 1 Mean for Observed Cases in Quadrant 4"
	    meanT2ObsCasesQuadrant4     	length = 8 label = "Test 2 Mean for Observed Cases in Quadrant 4"
	    stdT1ObsCasesQuadrant4      	length = 8 label = "Test 1 Standard Deviation for Observed Cases in Quadrant 4"
	    stdT2ObsCasesQuadrant4	    	length = 8 label = "Test 2 Standard Deviation for Observed Cases in Quadrant 4"
	    corrObsCasesQuadrant4	    	length = 8 label = "Correlation Between Observed Cases in Quadrant 4"
		numberObsCasesQ123				length = 8 label = "Number of Observed Cases in Quadrants 1, 2, and 3 Together"
		meanT1ObsCasesQ123				length = 8 label = "Test 1 Mean for Observed Cases in Quadrants 1, 2, and 3 Together"
	    meanT2ObsCasesQ123     			length = 8 label = "Test 2 Mean for Observed Cases in Quadrants 1, 2, and 3 Together"
	    stdT1ObsCasesQ123      			length = 8 label = "Test 1 Standard Deviation for Observed Cases in Quadrants 1, 2, and 3 Together"
	    stdT2ObsCasesQ123	    		length = 8 label = "Test 2 Standard Deviation for Observed Cases in Quadrants 1, 2, and 3 Together"
	    corrObsCasesQ123	    		length = 8 label = "Correlation Between Observed Cases in Quadrants 1, 2, and 3 Together"
		outcomeNathQuad1				length = 8 label = "Outcome of Nath Algorithm in Quadrant 1"
		outcomeNathQuad2				length = 8 label = "Outcome of Nath Algorithm in Quadrant 2"
		outcomeNathQuad3				length = 8 label = "Outcome of Nath Algorithm in Quadrant 3"
		outcomeNathQuad4				length = 8 label = "Outcome of Nath Algorithm in Quadrant 4"
		choice							length = 8 label = "Nath Estimates Chosen From This Quadrant"
		logL							length = 8 label = "Log Likelihood for Nath Estimates from Chosen Quadrant"
	  	nathIterations					length = 8 label = "Number of Iterations of Nath Algorithm for Chosen Quadrant"
		nathOutcome  					length = 8 label = "Nath Error Code for Chosen Quadrant"
		nathMu1							length = 8 label = "Nath Estimate for Mu1"
		nathMu2							length = 8 label = "Nath Estimate for Mu2"
		nathSig1						length = 8 label = "Nath Estimate for Sig1"
		nathSig2						length = 8 label = "Nath Estimate for Sig2"
		nathRho							length = 8 label = "Nath Estimate for Rho"
		probQ123Nath					length = 8 label = "Estimated Probability of Quadrants 1, 2, and 3 Based On Nath"
		probQuadrant4Nath				length = 8 label = "Estimated Probability of Quadrant 4 Based On Nath"
		probQ123Weighted				length = 8 label = "Estimated Probability of Quadrants 1, 2, and 3 Based On Weighted Estimates"
		probQuadrant4Weighted			length = 8 label = "Estimated Probability of Quadrant 4 Based On Weighted Estimates"
		correctedNumberCases			length = 8 label = "Corrected Number of Cases Based On Nath"
		correctedNumberNonCases  		length = 8 label = "Corrected Number of Non-Cases Based On Nath"
		weightedMu1						length = 8 label = "Weighted Estimate for Mu1"
		weightedMu2						length = 8 label = "Weighted Estimate for Mu2"
		weightedSig1					length = 8 label = "Weighted Estimate for Sig1"
		weightedSig2					length = 8 label = "Weighted Estimate for Sig2"
		weightedRho						length = 8 label = "Weighted Estimate for Rho"
		correctedMu1					length = 8 label = "Corrected Estimate for Mu1"
		correctedMu2					length = 8 label = "Corrected Estimate for Mu2"
		correctedSig1					length = 8 label = "Corrected Estimate for Sig1"
		correctedSig2					length = 8 label = "Corrected Estimate for Sig2"
		correctedRho					length = 8 label = "Corrected Estimate for Rho"
		
		
		observedAUCT1ParmA				length = 8 label = "Parameter A for Test 1 Binormal AUC Calculated Using Observed Summary Stats"
		observedAUCT1ParmB				length = 8 label = "Parameter B for Test 1 Binormal AUC Calculated Using Observed Summary Stats"
		observedAUCT1					length = 8 label = "Test 1 AUC Calculated From Observed Summary Stats"
		observedAUCT2ParmA				length = 8 label = "Parameter A for Test 2 Binormal AUC Calculated Using Observed Summary Stats"
		observedAUCT2ParmB				length = 8 label = "Parameter B for Test 2 Binormal AUC Calculated Using Observed Summary Stats"
		observedAUCT2					length = 8 label = "Test 2 AUC Calculated From Observed Summary Stats"
		observedDeltaAUC				length = 8 label = "Difference in AUC (Test 1 - Test 2) Calculated From Observed Summary Stats"
		observedSEDeltaAUC				length = 8 label = "Standard Error of the Difference in AUC Calculated From Observed Summary Stats"
		observedZDeltaAUC				length = 8 label = "Z Value for Delta AUC Hypothesis Test Calculated From Observed Summary Stats"
		observedPDeltaAUC				length = 8 label = "P Value for Delta AUC Hypothesis Test Calculated From Observed Summary Stats"
		observedReject					length = 8 label = "Indicator that Delta AUC Hypothesis Test Calculated From Observed Summary Stats Rejected (1 = reject, 0 = fail to reject)"
		
		correctedAUCT1ParmA				length = 8 label = "Parameter A for Test 1 Binormal AUC Calculated Using Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedAUCT1ParmB				length = 8 label = "Parameter B for Test 1 Binormal AUC Calculated Using Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedAUCT1					length = 8 label = "Test 1 AUC Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedAUCT2ParmA				length = 8 label = "Parameter A for Test 2 Binormal AUC Calculated Using Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedAUCT2ParmB				length = 8 label = "Parameter B for Test 2 Binormal AUC Calculated Using Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedAUCT2					length = 8 label = "Test 2 AUC Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedDeltaAUC				length = 8 label = "Difference in AUC (Test 1 - Test 2) Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedSEDeltaAUC				length = 8 label = "Standard Error of the Difference in AUC Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedZDeltaAUC				length = 8 label = "Z Value for Delta AUC Hypothesis Test Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedPDeltaAUC				length = 8 label = "P Value for Delta AUC Hypothesis Test Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases"
		correctedReject					length = 8 label = "Indicator that Delta AUC Hypothesis Test Calculated From Corrected Summary Stats for Cases / Observed for Non-Cases Rejected (1 = reject, 0 = fail to reject)"
		
		additionalColumnsNeeded			length = 8 label = "Number of empty columns added to the row to make the matrix conform - if this number is anything but 0 DO NOT USE ROW"
		columnError						length = 8 label = "1 = program errored out and dummy columns were created, 0 = no errors that required dummy columns"
		resumeError						length = 8 label = "1 = program errored out and resumed without resolving error, 0 = no resume error"
		errorsThisRep					length = 8 label = "Number of errors ignored for the current iteration"
		cumErrors						length = 8 label = "Cumulative number of errors ignored during program";
	
		

		if _n_= 1 then delete;

	run;

/*	reset log print;*/

	proc iml worksize = 3000 symsize = 6000;	


/* **************************** Define storage location for modules and load all modules ************************************** */

		reset storage = mlib.IMLModules;
		load _all_;

/* **************************** Free variables that do not change within the do loop ************************************** */
/* *** NOTE: In order to make the program more flexible, we also free the experimental variable but then reassign it later 
		                                                                             *** */

		free errCode cumErrors pastErrors 
			 maxIterations tolerance sampleSize
			 meanOfTest1ScoresCases meanOfTest2ScoresCases meanOfTest1ScoresNonCases meanOfTest2ScoresNonCases stdOfTest1ScoresCases stdOfTest2ScoresCases stdOfTest1ScoresNonCases stdOfTest2ScoresNonCases
             rateSignsSymptoms diseasePrevalence cutoffs populationRhoCases populationRhoNonCases
			 populationAUCT1 populationAUCT2 populationDeltaAUC
			 quadrantContainingMLECases quadrantContainingMLENonCases
	         ncat vectorRow;

		start main;    

			errCode = { "if cumErrors >= 0 then do;",
							"cumErrors = cumErrors + 1;",
							"call push( errCode ); resume;",
						"end;" };

			cumErrors = 0;
			pastErrors = 0;
			flag = &errorCode;

			call push( errCode );

			/* . */

/* ****************************************** setErrorCodes MODULE DEFINITION ****************************************** */ 
/* *** Set the error code for variables based on the error encountered at several steps in the decisionError module **** */


			start setErrorCodes; /* start module */
				
				if (numberObsCasesQuadrant1 < 2 & flag = 1) then do;
										
										
										meanT1ObsCasesQuadrant1 = &errorCode;
										meanT2ObsCasesQuadrant1 = &errorCode;
										stdT1ObsCasesQuadrant1 = &errorCode;
										stdT2ObsCasesQuadrant1 = &errorCode;
										corrObsCasesQuadrant1 = &errorCode;
										outcomeNathQuad1 = &errorCode;
										nathQ1Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ1 = &errorCode;
										
										

				end; /*end quadrant 1 is empty*/

				else if (numberObsCasesQuadrant2 < 2 & flag = 2) then do;
										
										
										meanT1ObsCasesQuadrant2 = &errorCode ;
										meanT2ObsCasesQuadrant2 = &errorCode ;
										stdT1ObsCasesQuadrant2 = &errorCode ;
										stdT2ObsCasesQuadrant2 = &errorCode ;
										corrObsCasesQuadrant2 = &errorCode ;
										outcomeNathQuad2 = &errorCode;
										nathQ2Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ2 = &errorCode;
										

				end; /*end quadrant 2 is empty*/
		
			    else if (numberObsCasesQuadrant3 < 2 & flag = 3) then do;
										
										
										meanT1ObsCasesQuadrant3 = &errorCode;
										meanT2ObsCasesQuadrant3 = &errorCode;
										stdT1ObsCasesQuadrant3 = &errorCode;
										stdT2ObsCasesQuadrant3 = &errorCode;
										corrObsCasesQuadrant3 = &errorCode;
										outcomeNathQuad3 = &errorCode;
										nathQ3Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ3 = &errorCode;
										

				end; /*end quadrant 3 is empty*/

				else if (numberObsCasesQuadrant4 < 2 & flag = 4) then do;

										
										meanT1ObsCasesQuadrant4 = &errorCode;
										meanT2ObsCasesQuadrant4 = &errorCode;
										stdT1ObsCasesQuadrant4 = &errorCode;
										stdT2ObsCasesQuadrant4 = &errorCode;
										corrObsCasesQuadrant4 = &errorCode;
										outcomeNathQuad4 = &errorCode;
										nathQ4Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ4 = &errorCode;
										meanT1ObsCasesQ123 = &errorCode;
										meanT2ObsCasesQ123 = &errorCode;
										stdT1ObsCasesQ123 = &errorCode;
										stdT2ObsCasesQ123 = &errorCode;
										corrObsCasesQ123 = &errorCode;

				end; /*end quadrant 4 is empty*/

				else if ( outcomeNathQuad1 ^= 0 & outcomeNathQuad2 ^= 0 & outcomeNathQuad3 ^= 0 & outcomeNathQuad4 ^= 0 & flag = 5) then do;
			
									weighted = &errorCode;
									correctedNumberCasesError = &errorCode;
									nathEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode|| &errorCode ;
									bivariateNormalProbabilitiesNath = &errorCode || &errorCode ;
									bivNormProbsWeighted = &errorCode || &errorCode ;
									correctedNumberCasesNonCases = &errorCode || &errorCode ;
									weightedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									correctedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
									correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
									correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									hypErrorCorrected = &errorCode ;
									directionCorrectedHypTest = &errorCode ;
									uncorrectedBias = &errorCode ;

				end; /*end nath algorithm did not converge in any quadrants*/

				else if ( (correctedNumberCasesNonCases[ , 1 ] > &sampleSize |
		                            correctedNumberCasesNonCases[ , 1 ] = 0) & flag = 6 ) then do;
									
									correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
									correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
									correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									hypErrorCorrected = &errorCode;
									directionCorrectedHypTest = &errorCode;
									uncorrectedBias = &errorCode;
				end; /*end corrected number of cases is greater than sample size*/

				/*if there are less than 2 observed cases or non-cases, do not calculate any summary statistics and return an error*/
				else if ( (numberObsCases < 2 | numberObsNonCases < 2) & flag = 8 ) then do;
								correctedNumberCasesError = &errorCode;
								empty123 = &errorCode;
								emptyQuad1 = &errorCode;
								emptyQuad2 = &errorCode;
								emptyQuad3 = &errorCode;
								emptyQuad4 = &errorCode;
								
								meanT1ObsCases = &errorCode;
								meanT2ObsCases = &errorCode;
								stdT1ObsCases = &errorCode;
								stdT2ObsCases = &errorCode;
								corrObsCases = &errorCode;
								meanT1ObsNonCases = &errorCode;
								meanT2ObsNonCases = &errorCode;
								stdT1ObsNonCases = &errorCode;
								stdT2ObsNonCases = &errorCode;
								corrObsNonCases = &errorCode;
								
								numberObsCasesQuadrant1 = &errorCode;
								meanT1ObsCasesQuadrant1 = &errorCode;
								meanT2ObsCasesQuadrant1 = &errorCode;
								stdT1ObsCasesQuadrant1 = &errorCode;
								stdT2ObsCasesQuadrant1 = &errorCode;
								corrObsCasesQuadrant1 = &errorCode;
								numberObsCasesQuadrant2 = &errorCode;
								meanT1ObsCasesQuadrant2 = &errorCode;
								meanT2ObsCasesQuadrant2 = &errorCode;
								stdT1ObsCasesQuadrant2 = &errorCode;
								stdT2ObsCasesQuadrant2 = &errorCode;
								corrObsCasesQuadrant2 = &errorCode;
								numberObsCasesQuadrant3 = &errorCode;
								meanT1ObsCasesQuadrant3 = &errorCode;
								meanT2ObsCasesQuadrant3 = &errorCode;
								stdT1ObsCasesQuadrant3 = &errorCode;
								stdT2ObsCasesQuadrant3 = &errorCode;
								corrObsCasesQuadrant3 = &errorCode;
								numberObsCasesQuadrant4 = &errorCode;
								meanT1ObsCasesQuadrant4 = &errorCode;
								meanT2ObsCasesQuadrant4 = &errorCode;
								stdT1ObsCasesQuadrant4 = &errorCode;
								stdT2ObsCasesQuadrant4 = &errorCode;
								corrObsCasesQuadrant4 = &errorCode;
								numberObsCasesQ123 = &errorCode;
								meanT1ObsCasesQ123 = &errorCode;
								meanT2ObsCasesQ123 = &errorCode;
								stdT1ObsCasesQ123 = &errorCode;
								stdT2ObsCasesQ123 = &errorCode;
								corrObsCasesQ123 = &errorCode;
								outcomeNathQuad1 = &errorCode;
								outcomeNathQuad2 = &errorCode;
								outcomeNathQuad3 = &errorCode;
								outcomeNathQuad4 = &errorCode;
								nathError = &errorCode;
								nathEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode|| &errorCode ;
								bivariateNormalProbabilitiesNath = &errorCode || &errorCode ;
								bivNormProbsWeighted = &errorCode || &errorCode ;
								correctedNumberCasesNonCases = &errorCode || &errorCode ;
							    weightedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
							    weighted = &errorCode;
					            correctedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;	
								
								observedAUCT1 = &errorCode || &errorCode || &errorCode ;
								observedAUCT2 = &errorCode || &errorCode || &errorCode ;
								observedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								
								hypErrorObserved = &errorCode ;
								directionObservedHypTest = &errorCode ;
								correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
								correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
								correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								
								hypErrorCorrected = &errorCode ;
								directionCorrectedHypTest = &errorCode ;
				end; /*end not enough observed cases*/
			
				/*if there are < 2 observed cases quadrants 1, 2, and 3 together,
								then return an error and do not calculate summary statistics for quadrants 1, 2, and 3*/	
				else if (numberObsCasesQ123 < 2 & flag = 9) then do;
								meanT1ObsCasesQuadrant1 = &errorCode; 
								meanT2ObsCasesQuadrant1 = &errorCode;
								stdT1ObsCasesQuadrant1 = &errorCode;
								stdT2ObsCasesQuadrant1 = &errorCode;
								corrObsCasesQuadrant1 = &errorCode;
								outcomeNathQuad1 = &errorCode;
								nathQ1Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ1 = &errorCode;
								meanT1ObsCasesQuadrant2 = &errorCode;
								meanT2ObsCasesQuadrant2 = &errorCode;
								stdT1ObsCasesQuadrant2 = &errorCode;
								stdT2ObsCasesQuadrant2 = &errorCode;
								corrObsCasesQuadrant2 = &errorCode;
								outcomeNathQuad2 = &errorCode;
								nathQ2Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ2 = &errorCode;
								meanT1ObsCasesQuadrant3 = &errorCode;
								meanT2ObsCasesQuadrant3 = &errorCode;
								stdT1ObsCasesQuadrant3 = &errorCode;
								stdT2ObsCasesQuadrant3 = &errorCode;
								corrObsCasesQuadrant3 = &errorCode;
								outcomeNathQuad3 = &errorCode;
								nathQ3Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ3 = &errorCode;
								meanT1ObsCasesQ123 = &errorCode;
								meanT2ObsCasesQ123 = &errorCode;
								stdT1ObsCasesQ123 = &errorCode;
								stdT2ObsCasesQ123 = &errorCode;
								corrObsCasesQ123 = &errorCode;
				end; /*end q123 is empty*/

				else
					print 'nothing';
				
			finish; /* finish setErrorCodes */


/*   ************************************* END MODULE setErrorCodes **************************************************  */

/* ****************************************** nathInAllQuadrants MODULE DEFINITION ****************************************** */ 
/* *****   Checks to see if the quadrants are empty. If so, calculates summary stats for only non-empty quadrants. ***** */

			start nathInAllQuadrants;

				/*if there are < 2 observed cases quadrants 1, 2, and 3 together*/ 
								/*then return an error and do not calculate summary statistics for quadrants 1, 2, and 3*/	
				
				if numberObsCasesQ123 < 2 then do;

							empty123 = 1;
							emptyQuad1 = 1; 
							emptyQuad2 = 1;
							emptyQuad3 = 1;
							flag = 9;
				
							/* ***************                           *************** */
							/* *************** CALL setErrorCodes MODULE *************** */ 
							/* ***************                           *************** */

							run setErrorCodes;
									

							/*Since Q123 is empty, then all observations must be in Q4, calculate summary stats for Q4 only*/
							emptyQuad4 = 0; 

							obsCasesQuadrant4 = matrix[ loc( indicateObsCasesQuadrant4 )`, ];

							/*find mean, std, corr*/
							meanT1ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 1 ] );
							meanT2ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 2 ] );
							covMatrixObsCasesQuadrant4 = cov( obsCasesQuadrant4[ , 1 ] || obsCasesQuadrant4[ , 2 ] );

							stdT1ObsCasesQuadrant4 = sqrt( covMatrixObsCasesQuadrant4[ 1, 1 ] );
							stdT2ObsCasesQuadrant4 = sqrt( covMatrixObsCasesQuadrant4[ 2, 2 ] );

							/*use only element 12 of the 2 x 2 covariance matrix*/
							corrObsCasesQuadrant4 = covMatrixObsCasesQuadrant4[ 1, 2 ] / stdT1ObsCasesQuadrant4 / stdT2ObsCasesQuadrant4;		


							/*run nath algorithm*/
							nathQ4Row = nathAlgorithm( errcode, cumErrors, &tolerance, &maxIterations, &errorCode, 4, cutoffs[ , 1 ], cutoffs[ , 2 ], 
						                                       meanT1ObsCasesQuadrant4, meanT2ObsCasesQuadrant4, 
						                                       stdT1ObsCasesQuadrant4, stdT2ObsCasesQuadrant4, 
						                                       corrObsCasesQuadrant4 );

							/*outcome of nath algorithm*/
							outcomeNathQuad4 = nathQ4Row[ , 2 ];

							/*maximize the log likelihood if the algorithm converged*/
							if outcomeNathQuad4 = 0 then logLQ4 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ4Row[ , 3 ], nathQ4Row[ , 4 ], 
						                                           		                 nathQ4Row[ , 5 ], nathQ4Row[ , 6 ], nathQ4Row[ , 7 ], 
						                                            	                 meanT1ObsCases, meanT2ObsCases, 
						                                            	                 stdT1ObsCases, stdT2ObsCases, 
						                                            	                 corrObsCases );

							else logLQ4 = &errorCode;
				
				end; /*end q123 is empty*/

				else do;

							empty123 = 0;

							/*Observed cases in area 1: disease = 1 and at least one test score is above its threshold*/
					  		indicateObsCasesQ123 = ( indicateObsCasesQuadrant1 | 
				                                             indicateObsCasesQuadrant2 |
				                                             indicateObsCasesQuadrant3 );

							obsCasesQ123 = matrix[ loc( indicateObsCasesQ123 )`, ];

							/*find mean, std, corr*/
							meanT1ObsCasesQ123 = mean( obsCasesQ123[ , 1 ] );
							meanT2ObsCasesQ123 = mean( obsCasesQ123[ , 2 ] );
							covMatrixObsCasesQ123 = cov( obsCasesQ123[ , 1 ] || obsCasesQ123[ , 2 ] );

							stdT1ObsCasesQ123 = sqrt( covMatrixObsCasesQ123[ 1, 1 ] );
							stdT2ObsCasesQ123 = sqrt( covMatrixObsCasesQ123[ 2, 2 ] );

							/*use only element 12 of the 2 x 2 covariance matrix*/
							corrObsCasesQ123 = covMatrixObsCasesQ123[ 1, 2 ] / stdT1ObsCasesQ123 / stdT2ObsCasesQ123;

							/*if the quadrant has < 2 obs cases then do not calculate summary statistics*/
							/*otherwise calculate summary statistics*/
							if numberObsCasesQuadrant1 < 2 then do;
									
									emptyQuad1 = 1;
									flag = 1;

									/* ***************                           *************** */
									/* *************** CALL setErrorCodes MODULE *************** */ 
									/* ***************                           *************** */
										
									run setErrorCodes;


							end; /*end quadrant 1 is empty*/

							else do;

									emptyQuad1 = 0;
									obsCasesQuadrant1 = matrix[ loc( indicateObsCasesQuadrant1 )`, ]; 

									/*find mean, std, corr*/
									meanT1ObsCasesQuadrant1 = mean( obsCasesQuadrant1[ , 1 ] );
									meanT2ObsCasesQuadrant1 = mean( obsCasesQuadrant1[ , 2 ] );
									covMatrixObsCasesQuadrant1 = cov( obsCasesQuadrant1[ , 1 ] || obsCasesQuadrant1[ , 2 ] );

									stdT1ObsCasesQuadrant1 = sqrt( covMatrixObsCasesQuadrant1[ 1, 1 ] );
									stdT2ObsCasesQuadrant1 = sqrt( covMatrixObsCasesQuadrant1[ 2, 2 ] );

									/*use only element 12 of the 2 x 2 covariance matrix*/
									corrObsCasesQuadrant1 = covMatrixObsCasesQuadrant1[ 1, 2 ] / stdT1ObsCasesQuadrant1 / stdT2ObsCasesQuadrant1;

									/*run nath algorithm*/
									nathQ1Row = nathAlgorithm( errcode, cumErrors, &tolerance, &maxIterations, &errorCode, 1, cutoffs[ , 1 ], cutoffs[ , 2 ], 
							                                       meanT1ObsCasesQuadrant1, meanT2ObsCasesQuadrant1, 
							                                       stdT1ObsCasesQuadrant1, stdT2ObsCasesQuadrant1, 
							                                       corrObsCasesQuadrant1 );

									/*outcome of nath algorithm*/
									outcomeNathQuad1 = nathQ1Row[ , 2 ];


									/*maximize the log likelihood if the algorithm converged*/
									if outcomeNathQuad1 = 0 then logLQ1 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ1Row[ , 3 ], nathQ1Row[ , 4 ], 
							                                           		                 nathQ1Row[ , 5 ], nathQ1Row[ , 6 ], nathQ1Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

									else logLQ1 = &errorCode;

							end; /*end quadrant 1 is not empty*/

							if numberObsCasesQuadrant2 < 2 then do;
										
									emptyQuad2 = 1;
									flag = 2;
										
									/* ***************                           *************** */
									/* *************** CALL setErrorCodes MODULE *************** */ 
									/* ***************                           *************** */

									run setErrorCodes;

							end; /*end quadrant 2 is empty*/

							else do;
								
									emptyQuad2 = 0;
									obsCasesQuadrant2 = matrix[ loc( indicateObsCasesQuadrant2 )`, ];

									/*find mean, std, corr*/
									meanT1ObsCasesQuadrant2 = mean( obsCasesQuadrant2[ , 1 ] );
									meanT2ObsCasesQuadrant2 = mean( obsCasesQuadrant2[ , 2 ] );
									covMatrixObsCasesQuadrant2 = cov( obsCasesQuadrant2[ , 1 ] || obsCasesQuadrant2[ , 2 ] );

									stdT1ObsCasesQuadrant2 = sqrt( covMatrixObsCasesQuadrant2[ 1, 1 ] );
									stdT2ObsCasesQuadrant2 = sqrt( covMatrixObsCasesQuadrant2[ 2, 2 ] );

									/*use only element 12 of the 2 x 2 covariance matrix*/
									corrObsCasesQuadrant2 = covMatrixObsCasesQuadrant2[ 1, 2 ] / stdT1ObsCasesQuadrant2 / stdT2ObsCasesQuadrant2;

									/*run nath algorithm*/
									nathQ2Row = nathAlgorithm( errcode, cumErrors, &tolerance, &maxIterations, &errorCode, 2, cutoffs[ , 1 ], cutoffs[ , 2 ], 
							                                       meanT1ObsCasesQuadrant2, meanT2ObsCasesQuadrant2, 
							                                       stdT1ObsCasesQuadrant2, stdT2ObsCasesQuadrant2, 
							                                       corrObsCasesQuadrant2 );

									/*outcome of nath algorithm*/
									outcomeNathQuad2 = nathQ2Row[ , 2 ];


									/*maximize the log likelihood if the algorithm converged*/
									if outcomeNathQuad2 = 0 then logLQ2 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ2Row[ , 3 ], nathQ2Row[ , 4 ], 
							                                           		                 nathQ2Row[ , 5 ], nathQ2Row[ , 6 ], nathQ2Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

									else logLQ2 = &errorCode;

							end; /*end quadrant 2 is not empty*/

							if numberObsCasesQuadrant3 < 2 then do;
									
									emptyQuad3 = 1;
									flag = 3;

									/* ***************                           *************** */
									/* *************** CALL setErrorCodes MODULE *************** */ 
									/* ***************                           *************** */
										
									run setErrorCodes;

							end; /*end quadrant 3 is empty*/

							else do;

									emptyQuad3 = 0;
									obsCasesQuadrant3 = matrix[ loc( indicateObsCasesQuadrant3 )`, ];

									/*find mean, std, corr*/
									meanT1ObsCasesQuadrant3 = mean( obsCasesQuadrant3[ , 1 ] );
									meanT2ObsCasesQuadrant3 = mean( obsCasesQuadrant3[ , 2 ] );
									covMatrixObsCasesQuadrant3 = cov( obsCasesQuadrant3[ , 1 ] || obsCasesQuadrant3[ , 2 ] );

									stdT1ObsCasesQuadrant3 = sqrt( covMatrixObsCasesQuadrant3[ 1, 1 ] );
									stdT2ObsCasesQuadrant3 = sqrt( covMatrixObsCasesQuadrant3[ 2, 2 ] );

									/*use only element 12 of the 2 x 2 covariance matrix*/
									corrObsCasesQuadrant3 = covMatrixObsCasesQuadrant3[ 1, 2 ] / stdT1ObsCasesQuadrant3 / stdT2ObsCasesQuadrant3;


									/*run nath algorithm*/
									nathQ3Row = nathAlgorithm( errcode, cumErrors, &tolerance, &maxIterations, &errorCode, 3, cutoffs[ , 1 ], cutoffs[ , 2 ], 
							                                       meanT1ObsCasesQuadrant3, meanT2ObsCasesQuadrant3, 
							                                       stdT1ObsCasesQuadrant3, stdT2ObsCasesQuadrant3, 
							                                       corrObsCasesQuadrant3 );

									/*outcome of nath algorithm*/
									outcomeNathQuad3 = nathQ3Row[ , 2 ];


									/*maximize the log likelihood if the algorithm converged*/
									if outcomeNathQuad3 = 0 then logLQ3 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ3Row[ , 3 ], nathQ3Row[ , 4 ], 
							                                           		                 nathQ3Row[ , 5 ], nathQ3Row[ , 6 ], nathQ3Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

									else logLQ3 = &errorCode;

							end; /*end quadrant 3 is not empty*/

							/*if there are < 2 observed cases in quadrant 4*/
							/*then return an error and do not calculate summary statistics for quadrant 4*/
							/*otherwise calculate summary statistics*/
							if numberObsCasesQuadrant4 < 2 then do;
									
									emptyQuad4 = 1;
									flag = 4;	

									/* ***************                           *************** */
									/* *************** CALL setErrorCodes MODULE *************** */ 
									/* ***************                           *************** */
										
									run setErrorCodes;


							end; /*end quadrant 4 is empty*/

							else do;
										
									emptyQuad4 = 0;

									obsCasesQuadrant4 = matrix[ loc( indicateObsCasesQuadrant4 )`, ];

									/*find mean, std, corr*/
									meanT1ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 1 ] );
									meanT2ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 2 ] );
									covMatrixObsCasesQuadrant4 = cov( obsCasesQuadrant4[ , 1 ] || obsCasesQuadrant4[ , 2 ] );

									stdT1ObsCasesQuadrant4 = sqrt( covMatrixObsCasesQuadrant4[ 1, 1 ] );
									stdT2ObsCasesQuadrant4 = sqrt( covMatrixObsCasesQuadrant4[ 2, 2 ] );

									/*use only element 12 of the 2 x 2 covariance matrix*/
									corrObsCasesQuadrant4 = covMatrixObsCasesQuadrant4[ 1, 2 ] / stdT1ObsCasesQuadrant4 / stdT2ObsCasesQuadrant4;


									/*run nath algorithm*/
									nathQ4Row = nathAlgorithm( errcode, cumErrors, 
															       &tolerance, &maxIterations, &errorCode, 4, cutoffs[ , 1 ], cutoffs[ , 2 ], 
							                                       meanT1ObsCasesQuadrant4, meanT2ObsCasesQuadrant4, 
							                                       stdT1ObsCasesQuadrant4, stdT2ObsCasesQuadrant4, 
							                                       corrObsCasesQuadrant4 );

									/*outcome of nath algorithm*/
									outcomeNathQuad4 = nathQ4Row[ , 2 ];


									/*maximize the log likelihood if the algorithm converged*/
									if outcomeNathQuad4 = 0 then logLQ4 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ4Row[ , 3 ], nathQ4Row[ , 4 ], 
							                                           		                 nathQ4Row[ , 5 ], nathQ4Row[ , 6 ], nathQ4Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

									else logLQ4 = &errorCode;	

							end; /*end quadrant 4 is not empty*/

				end; /*end q123 is not empty*/
				
			finish;
			
/*   ************************************* END MODULE nathInAllQuadrants **************************************************  */


/* ****************************************** standardAnalysis MODULE DEFINITION ****************************************** */ 
/* ****************************************** Performs Standard Analysis on the data ************************************** */


			start standardAnalysis;

								/* find mean, std, corr cases */

								obsCases = matrix[ loc( indicateObsCases )`, ];
								obsNonCases = matrix[ loc( indicateObsNonCases )`, ];

								meanT1ObsCases = mean( obsCases[ , 1 ] );
								meanT2ObsCases = mean( obsCases[ , 2 ] );
								covMatrixObsCases = cov( obsCases[ , 1 ] || obsCases[ , 2 ] );

								stdT1ObsCases = sqrt( covMatrixObsCases[ 1, 1 ] );
								stdT2ObsCases = sqrt( covMatrixObsCases[ 2, 2 ] );

								/*use only element 12 of the 2 x 2 covariance matrix*/
								corrObsCases = covMatrixObsCases[ 1, 2 ] / stdT1ObsCases / stdT2ObsCases;

								/*non-cases*/
								meanT1ObsNonCases = mean( obsNonCases[ , 1 ] );
								meanT2ObsNonCases = mean( obsNonCases[ , 2 ] );
								covMatrixObsNonCases = cov( obsNonCases[ , 1 ] || obsNonCases[ , 2 ] );

								stdT1ObsNonCases = sqrt( covMatrixObsNonCases[ 1, 1 ] );
								stdT2ObsNonCases = sqrt( covMatrixObsNonCases[ 2, 2 ] );

								/*use only element 12 of the 2 x 2 covariance matrix*/
								corrObsNonCases = covMatrixObsNonCases[ 1, 2 ] / stdT1ObsNonCases / stdT2ObsNonCases;

								/*calculate observed AUC*/
								observedAUCT1 = calculateAUC( errcode, cumErrors, meanT1ObsCases, meanT1ObsNonCases, stdT1ObsCases, stdT1ObsNonCases );
								observedAUCT2 = calculateAUC( errcode, cumErrors, meanT2ObsCases, meanT2ObsNonCases, stdT2ObsCases, stdT2ObsNonCases );

								observedHypTest = differenceInAUCHypothesisTest( errcode, cumErrors, observedAUCT1[ , 1 ], 
				 																 observedAUCT1[ , 2 ],
				 																 observedAUCT1[ , 3 ],
																				 observedAUCT2[ , 1 ],
																				 observedAUCT2[ , 2 ],
				 																 observedAUCT2[ , 3 ],
																				 corrObsCases,
																				 corrObsNonCases,
				                                                                 numberObsCases,
																				 numberObsNonCases );

			finish;
				print 'finished defining standardAnalysis module';
			
/*   ************************************* END MODULE standardAnalysis **************************************************  */

	

/* ****************************************** biasCorrectionAnalysis MODULE DEFINITION ****************************************** */ 
/* ****************************************** 	  Bias Corrects the data 				 ************************************** */


			start biasCorrectionAnalysis;

								/*calculate the number of observed cases in each quadrant and in the first three quadrants together*/
								numberObsCasesQuadrant1 = sum( indicateObsCasesQuadrant1 );
								numberObsCasesQuadrant2 = sum( indicateObsCasesQuadrant2 );
								numberObsCasesQuadrant3 = sum( indicateObsCasesQuadrant3 );
								numberObsCasesQ123 = numberObsCasesQuadrant1 +
								                     numberObsCasesQuadrant2 +
											         numberObsCasesQuadrant3;
								numberObsCasesQuadrant4 = numberObsCases - numberObsCasesQ123;

								/*if there are < 2 observed cases quadrants 1, 2, and 3 together*/ 
								/*then return an error and do not calculate summary statistics for quadrants 1, 2, and 3*/	


								/* ***************                           *************** */
								/* *************** CALL nathInAllQuadrants MODULE *************** */ 
								/* ***************                           *************** */

								run nathInAllQuadrants;

								/*if the Nath estimates are missing for all 4 quadrants then set remaining values to missing*/
								if ( outcomeNathQuad1 ^= 0 &
				                     outcomeNathQuad2 ^= 0 &
				                     outcomeNathQuad3 ^= 0 &
				                     outcomeNathQuad4 ^= 0 ) then do;
									 nathError = 1;
									 flag = 5;

								/* ***************                           *************** */
								/* *************** CALL setErrorCodes MODULE *************** */ 
								/* ***************                           *************** */

									run setErrorCodes;

								end; /*end nath algorithm did not converge in any quadrants*/

								else do; 

									nathError = 0;
									/*combine logL with estimates*/
									nathAndLogLQ1Row = 1 || logLQ1 || nathQ1Row;
									nathAndLogLQ2Row = 2 || logLQ2 || nathQ2Row;
									nathAndLogLQ3Row = 3 || logLQ3 || nathQ3Row;
									nathAndLogLQ4Row = 4 || logLQ4 || nathQ4Row;

									/*stack quadrant nath estimates*/
									nathCandidates = nathAndLogLQ1Row // nathAndLogLQ2Row // nathAndLogLQ3Row // nathAndLogLQ4Row;

									/*pick off nath rows that have outcome = 0*/
									nathCandidatesConverged = nathCandidates[ loc( nathCandidates[ , 4 ] = 0 )`, ];
							 
									/*choose the row with the maximum log likelihood as the nath estimates*/
									nathEstimatesRow = nathCandidatesConverged[ nathCandidatesConverged[ <:>, 2 ], ];


									/*calculate bivariate probabilities based on nath estimates*/
								    bivariateNormalProbabilitiesNath = estimateBivNormProbabilities( errcode, cumErrors, cutoffs[ , 1 ], cutoffs[ , 2 ],
							                                                                         nathEstimatesRow[ , 5  ], nathEstimatesRow[ , 6 ],
							                                                                         nathEstimatesRow[ , 7 ], nathEstimatesRow[ , 8 ],
							                                                                         nathEstimatesRow[ , 9 ], &errorCode );

									/*if q123 or q4 are empty then we cannot calculate the weighted estimates*/
									/*instead, we use the nath estimates as the corrected estimates*/
									if empty123 = 1 | emptyQuad4 = 1 then do;

										weighted = 0;
										weightedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										bivNormProbsWeighted = &errorCode || &errorCode ;

										/*calculate corrected number of cases/non-cases based on bivariate probabilities*/
										correctedEstimatesRow = nathEstimatesRow[ , { 5, 6, 7, 8, 9 } ];
										correctedNumberCasesNonCases = calcCorrectedNumCasesNonCases( errcode, cumErrors, bivariateNormalProbabilitiesNath[ , 1 ], 
								            													      &sampleSize, numberObsCasesQ123 );
									end; /*end use corrected estimates*/

									/*if there are at least 2 observations in q123 AND q4 then we can calculate the weighted estimates*/
									/*we will use these estimates as the corrected estimates*/
									else do;

										weighted = 1;

										weightedEstimatesRow = calculateWeightedEstimates( bivariateNormalProbabilitiesNath[ , 1 ], 
																						   bivariateNormalProbabilitiesNath[ , 2 ],
																						   meanT1ObsCasesQ123, meanT2ObsCasesQ123, 
																						   stdT1ObsCasesQ123, stdT2ObsCasesQ123, 
																						   corrObsCasesQ123, 
																						   meanT1ObsCasesQuadrant4, meanT2ObsCasesQuadrant4, 
            																		       stdT1ObsCasesQuadrant4, stdT2ObsCasesQuadrant4, 
 																				           corrObsCasesQuadrant4 );

										correctedEstimatesRow = weightedEstimatesRow;

										
										/*recalculate bivariate normal probabilities using weighted estimates*/
								 		bivNormProbsWeighted = estimateBivNormProbabilities( errcode, cumErrors, cutoffs[ , 1 ], cutoffs[ , 2 ],
							                                                                 weightedEstimatesRow[ , 1 ], weightedEstimatesRow[ , 2 ],
							                                                                 weightedEstimatesRow[ , 3 ], weightedEstimatesRow[ , 4 ],
							                                                                 weightedEstimatesRow[ , 5 ], &errorCode );

										/*use the bivariate normal probabilities calculated from the weighted estimates to correct the number of cases*/
										correctedNumberCasesNonCases = calcCorrectedNumCasesNonCases( errcode, cumErrors, bivNormProbsWeighted[ , 1 ], 
								            													      &sampleSize, numberObsCasesQ123 );

									end; /*end use weighted estimates*/

									/*sometimes the corrected number of cases will be greater than the sample size*/
									/*this happens because the bivariate probabilties (f1, f2) are estimated with error*/
									/*if the corrected number of cases is greater than the sample size, then do not bias correct*/
									/*also, the corrected number of cases could be 0, which would blow up R in the hypothesis test*/
									/*this is bad, so return an error if this happens and do not do bias correction*/
									/*essentially, you cannot do bias correction if you have an extreme number of observed cases or non-cases*/
									if ( correctedNumberCasesNonCases[ , 1 ] > &sampleSize |
		                                 correctedNumberCasesNonCases[ , 1 ] = 0 ) then do;
									   
									   flag = 6;
									   correctedNumberCasesError = 1;
									   run setErrorCodes;
									end; /*end corrected number of cases is greater than sample size*/

									else do;

										correctedNumberCasesError = 0;	

										/*calculate corrected AUC*/
										correctedAUCT1 = calculateAUC( errcode, cumErrors, correctedEstimatesRow[ , 1 ], meanT1ObsNonCases, 
						                                               correctedEstimatesRow[ , 3 ], stdT1ObsNonCases );
										correctedAUCT2 = calculateAUC( errcode, cumErrors, correctedEstimatesRow[ , 2 ], meanT2ObsNonCases, 
						                                               correctedEstimatesRow[ , 4 ], stdT2ObsNonCases );

										correctedHypTest = differenceInAUCHypothesisTest( errcode, cumErrors, correctedAUCT1[ , 1 ], 
						 																  correctedAUCT1[ , 2 ],
						 																  correctedAUCT1[ , 3 ],
																						  correctedAUCT2[ , 1 ],
																						  correctedAUCT2[ , 2 ],
						 																  correctedAUCT2[ , 3 ],
																						  correctedEstimatesRow[ , 5 ],
																						  corrObsNonCases,
						                                                                  correctedNumberCasesNonCases[ , 1 ],
																						  correctedNumberCasesNonCases[ , 2 ] );

									end; /*end corrected number of cases is less than sample size*/
							
								end; /*end nath algorithm converged in at least one quadrant*/

			finish;
				

/*   ************************************* END MODULE biasCorrectionAnalysis **************************************************  */


/* ****************************************** decisionError MODULE DEFINITION ****************************************** */ 
/* ***********************************  Simulates the dataset and bias corrects it. *********************************** */
			

			start decisionError;
				
				/*give values to constants*/
				/*we have to assign the macro variables as local variables because the IML modules*/
				/*do not like to use macro variables as operands*/

				maxIterations = &maxIterations;
				tolerance = &tolerance;
				sampleSize = &sampleSize;

				/*free rep of value used in last iteration of vectorRow do loop*/	
				/*free experimental variable of value assigned above*/	
				free rep;

				/*set values for rep*/
				do rep = 1 to &numberOfrealizations;

						/*free variable names used in last iteration of rep do loop*/
						/*do not free variables assigned outside this do loop*/
						free / errCode cumErrors pastErrors
							   maxIterations tolerance sampleSize
			                   rep;

						use out01.example1;

						read all var _ALL_ into matrix;
						close out01.example1;

						

						cutoffs = {65 59};

						/*subset matrix into the groups*/
						/*we will then get summary statistics of the test scores in each of the groups*/

						/*first, we must make sure there is more than 1 observed case and non-case*/
						/*if not, we will not calculate any summary statistics and we will return an error*/

						/*find the locations of each observation in each of the groups*/
						/*if any of the locations are empty, write an error*/
						/*Observed cases: disease = 1 and at least one test score is above the threshold or ss = 1*/

						/*now do the observed cases and non-cases DONT NEED THOSE*/
							

						indicateObsCases = ( matrix[ , 3 ] = 1 );
						indicateObsNonCases = ( matrix[ , 3 ] = 0 );	

						/*calculate the number of observed cases*/
						numberObsCases = sum( indicateObsCases );
						numberObsNonCases = sum( indicateObsNonCases ); 

						/*if there are less than 2 observed cases or non-cases, do not calculate any summary statistics and return an error*/

						if ( numberObsCases < 2 | numberObsNonCases < 2 ) then do;
	
								obsError = 1;
								flag = 8;

								/* ***************                           *************** */
								/* *************** CALL setErrorCodes MODULE *************** */ 
								/* ***************                           *************** */

								run setErrorCodes;
						end; /*end not enough observed cases*/

						else do;

								/*print 'inside numberObsCases > 2';*/

								obsError = 0;

								run standardAnalysis;

								/*Observed cases in quadrant 1: disease = 1 and both test scores are above their thresholds*/
							    indicateObsCasesQuadrant1 = ( matrix[ , 3 ] = 1 & 
					                                          matrix[ , 1 ] >= cutoffs[ , 1 ] &
					                                          matrix[ , 2 ] >= cutoffs[ , 2 ] )`;				

								/*Observed cases in quadrant 2: disease = 1, test 1 score above threshold, test 2 score below threshold*/
							    indicateObsCasesQuadrant2 = ( matrix[ , 3 ] = 1 & 
					                                          matrix[ , 1 ] >= cutoffs[ , 1 ] &
					                                          matrix[ , 2 ] < cutoffs[ , 2 ] )`;

								/*Observed cases in quadrant 3: disease = 1, test 1 score below threshold, test 2 score above threshold*/
							    indicateObsCasesQuadrant3 = ( matrix[ , 3 ] = 1 & 
					                                          matrix[ , 1 ] < cutoffs[ , 1 ] &
					                                          matrix[ , 2 ] >= cutoffs[ , 2 ] )`;

								/*Observed cases in quadrant 4: disease = 1, test 1 score below threshold, test 2 score below threshold, ss = 1*/
							    indicateObsCasesQuadrant4 = ( matrix[ , 3 ] = 1 & 
						                                      matrix[ , 1 ] < cutoffs[ , 1 ] &
						                                      matrix[ , 2 ] < cutoffs[ , 2 ] )`;


								/* ***************                           *************** */
								/* ********** CALL biasCorrectionAnalysis MODULE *************** */ 
								/* ***************                           *************** */

								run biasCorrectionAnalysis;

						end; /*end enough observed cases/non-cases*/

/* ************************************ Create a matrix to display results ******************************************************** */         


						output =    rep || obsError || nathError || weighted || correctedNumberCasesError || 
									hypErrorObserved || hypErrorCorrected ||
								    empty123 || emptyQuad1 || emptyQuad2 || emptyQuad3 || emptyQuad4 ||

									cutoffs || 

									maxIterations || tolerance || sampleSize ||

							        numberObsCases ||
					                meanT1ObsCases || meanT2ObsCases || 
							        stdT1ObsCases || stdT2ObsCases ||
								    corrObsCases ||

							        numberObsNonCases ||
					                meanT1ObsNonCases || meanT2ObsNonCases || 
					                stdT1ObsNonCases || stdT2ObsNonCases ||
								    corrObsNonCases ||

							        numberObsCasesQuadrant1 ||
					                meanT1ObsCasesQuadrant1 || meanT2ObsCasesQuadrant1 ||
							        stdT1ObsCasesQuadrant1 || stdT2ObsCasesQuadrant1 ||
							        corrObsCasesQuadrant1 ||

							        numberObsCasesQuadrant2 ||
					                meanT1ObsCasesQuadrant2 || meanT2ObsCasesQuadrant2 ||
							        stdT1ObsCasesQuadrant2 || stdT2ObsCasesQuadrant2 ||
							        corrObsCasesQuadrant2 || 

							        numberObsCasesQuadrant3 || 
					                meanT1ObsCasesQuadrant3 || meanT2ObsCasesQuadrant3 ||
							        stdT1ObsCasesQuadrant3 || stdT2ObsCasesQuadrant3 ||
							        corrObsCasesQuadrant3 || 

							        numberObsCasesQuadrant4 ||
					                meanT1ObsCasesQuadrant4 || meanT2ObsCasesQuadrant4 ||
							        stdT1ObsCasesQuadrant4 || stdT2ObsCasesQuadrant4 ||
							        corrObsCasesQuadrant4 || 

							        numberObsCasesQ123 ||
					                meanT1ObsCasesQ123 || meanT2ObsCasesQ123 ||
							        stdT1ObsCasesQ123 || stdT2ObsCasesQ123 ||
							        corrObsCasesQ123 || 

									outcomeNathQuad1 || outcomeNathQuad2 || outcomeNathQuad3 || outcomeNathQuad4 ||

									nathEstimatesRow ||

									bivariateNormalProbabilitiesNath || bivNormProbsWeighted ||

								    correctedNumberCasesNonCases ||

								    weightedEstimatesRow ||

								    correctedEstimatesRow ||

				                    observedAUCT1 || observedAUCT2 || observedHypTest ||
				                    correctedAUCT1 || correctedAUCT2 || correctedHypTest;

						errorsThisRep = cumErrors - pastErrors;

						if errorsThisRep >= 1 then resumeError = 1;
							else resumeError = 0;

						pastErrors = cumErrors;

						/* The output matrix should have 163 columns (one row per rep) */
						/* If there are not 163 columns, then add enough columns to make it 163 */
						/* This is done so the output row can be appended to the previous output row, even if there was an error during the current iteration*/

						numColumns = ncol(output);
						print numColumns;

						if ( ncol( output ) ^= 108 ) then do;
								columnError = 1;
								additionalColumnsNeeded = 108 - ncol( output );
								addColumns = j( 1, additionalColumnsNeeded, &errorCode );
								results = output || addColumns || columnError || additionalColumnsNeeded || 
                                      resumeError || errorsThisRep || cumErrors;
						end;

						else do;
								results = output || 0 || 0 || resumeError || errorsThisRep || cumErrors;
						end;


						/* **************************** Open dataset to edit ************************************** */

						edit out01.results;

						append from results; 
			
						close out01.results;  
  
					end; /*end repetition loop*/

				cumErrors = -1;

			finish; /* finish decisionError module */

/***********************************************************************************************************/
			
			run decisionError;

		finish main; /* finish main */

		run; /* run main */

	quit;

%mend;

