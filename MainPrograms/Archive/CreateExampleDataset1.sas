*Output example dataset to be used to test the DecisionErrorSimulator module;

/*  *******************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/12/11
 
----------------------------------------------------------------------------------------------------------------
									DESCRIPTION OF SIMULATOR
----------------------------------------------------------------------------------------------------------------

The DecisionErrorSimulator module corrects the AUC for randomly generated binormal data. The motivating 
example is a screening population where the sample consists of cases and non-cases.  There 
are two screening test scores associated with each participant.  The means, variances, and 
correlations of the test scores are conditional on whether the participant is a case or a 
non-case.

The DecisionErrorSimulator defines three submodules, as briefly described below: 

completeAnalysis: performs the complete (or true) analysis,
standardAnalysis: performs the standard (or observed) analysis, and 
biasCorrectionAnalysis: performs the (bias) corrected analysis.

In addition to the three analysis submodule listed above, the DecisioErrorSimulator also defines two other submodules, as described below:

setErrorCodes: sets error codes for several parameters based on the results of the performed analysis and 
emptyQuadrants: checks if the quadrants are empty.

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

%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas";
%CommonMain( CreateExampleDataset, CreateExampleDataset ); 

/* **************************** DecisionErrorSimulator MACRO DEFINITION  *********************************************************************** */
/* *************************************************************************************************** */
 

%macro DecisionErrorSimAndExDatasets( seed, errorCode, numberOfrealizations, sampleSize, tolerance, maxIterations, meanOfTest1ScoresCases, meanOfTest2ScoresCases, stdOfTest1ScoresCases, stdOfTest2ScoresCases, correlationT1T2ForCases, meanOfTest1ScoresNonCases,
                         meanOfTest2ScoresNonCases, stdOfTest1ScoresNonCases, stdOfTest2ScoresNonCases, correlationT1T2ForNonCases, diseasePrevalence, cutOffT1T2, rateOfSignsSymptoms, changer, vector ) / store source; 

%let counter = 0;
%put "before" &counter;

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
		vectorRow						length = 8 label = "Experimental Variable Index" 
		trueError						length = 8 label = "Less than 2 cases or non-cases"
		obsError						length = 8 label = "Less than 2 observed cases or non-cases"
		nathError						length = 8 label = "Nath algorithm did not converge in any quadrant"
		weighted						length = 8 label = "Source of corrected estimates (1 = weighted, 0 = nath )"
		correctedNumberCasesError		length = 8 label = "Corrected Number of Cases Exceeded Total Sample Size"
		hypErrorComplete				length = 8 label = "Population Delta AUC = 0 But Observed Hypothesis Test Rejects"
		hypErrorObserved				length = 8 label = "Population Delta AUC = 0 But Observed Hypothesis Test Rejects"
		hypErrorCorrected				length = 8 label = "Population Delta AUC = 0 But Corrected Hypothesis Test Rejects"
		empty123						length = 8 label = "Less than 2 observed cases in quadrants 1, 2, and 3 together"
		emptyQuad1						length = 8 label = "Less than 2 observed cases in quadrant 1"
		emptyQuad2						length = 8 label = "Less than 2 observed cases in quadrant 2"
		emptyQuad3						length = 8 label = "Less than 2 observed cases in quadrant 3"
		emptyQuad4						length = 8 label = "Less than 2 observed cases in quadrant 4"
		diseasePrevalence				length = 8 label = "Disease Prevalence"
		rateSignsSymptoms				length = 8 label = "Rate of Signs and Symptoms"
		cutoffTest1						length = 8 label = "Cutoff for Test 1"
		cutoffTest2						length = 8 label = "Cutoff for Test 2"
		populationRhoCases				length = 8 label = "True Value of Rho for Cases"
		populationRhoNonCases			length = 8 label = "True Value of Rho for Non-Cases"
		nathMaxIterations				length = 8 label = "Maximum Number of Iterations for Nath Algorithm"
		nathTolerance					length = 8 label = "Tolerance for Nath Algorithm"
		sampleSize						length = 8 label = "Sample Size"
		populationMu1Cases				length = 8 label = "True Value of Mu1 for Cases"
		populationMu2Cases				length = 8 label = "True Value of Mu2 for Cases"
		populationMu1NonCases			length = 8 label = "True Value of Mu1 for Non-Cases"
		populationMu2NonCases			length = 8 label = "True Value of Mu2 for Non-Cases"
		populationSig1Cases				length = 8 label = "True Value of Sigma1 for Cases"
		populationSig2Cases				length = 8 label = "True Value of Sigma2 for Cases"
		populationSig1NonCases			length = 8 label = "True Value of Sigma1 for Non-Cases"
		populationSig2NonCases			length = 8 label = "True Value of Sigma2 for Non-Cases"
		quadrantContainingMLECases		length = 8 label = "Quadrant Containing the MLE for Cases"
	    quadrantContainingMLENonCases	length = 8 label = "Quadrant Containing the MLE for Non-Cases"
		numberCases						length = 8 label = "Number of True Cases"
		meanT1Cases						length = 8 label = "Test 1 Mean for True Cases"
	    meanT2Cases         			length = 8 label = "Test 2 Mean for True Cases"
	    stdT1Cases          			length = 8 label = "Test 1 Standard Deviation for True Cases"
	    stdT2Cases						length = 8 label = "Test 2 Standard Deviation for True Cases"
	    corrCases						length = 8 label = "Correlation Between True Cases"
		numberNonCases					length = 8 label = "Number of True Non-Cases"
		meanT1NonCases					length = 8 label = "Test 1 Mean for True Non-Cases"
	    meanT2NonCases         			length = 8 label = "Test 2 Mean for True Non-Cases"
	    stdT1NonCases          			length = 8 label = "Test 1 Standard Deviation for True Non-Cases"
	    stdT2NonCases					length = 8 label = "Test 2 Standard Deviation for True Non-Cases"
	    corrNonCases					length = 8 label = "Correlation Between True Non-Cases"
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
		posT1SSGoldStd					length = 8 label = "Proportion of Cases That Screen Positive on Test 1 or Screen Negative on Both Tests and Show Signs and Symptoms"
		posT2SSGoldStd					length = 8 label = "Proportion of Cases That Screen Positive on Test 2 or Screen Negative on Both Tests and Show Signs and Symptoms"
		GoldStd							length = 8 label = "Proportion of Cases That Receive the Gold Standard For Any Reason"
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
		populationAUCT1ParmA			length = 8 label = "Parameter A for Test 1 Binormal AUC Calculated From Population (True) Values"
		populationAUCT1ParmB			length = 8 label = "Parameter B for Test 1 Binormal AUC Calculated From Population (True) Values"
		populationAUCT1					length = 8 label = "Test 1 AUC Calculated From Population (True) Values"
		populationAUCT2ParmA			length = 8 label = "Parameter A for Test 2 Binormal AUC Calculated From Population (True) Values"
		populationAUCT2ParmB			length = 8 label = "Parameter B for Test 2 Binormal AUC Calculated From Population (True) Values"
		populationAUCT2					length = 8 label = "Test 2 AUC Calculated From Population (True) Values"
		populationDeltaAUC				length = 8 label = "Difference in AUC (Test 1 - Test 2) Calculated From Population (True) Values"
		completeAUCT1ParmA				length = 8 label = "Parameter A for Test 1 Binormal AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeAUCT1ParmB				length = 8 label = "Parameter B for Test 1 Binormal AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeAUCT1					length = 8 label = "Test 1 AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeAUCT2ParmA				length = 8 label = "Parameter A for Test 2 Binormal AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeAUCT2ParmB				length = 8 label = "Parameter B for Test 2 Binormal AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeAUCT2					length = 8 label = "Test 2 AUC Calculated Assuming Complete Disease Status Ascertainment"
		completeDeltaAUC				length = 8 label = "Difference in AUC (Test 1 - Test 2) Calculated Assuming Complete Disease Status Ascertainment"
		completeSEDeltaAUC				length = 8 label = "Standard Error of the Difference in AUC Assuming Complete Disease Status Ascertainment"
		completeZDeltaAUC				length = 8 label = "Z Value for Delta AUC Hypothesis Test Assuming Complete Disease Status Ascertainment"
		completePDeltaAUC				length = 8 label = "P Value for Delta AUC Hypothesis Test Assuming Complete Disease Status Ascertainment"
		completeReject					length = 8 label = "Indicator that Delta AUC Hypothesis Test Assuming Complete Disease Status Ascertainment Rejected (1 = reject, 0 = fail to reject)"
		directionCompleteHypTest		length = 8 label = "Indicator for Direction of Rejection of Complete Hypothesis Test (0 = fail, 1 = correct, -1 = reverse)"
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
		bias							length = 8 label = "Bias"
		directionObservedHypTest		length = 8 label = "Indicator for Direction of Rejection of Observed Hypothesis Test (0 = fail, 1 = correct, -1 = reverse)"
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
		uncorrectedBias					length = 8 label = "Uncorrected bias"
		directionCorrectedHypTest		length = 8 label = "Indicator for Direction of Rejection of Corrected Hypothesis Test (0 = fail, 1 = correct, -1 = reverse)"
		additionalColumnsNeeded			length = 8 label = "Number of empty columns added to the row to make the matrix conform - if this number is anything but 0 DO NOT USE ROW"
		columnError						length = 8 label = "1 = program errored out and dummy columns were created, 0 = no errors that required dummy columns"
		resumeError						length = 8 label = "1 = program errored out and resumed without resolving error, 0 = no resume error"
		errorsThisRep					length = 8 label = "Number of errors ignored for the current iteration"
		cumErrors						length = 8 label = "Cumulative number of errors ignored during program";
	
/*		flag  							length = 8 label = "Flag to check error condition in the setErrorCodes module";*/

		if _n_= 1 then delete;

	run;

	reset log print;

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

				else if ((numberCases < 2 | numberNonCases < 2) & flag = 7) then do;
									obsError = &errorCode;
									correctedNumberCasesError = &errorCode;
									empty123 = &errorCode;
									emptyQuad1 = &errorCode;
									emptyQuad2 = &errorCode;
									emptyQuad3 = &errorCode;
									emptyQuad4 = &errorCode;
									meanT1Cases = &errorCode;
									meanT2Cases = &errorCode;
									stdT1Cases = &errorCode;
									stdT2Cases = &errorCode;
									corrCases = &errorCode;
									meanT1NonCases = &errorCode;
									meanT2NonCases = &errorCode;
									stdT1NonCases = &errorCode;
									stdT2NonCases = &errorCode;
									corrNonCases = &errorCode;
									numberObsCases = &errorCode;
									meanT1ObsCases = &errorCode;
									meanT2ObsCases = &errorCode;
									stdT1ObsCases = &errorCode;
									stdT2ObsCases = &errorCode;
									corrObsCases = &errorCode;
									numberObsNonCases = &errorCode;
									meanT1ObsNonCases = &errorCode;
									meanT2ObsNonCases = &errorCode;
									stdT1ObsNonCases = &errorCode;
									stdT2ObsNonCases = &errorCode;
									corrObsNonCases = &errorCode;
									posT1SSGoldStd = &errorCode;	
									posT2SSGoldStd = &errorCode;	
									GoldStd = &errorCode;
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
									nathEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									bivariateNormalProbabilitiesNath = &errorCode || &errorCode ;
									bivNormProbsWeighted = &errorCode || &errorCode ;
									correctedNumberCasesNonCases = &errorCode || &errorCode ;
						   		 	weightedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
						    		weighted = &errorCode;
				            		correctedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;	
									completeAUCT1 = &errorCode || &errorCode || &errorCode ;
									completeAUCT2 = &errorCode || &errorCode || &errorCode ;
									completeHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									hypErrorComplete = &errorCode ;
									directionCompleteHypTest = &errorCode ;
									observedAUCT1 = &errorCode || &errorCode || &errorCode ;
									observedAUCT2 = &errorCode || &errorCode || &errorCode ;
									observedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									bias = &errorCode;
									hypErrorObserved = &errorCode ;
									directionObservedHypTest = &errorCode ;
									correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
									correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
									correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									uncorrectedBias = &errorCode;
									hypErrorCorrected = &errorCode ;
									directionCorrectedHypTest = &errorCode ;
				end; /*end not enough true cases*/

				/*if there are less than 2 observed cases or non-cases, do not calculate any summary statistics and return an error*/
				else if ( (numberObsCases < 2 | numberObsNonCases < 2) & flag = 8 ) then do;
								correctedNumberCasesError = &errorCode;
								empty123 = &errorCode;
								emptyQuad1 = &errorCode;
								emptyQuad2 = &errorCode;
								emptyQuad3 = &errorCode;
								emptyQuad4 = &errorCode;
								meanT1Cases = &errorCode;
								meanT2Cases = &errorCode;
								stdT1Cases = &errorCode;
								stdT2Cases = &errorCode;
								corrCases = &errorCode;
								meanT1NonCases = &errorCode;
								meanT2NonCases = &errorCode;
								stdT1NonCases = &errorCode;
								stdT2NonCases = &errorCode;
								corrNonCases = &errorCode;
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
								posT1SSGoldStd = &errorCode;	
								posT2SSGoldStd = &errorCode;	
								GoldStd = &errorCode;
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
								completeAUCT1 = &errorCode || &errorCode || &errorCode ;
								completeAUCT2 = &errorCode || &errorCode || &errorCode ;
								completeHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								hypErrorComplete = &errorCode ;
								directionCompleteHypTest = &errorCode ;
								observedAUCT1 = &errorCode || &errorCode || &errorCode ;
								observedAUCT2 = &errorCode || &errorCode || &errorCode ;
								observedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								bias = &errorcode;
								hypErrorObserved = &errorCode ;
								directionObservedHypTest = &errorCode ;
								correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
								correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
								correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								uncorrectedBias = &errorCode;
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




/* ****************************************** emptyQuadrants MODULE DEFINITION ****************************************** */ 
/* *****   Checks to see if the quadrants are empty. If so, calculates summary stats for only non-empty quadrants. ***** */

			start emptyQuadrants;


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
							meanT1ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 4 ] );
							meanT2ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 5 ] );
							covMatrixObsCasesQuadrant4 = cov( obsCasesQuadrant4[ , 4 ] || obsCasesQuadrant4[ , 5 ] );

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
							meanT1ObsCasesQ123 = mean( obsCasesQ123[ , 4 ] );
							meanT2ObsCasesQ123 = mean( obsCasesQ123[ , 5 ] );
							covMatrixObsCasesQ123 = cov( obsCasesQ123[ , 4 ] || obsCasesQ123[ , 5 ] );

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
									meanT1ObsCasesQuadrant1 = mean( obsCasesQuadrant1[ , 4 ] );
									meanT2ObsCasesQuadrant1 = mean( obsCasesQuadrant1[ , 5 ] );
									covMatrixObsCasesQuadrant1 = cov( obsCasesQuadrant1[ , 4 ] || obsCasesQuadrant1[ , 5 ] );

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
									meanT1ObsCasesQuadrant2 = mean( obsCasesQuadrant2[ , 4 ] );
									meanT2ObsCasesQuadrant2 = mean( obsCasesQuadrant2[ , 5 ] );
									covMatrixObsCasesQuadrant2 = cov( obsCasesQuadrant2[ , 4 ] || obsCasesQuadrant2[ , 5 ] );

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
									meanT1ObsCasesQuadrant3 = mean( obsCasesQuadrant3[ , 4 ] );
									meanT2ObsCasesQuadrant3 = mean( obsCasesQuadrant3[ , 5 ] );
									covMatrixObsCasesQuadrant3 = cov( obsCasesQuadrant3[ , 4 ] || obsCasesQuadrant3[ , 5 ] );

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
									meanT1ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 4 ] );
									meanT2ObsCasesQuadrant4 = mean( obsCasesQuadrant4[ , 5 ] );
									covMatrixObsCasesQuadrant4 = cov( obsCasesQuadrant4[ , 4 ] || obsCasesQuadrant4[ , 5 ] );

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
			
/*   ************************************* END MODULE emptyQuadrants **************************************************  */


	

/* ****************************************** completeAnalysis MODULE DEFINITION ****************************************** */ 
/* ****************************************** Performs Complete Analysis on the data ************************************** */
																		

			start completeAnalysis;


								/*find mean, std, corr of true cases*/
								meanT1Cases = mean( cases[ , 4 ] );

								meanT2Cases = mean( cases[ , 5 ] );
								sampleCovMatrixCases = cov( cases[ , 4 ] || cases[ , 5 ] );

								stdT1Cases = sqrt( sampleCovMatrixCases[ 1, 1 ] );
								stdT2Cases = sqrt( sampleCovMatrixCases[ 2, 2 ] );

								/*use only element 12 of the 2 x 2 covariance matrix*/
								corrCases = sampleCovMatrixCases[ 1, 2 ] / stdT1Cases / stdT2Cases;
								

								/*find mean, std, corr of true non-cases*/
								meanT1NonCases = mean( nonCases[ , 4 ] );
								meanT2NonCases = mean( nonCases[ , 5 ] );
								sampleCovMatrixNonCases = cov( nonCases[ , 4 ] || nonCases[ , 5 ] );

								stdT1NonCases = sqrt( sampleCovMatrixNonCases[ 1, 1 ] );
								stdT2NonCases = sqrt( sampleCovMatrixNonCases[ 2, 2 ] );

								/*use only element 12 of the 2 x 2 covariance matrix*/
								corrNonCases = sampleCovMatrixNonCases[ 1, 2 ] / stdT1NonCases / stdT2NonCases;


								/*calculate AUC with complete disease status ascertainment*/
								completeAUCT1 = calculateAUC( errcode, cumErrors, meanT1Cases, meanT1NonCases, stdT1Cases, stdT1NonCases );
								completeAUCT2 = calculateAUC( errcode, cumErrors, meanT2Cases, meanT2NonCases, stdT2Cases, stdT2NonCases );
								completeHypTest = differenceInAUCHypothesisTest( errcode, cumErrors, completeAUCT1[ , 1 ], 
				 																 completeAUCT1[ , 2 ],
				 																 completeAUCT1[ , 3 ],
																				 completeAUCT2[ , 1 ],
																				 completeAUCT2[ , 2 ],
				 																 completeAUCT2[ , 3 ],
																				 corrCases,
																				 corrNonCases,
				                                                                 numberCases,
																				 numberNonCases );

								/*check direction of rejection against population difference in AUC*/	
								if completeHypTest[ , 5 ] = 1 then do;

									/*if the population difference is 0 but the comp/obs/corr rejects then mark the direction of rejection as a 1*/
									/*also return an error so this kind of rejection can be separated from other kinds*/
									if populationDeltaAUC = 0 then do;
										hypErrorComplete = 1;
										directionCompleteHypTest = 1;
									end;

									/*if the population difference has the same sign as the comp/obs/corr difference then the tests are in the same order*/
									/*this is a rejection in the correct direction*/
									else if ( populationDeltaAUC < 0 & completeHypTest[ , 1 ] < 0 ) |
					                        ( populationDeltaAUC > 0 & completeHypTest[ , 1 ] > 0 ) then do;
										hypErrorComplete = 0;
										directionCompleteHypTest = 1;
									end;

									/*if the population difference has the opposite sign as the comp/obs/corr difference then the tests are in the wrong order*/
									/*this is a rejection in the wrong or reverse direction*/
									else if ( populationDeltaAUC < 0 & completeHypTest[ , 1 ] > 0 ) |
								            ( populationDeltaAUC > 0 & completeHypTest[ , 1 ] < 0 ) then do;
										hypErrorComplete = 0;
										directionCompleteHypTest = -1;
									end;

								end; /*end complete hyp test rejected*/

								/*if the comp/obs/corr hyp test did not reject then set the direction of rejection to 0*/
								else do;
									hypErrorComplete = 0;
									directionCompleteHypTest = 0;
								end; /*end complete hyp test failed to reject*/		


			finish;
				
			
/*   ************************************* END MODULE completeAnalysis **************************************************  */


	

/* ****************************************** standardAnalysis MODULE DEFINITION ****************************************** */ 
/* ****************************************** Performs Standard Analysis on the data ************************************** */


			start standardAnalysis;

				print 'Entering standardAnalysis module';

								/*now do the observed cases and non-cases*/
								obsCases = matrix[ loc( indicateObsCases )`, ];
								obsNonCases = matrix[ loc( indicateObsNonCases )`, ];

								/*find mean, std, corr*/
								/*cases*/
								meanT1ObsCases = mean( obsCases[ , 4 ] );
								meanT2ObsCases = mean( obsCases[ , 5 ] );
								covMatrixObsCases = cov( obsCases[ , 4 ] || obsCases[ , 5 ] );

								stdT1ObsCases = sqrt( covMatrixObsCases[ 1, 1 ] );
								stdT2ObsCases = sqrt( covMatrixObsCases[ 2, 2 ] );

								/*use only element 12 of the 2 x 2 covariance matrix*/
								corrObsCases = covMatrixObsCases[ 1, 2 ] / stdT1ObsCases / stdT2ObsCases;

								/*non-cases*/
								meanT1ObsNonCases = mean( obsNonCases[ , 4 ] );
								meanT2ObsNonCases = mean( obsNonCases[ , 5 ] );
								covMatrixObsNonCases = cov( obsNonCases[ , 4 ] || obsNonCases[ , 5 ] );

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

								/*calculate bias in difference in AUC*/
								if observedHypTest[ , 1 ] ^= &errorCode then bias = observedHypTest[ , 1 ] - completeHypTest[ , 1 ];
									else bias = &errorCode;

								/*check direction of rejection against population difference in AUC*/	
								if observedHypTest[ , 5 ] = 1 then do;

									/*if the population difference is 0 but the comp/obs/corr rejects then mark the direction of rejection as a 1*/
									/*also return an error so this kind of rejection can be separated from other kinds*/
									if populationDeltaAUC = 0 then do;
										hypErrorObserved = 1;
										directionObservedHypTest = 1;
									end;

									/*if the population difference has the same sign as the comp/obs/corr difference then the tests are in the same order*/
									/*this is a rejection in the correct direction*/
									else if ( populationDeltaAUC < 0 & observedHypTest[ , 1 ] < 0 ) |
					                        ( populationDeltaAUC > 0 & observedHypTest[ , 1 ] > 0 ) then do;
										hypErrorObserved = 0;
										directionObservedHypTest = 1;
									end;

									/*if the population difference has the opposite sign as the comp/obs/corr difference then the tests are in the wrong order*/
									/*this is a rejection in the wrong or reverse direction*/
									else if ( populationDeltaAUC < 0 & observedHypTest[ , 1 ] > 0 ) |
								            ( populationDeltaAUC > 0 & observedHypTest[ , 1 ] < 0 ) then do;
										hypErrorObserved = 0;
										directionObservedHypTest = -1;
									end;

								end; /*end obs hyp test rejected*/

								/*if the comp/obs/corr hyp test did not reject then set the direction of rejection to 0*/
								else do;
									hypErrorObserved = 0;
									directionObservedHypTest = 0;
								end; /*end obs hyp test failed to reject*/

								/*Observed cases in quadrant 1: disease = 1 and both test scores are above their thresholds*/
							    indicateObsCasesQuadrant1 = ( matrix[ , 2 ] = 1 & 
					                                          matrix[ , 4 ] >= cutoffs[ , 1 ] &
					                                          matrix[ , 5 ] >= cutoffs[ , 2 ] )`;				

								/*Observed cases in quadrant 2: disease = 1, test 1 score above threshold, test 2 score below threshold*/
							    indicateObsCasesQuadrant2 = ( matrix[ , 2 ] = 1 & 
					                                          matrix[ , 4 ] >= cutoffs[ , 1 ] &
					                                          matrix[ , 5 ] < cutoffs[ , 2 ] )`;

								/*Observed cases in quadrant 3: disease = 1, test 1 score below threshold, test 2 score above threshold*/
							    indicateObsCasesQuadrant3 = ( matrix[ , 2 ] = 1 & 
					                                          matrix[ , 4 ] < cutoffs[ , 1 ] &
					                                          matrix[ , 5 ] >= cutoffs[ , 2 ] )`;

								/*Observed cases in quadrant 4: disease = 1, test 1 score below threshold, test 2 score below threshold, ss = 1*/
							    indicateObsCasesQuadrant4 = ( matrix[ , 2 ] = 1 & 
						                                      matrix[ , 4 ] < cutoffs[ , 1 ] &
						                                      matrix[ , 5 ] < cutoffs[ , 2 ] &
						                                      matrix[ , 3 ] = 1 )`;

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
								/* *************** CALL emptyQuadrants MODULE *************** */ 
								/* ***************                           *************** */


								run emptyQuadrants;

								/*if the Nath estimates are missing for all 4 quadrants then set remaining values to missing*/
								if ( outcomeNathQuad1 ^= 0 &
				                     outcomeNathQuad2 ^= 0 &
				                     outcomeNathQuad3 ^= 0 &
				                     outcomeNathQuad4 ^= 0 ) then do;
									print 'Found NATH ERROR';
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

										/*calculate uncorrected bias in the difference in AUCs*/;
										if correctedHypTest[ , 1 ] ^= &errorCode then uncorrectedBias = correctedHypTest[ , 1 ] - completeHypTest[ , 1 ];
											else uncorrectedBias = &errorCode;

										/*check direction of rejection against population difference in AUC*/	
										if correctedHypTest[ , 5 ] = 1 then do;

											/*if the population difference is 0 but the comp/obs/corr rejects then mark the direction of rejection as a 1*/
											/*also return an error so this kind of rejection can be separated from other kinds*/
											if populationDeltaAUC = 0 then do;
												hypErrorCorrected = 1;
												directionCorrectedHypTest = 1;
											end;

											/*if the population difference has the same sign as the comp/obs/corr difference then the tests are in the same order*/
											/*this is a rejection in the correct direction*/
											else if ( populationDeltaAUC < 0 & correctedHypTest[ , 1 ] < 0 ) |
							                        ( populationDeltaAUC > 0 & correctedHypTest[ , 1 ] > 0 ) then do;
												hypErrorCorrected = 0;
												directionCorrectedHypTest = 1;
											end;

											/*if the population difference has the opposite sign as the comp/obs/corr difference then the tests are in the wrong order*/
											/*this is a rejection in the wrong or reverse direction*/
											else if ( populationDeltaAUC < 0 & correctedHypTest[ , 1 ] > 0 ) |
										            ( populationDeltaAUC > 0 & correctedHypTest[ , 1 ] < 0 ) then do;
												hypErrorCorrected = 0;
												directionCorrectedHypTest = -1;
											end;

										end; /*end corrected hypothesis test rejected*/

										/*if the comp/obs/corr hyp test did not reject then set the direction of rejection to 0*/
										else do;
											hypErrorCorrected = 0;
											directionCorrectedHypTest = 0;
										end; /*end corrected hypothesis test failed to reject*/

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
				meanOfTest1ScoresCases = &meanOfTest1ScoresCases;
				meanOfTest2ScoresCases = &meanOfTest2ScoresCases;
				meanOfTest1ScoresNonCases = &meanOfTest1ScoresNonCases;
				meanOfTest2ScoresNonCases = &meanOfTest2ScoresNonCases;
				stdOfTest1ScoresCases = &stdOfTest1ScoresCases;
				stdOfTest2ScoresCases = &stdOfTest2ScoresCases;
				stdOfTest1ScoresNonCases = &stdOfTest1ScoresNonCases;
				stdOfTest2ScoresNonCases = &stdOfTest2ScoresNonCases;

				/*give values to experimental variables*/
				/*note: we will overwrite the experimental variable(s) with new values*/
				rateSignsSymptoms = &rateOfSignsSymptoms;
				diseasePrevalence = &diseasePrevalence;
				cutoffs = &cutOffT1T2;
				populationRhoCases = &correlationT1T2ForCases;
				populationRhoNonCases = &correlationT1T2ForNonCases;

				/*calculate true AUCs and difference in AUCs*/
				populationAUCT1 = calculateAUC( errCode, cumErrors, meanOfTest1ScoresCases, meanOfTest1ScoresNonCases, stdOfTest1ScoresCases, stdOfTest1ScoresNonCases ); 
				populationAUCT2 = calculateAUC( errcode, cumErrors, meanOfTest2ScoresCases, meanOfTest2ScoresNonCases, stdOfTest2ScoresCases, stdOfTest2ScoresNonCases );
				populationDeltaAUC = populationAUCT1[ , 3 ] - populationAUCT2[ , 3 ];

				/*find the quadrant containing the MLE for cases and non-cases*/
				if &meanOfTest1ScoresCases >= cutoffs[ , 1 ] & &meanOfTest2ScoresCases >= cutoffs[ , 2 ] then quadrantContainingMLECases = 1;
					else if &meanOfTest1ScoresCases >= cutoffs[ , 1 ] & &meanOfTest2ScoresCases < cutoffs[ , 2 ] then quadrantContainingMLECases = 2;
						else if &meanOfTest1ScoresCases < cutoffs[ , 1 ] & &meanOfTest2ScoresCases >= cutoffs[ , 2 ] then quadrantContainingMLECases = 3;
							else quadrantContainingMLECases = 4;

				if &meanOfTest1ScoresNonCases >= cutoffs[ , 1 ] & &meanOfTest2ScoresNonCases >= cutoffs[ , 2 ] then quadrantContainingMLENonCases = 1;
					else if &meanOfTest1ScoresNonCases >= cutoffs[ , 1 ] & &meanOfTest2ScoresNonCases < cutoffs[ , 2 ] then quadrantContainingMLENonCases = 2;
						else if &meanOfTest1ScoresNonCases < cutoffs[ , 1 ] & &meanOfTest2ScoresNonCases >= cutoffs[ , 2 ] then quadrantContainingMLENonCases = 3;
							else quadrantContainingMLENonCases = 4;

				/*create a vector of parameter values to loop through*/
				ncat = nrow( &vector );

				/*loop through parameter values for the experimental variable*/
				do vectorRow = 1 to ncat by 1;

					/*free rep of value used in last iteration of vectorRow do loop*/	
					/*free experimental variable of value assigned above*/	
					free rep &changer;

					/*set current value for variable that changes*/
					&changer = &vector[ vectorRow, ];

					/*set values for rep*/
					do rep = 1 to &numberOfrealizations;

						/*free variable names used in last iteration of rep do loop*/
						/*do not free variables assigned outside this do loop*/
						free / errCode cumErrors pastErrors
							   maxIterations tolerance sampleSize
			                   meanOfTest1ScoresCases meanOfTest2ScoresCases meanOfTest1ScoresNonCases meanOfTest2ScoresNonCases stdOfTest1ScoresCases stdOfTest2ScoresCases stdOfTest1ScoresNonCases stdOfTest2ScoresNonCases
							   rateSignsSymptoms diseasePrevalence cutoffs populationRhoCases populationRhoNonCases 
							   populationAUCT1 populationAUCT2 populationDeltaAUC quadrantContainingMLECases quadrantContainingMLENonCases
							   ncat vectorRow rep &changer;

						/*generate binormal data*/
						/*make a matrix with id disease t1score t2score and signs and symptoms in it*/
						/*set a seed for random number generator calls*/
						call randseed( &seed, 0 );

						/*generates a random number of cases from a binomial distribution with n = sample size and p = prevalence*/
						call randgen( numberCases, 'BINOM', diseasePrevalence, &sampleSize );

						numberNonCases = &sampleSize - numberCases;


						if numberCases < 2 | numberNonCases < 2 then do;
							print 'inside numberCases < 2';
							trueError = 1;
							flag = 7;

							/* ***************                           *************** */
							/* *************** CALL setErrorCodes MODULE *************** */ 
							/* ***************                           *************** */

							run setErrorCodes;
						end; /*end not enough true cases*/

						else do;
				
							trueError = 0;

							/*matrix of participant ids*/
							id = ( 1:&sampleSize )`;

							/*create matrices of indicators for case or non-case*/
							/*create a matrix of 1 with length equal to the number of cases*/
							casesDisease = j( numberCases, 1, 1 );

							/*create a matrix of 0's of length equal to the sample size - number of cases*/
							nonCasesDisease = j( numberNonCases, 1, 0 );

							/*create disease index matrix*/
							disease = casesDisease // nonCasesDisease;

							/*generate binormal test scores for cases and non-cases*/
							/*cases*/
							meanCases = { &meanOfTest1ScoresCases &meanOfTest2ScoresCases };
							rhoMatrixCases = { 1 &correlationT1T2ForCases, &correlationT1T2ForCases 1 };
							sigmaMatrixCases = { &stdOfTest1ScoresCases &stdOfTest2ScoresCases };
							covMatrixCases = rhoMatrixCases # ( sigmaMatrixCases` * sigmaMatrixCases );
							scoreMatrixCases = randnormal( numberCases, meanCases, covMatrixCases );
							t1scoreCases = scoreMatrixCases[ , 1 ]; 
							t2scoreCases = scoreMatrixCases[ , 2 ];
						
							/*non-cases*/
							meanNonCases = { &meanOfTest1ScoresNonCases &meanOfTest2ScoresNonCases };
							rhoMatrixNonCases = { 1 &correlationT1T2ForNonCases, &correlationT1T2ForNonCases 1 };
							sigmaMatrixNonCases = { &stdOfTest1ScoresNonCases &stdOfTest2ScoresNonCases };
							covMatrixNonCases = rhoMatrixNonCases # ( sigmaMatrixNonCases` * sigmaMatrixNonCases );
							scoreMatrixNonCases = randnormal( numberNonCases, meanNonCases, covMatrixNonCases );
							t1scoreNonCases = scoreMatrixNonCases[ , 1 ]; 
							t2scoreNonCases = scoreMatrixNonCases[ , 2 ];

							/*combine score matrices*/	
							t1score = t1scoreCases // t1scoreNonCases;
							t2score = t2scoreCases // t2scoreNonCases;

							/*assign signs and symptoms*/
							/*cases*/
							ssCases = j( numberCases, 1, &errorCode );
							call randgen( ssCases, 'BERN', rateSignsSymptoms );

							/*non-cases*/
							ssNonCases = j( numberNonCases, 1, 0 );

							/*combine signs and symptoms matrices*/
							ss = ssCases // ssNonCases;

							/*make data matrix*/
							matrix = id || disease || ss || t1score || t2score;	 /* dataset generated to analyze. */

							/*output datasets for Aarti to use as test sets for the bias correction tool module*/
							/*these are output as temporary datasets because they still need the observed disease status added*/
							if rep = 1 then do;

								create example1 var { id disease ss t1score t2score };
								append from matrix;
								close example1;

							end;

							else if rep = 2 then do;

								create example2 var { id disease ss t1score t2score };
								append from matrix;
								close example2;

							end;

							else if rep = 3 then do;

								create example3 var { id disease ss t1score t2score };
								append from matrix;
								close example3;

							end;

							/*subset matrix into the groups*/
							/*we will then get summary statistics of the test scores in each of the groups*/

							/*first, we must make sure there is more than 1 observed case and non-case*/
							/*if not, we will not calculate any summary statistics and we will return an error*/

							/*find the locations of each observation in each of the groups*/
							/*if any of the locations are empty, write an error*/
							/*Observed cases: disease = 1 and at least one test score is above the threshold or ss = 1*/
							indicateObsCases = ( matrix[ , 2 ] = 1 & 
				                               ( matrix[ , 3 ] = 1 | 
				                                 matrix[ , 4 ] >= cutoffs[ , 1 ] | 
				                                 matrix[ , 5 ] >= cutoffs[ , 2 ] ) );

							/*Observed non-cases: disease = 0 or disease = 1 and ss = 0 and both test scores are below their thresholds*/ 
							indicateObsNonCases = ( matrix[ , 2 ] = 0 | 
					                              ( matrix[ , 2 ] = 1 & 
					                                matrix[ , 3 ] = 0 & 
					                                matrix[ , 4 ] < cutoffs[ , 1 ] & 
					                                matrix[ , 5 ] < cutoffs[ , 2 ] ) );

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

								/*subset the true cases and non-cases*/
								cases = matrix[ ( loc( matrix[ , 2 ] = 1 ) )`, ];
								nonCases = matrix[ ( loc( matrix[ , 2 ] = 0 ) )`, ];


								/* ***************                           *************** */
								/* *************** CALL completeAnalysis MODULE *************** */ 
								/* ***************                           *************** */


								run completeAnalysis;	


								/*calculate recall rate for cases for each test*/
								/*proportion of cases who test positive and are recalled for biopsy*/
								/*number of t1screen pos / number of participants given t1*/
								/*id, disease, ss, t1score, t2score*/
								numberT1ScreenPosSSCases = sum( ( matrix[ , 2 ] = 1 &
			                                                    ( matrix[ , 4 ] >= cutoffs[ , 1 ] |
			                                                    ( matrix[ , 4 ] < cutoffs[ , 1 ] &
			                                                      matrix[ , 5 ] < cutoffs[ , 2 ] &
			                                                      matrix[ , 3 ] = 1 ) ) )` ); 

								numberT2ScreenPosSSCases = sum( ( matrix[ , 2 ] = 1 &
			                                                    ( matrix[ , 5 ] >= cutoffs[ , 2 ] |
			                                                    ( matrix[ , 4 ] < cutoffs[ , 1 ] &
			                                                      matrix[ , 5 ] < cutoffs[ , 2 ] &
			                                                      matrix[ , 3 ] = 1 ) ) )` ); 

						        numberGoldStandardCases = sum( ( matrix[ , 2 ] = 1 &
								                               ( matrix[ , 4 ] >= cutoffs[ , 1 ] |
													             matrix[ , 5 ] >= cutoffs[ , 2 ] |
			                                                     matrix[ , 3 ] = 1 ) )` );

								posT1SSGoldStd = numberT1ScreenPosSSCases / numberCases;
								posT2SSGoldStd = numberT2ScreenPosSSCases / numberCases;
								GoldStd = numberGoldStandardCases / numberCases;

								/* ***************                           *************** */
								/* *************** CALL standardAnalysis MODULE *************** */ 
								/* ***************                           *************** */


								run standardAnalysis;

								/* ***************                           *************** */
								/* ********** CALL biasCorrectionAnalysis MODULE *************** */ 
								/* ***************                           *************** */

								run biasCorrectionAnalysis;

							end; /*end enough observed cases/non-cases*/

						end; /*end enough true cases/non-cases*/

/* **************************** Open dataset to edit ************************************** */

		edit out01.results;

/* ************************************ Create a matrix to display results ******************************************************** */         


						output =    rep || vectorRow || 
								    trueError || obsError || nathError || weighted || correctedNumberCasesError || 
									hypErrorComplete || hypErrorObserved || hypErrorCorrected ||
								    empty123 || emptyQuad1 || emptyQuad2 || emptyQuad3 || emptyQuad4 ||

									diseasePrevalence || rateSignsSymptoms || cutoffs || populationRhoCases || populationRhoNonCases ||

									maxIterations || tolerance || sampleSize ||
									meanOfTest1ScoresCases || meanOfTest2ScoresCases || meanOfTest1ScoresNonCases || meanOfTest2ScoresNonCases || stdOfTest1ScoresCases || stdOfTest2ScoresCases || stdOfTest1ScoresNonCases || stdOfTest2ScoresNonCases ||
									
									quadrantContainingMLECases || quadrantContainingMLENonCases ||

					                numberCases ||
								    meanT1Cases || meanT2Cases ||            
							        stdT1Cases || stdT2Cases ||
							        corrCases ||

							        numberNonCases ||
							        meanT1NonCases || meanT2NonCases ||
							        stdT1NonCases || stdT2NonCases ||
							        corrNonCases ||

							        numberObsCases ||
					                meanT1ObsCases || meanT2ObsCases || 
							        stdT1ObsCases || stdT2ObsCases ||
								    corrObsCases ||

							        numberObsNonCases ||
					                meanT1ObsNonCases || meanT2ObsNonCases || 
					                stdT1ObsNonCases || stdT2ObsNonCases ||
								    corrObsNonCases ||

									posT1SSGoldStd || posT2SSGoldStd ||	
									GoldStd ||

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

									populationAUCT1 || populationAUCT2 || populationDeltaAUC ||
									completeAUCT1 || completeAUCT2 || completeHypTest || directionCompleteHypTest ||
				                    observedAUCT1 || observedAUCT2 || observedHypTest || bias || directionObservedHypTest ||
				                    correctedAUCT1 || correctedAUCT2 || correctedHypTest || uncorrectedBias || directionCorrectedHypTest;

						errorsThisRep = cumErrors - pastErrors;

						if errorsThisRep >= 1 then resumeError = 1;
							else resumeError = 0;

						pastErrors = cumErrors;

						/* The output matrix should have 163 columns (one row per rep) */
						/* If there are not 163 columns, then add enough columns to make it 163 */
						/* This is done so the output row can be appended to the previous output row, even if there was an error during the current iteration*/


						if ( ncol( output ) ^= 165 ) then do;
								columnError = 1;
								additionalColumnsNeeded = 165 - ncol( output );
								addColumns = j( 1, additionalColumnsNeeded, &errorCode );
								results = output || addColumns || columnError || additionalColumnsNeeded || 
                                      resumeError || errorsThisRep || cumErrors;
						end;

						else do;
								results = output || 0 || 0 || resumeError || errorsThisRep || cumErrors;
						end;

						append from results;  
  
					end; /*end repetition loop*/

				end; /*end of rateOfSignsSymptoms loop*/

				cumErrors = -1;

			finish; /* finish decisionError module */

/***********************************************************************************************************/
			
			run decisionError;

		finish main; /* finish main */

		

		run; /* run main */
			
		close out01.results; 

	quit;

%mend;

/**Save the log as a file;*/
/*proc printto log = "&OUTPUT_FILE..log";*/
/*run;*/

/**generate data and do the complete, standard, and bias corrected analyses;*/
/*this dataset output by this macro call is out01.results*/
/*this macro call also outputs the raw datasets upon which we performed the complete, standard, and observed analsyses*/
/*the raw datasets can be used as test datasets for the bias correction tool module*/
/*the bias correction results output from this macro call and from the bias correction tool should match*/
%DecisionErrorSimAndExDatasets( 	seed = 1066, 
									errorCode = -99999, 
									numberOfRealizations = 3, 
									sampleSize = 50000, 
									tolerance = .000001, 
									maxIterations = 500, 
									meanOfTest1ScoresCases = 61.1, 
									meanOfTest2ScoresCases = 62.5,
									stdOfTest1ScoresCases = 1,
									stdOfTest2ScoresCases = 5,
									correlationT1T2ForCases = .1, 
									meanOfTest1ScoresNonCases = 60, 
									meanOfTest2ScoresNonCases = 58, 
									stdOfTest1ScoresNonCases = 1, 
									stdOfTest2ScoresNonCases = 5, 
									correlationT1T2ForNonCases = .1, 
									diseasePrevalence = .01, 
									cutOffT1T2 = { 65 59 }, 
									rateOfSignsSymptoms = .1, 
									changer = diseasePrevalence, 
									vector = ( { .01 } ) );

/*create permanent sas datasets of the three temporary example datasets output by the above macro call*/
/*create a variable for the observed disease status*/
/*verify that the observed summary statistics match those calculated in the out01.results dataset ouput in the above macro call*/
%macro createExampleDatasetAndVerify( id, co1, co2 );

	/*delete temporary datasets*/
	proc datasets lib = work;

		delete summaryCases trSummaryCases t1scoreCases t2scoreCases
			   summaryNonCases trSummaryNonCases t1scoreNonCases t2scoreNonCases
			   exampleSummary results;

	run;

	/*add observed disease status variable*/
	data out01.example&id;
		
		set example&id;

		cutOffTest1 = &co1;
		cutOffTest2 = &co2;

		if disease = 1 and ( ss = 1 or t1score >= cutOffTest1 or t2score >= cutOffTest2 ) then obsDisease = 1;
		else obsDisease = 0;

		keep obsDisease t1score t2score cutOffTest1 cutOffTest2;

	run;

	/*calculate summary statistics for the observed cases*/
	proc corr data = out01.example&id outp = summaryCases;

		where obsDisease = 1;
		var t1score t2score;

	run;

	/*reformat dataset*/
	proc transpose data = summaryCases ( where = ( _name_ ne "T1SCORE" ) ) out = trSummaryCases;

		id _type_;

	run;

	/*keep only useful variable for test 1*/
	data t1scoreCases;
		
		set trSummaryCases;

		if _name_ = "T1SCORE";

		keep n mean std corr;

	run;

	/*keep only useful variable for test 2*/
	data t2scoreCases;

		set trSummaryCases;

		if _name_ = "T2SCORE";

		keep mean std;

	run;

	/*calculate summary statistics for observed non-cases*/
	proc corr data = out01.example&id outp = summaryNonCases;

		where obsDisease = 0;
		var t1score t2score;

	run;

	/*reformat dataset*/
	proc transpose data = summaryNonCases ( where = ( _name_ ne "T1SCORE" ) ) out = trSummaryNonCases;

		id _type_;

	run;

	/*keep useful variables for test 1*/
	data t1scoreNonCases;
		
		set trSummaryNonCases;

		if _name_ = "T1SCORE";

		keep n mean std corr;

	run;
	
	/*keep useful variables for test 2*/
	data t2scoreNonCases;

		set trSummaryNonCases;

		if _name_ = "T2SCORE";

		keep mean std;

	run;

	/*combine test 1 and test 2 datasets and rename variables to match out01.results*/
	data exampleSummary;

		merge t1scoreCases ( rename = ( n = numberObsCases mean = meanT1ObsCases std = stdT1ObsCases corr = corrObsCases ) )
			  t2scoreCases ( rename = ( mean = meanT2ObsCases std = stdT2ObsCases ) )
		      t1scoreNonCases ( rename = ( n = numberObsNonCases mean = meanT1ObsNonCases std = stdT1ObsNonCases corr = corrObsNonCases ) )
			  t2scoreNonCases ( rename = ( mean = meanT2ObsNonCases std = stdT2ObsNonCases ) );

		rep = &id;

	run;

	/*pick off variables from out01.results to be compared to the example dataset*/
	data results;

		set out01.results;

		if rep = &id;

		keep rep numberObsCases meanT1ObsCases stdT1ObsCases meanT2ObsCases stdT2ObsCases corrObsCases
		         numberObsNonCases meanT1ObsNonCases stdT1ObsNonCases meanT2ObsNonCases stdT2ObsNonCases corrObsNonCases;

	run;

	/*compare results dataset summary statistics to the example dataset summary statistics*/
	ods pdf file = "&OUTPUT_FILE.&id..pdf";

	proc compare base = results compare = exampleSummary;
	run;

	ods pdf close;

%mend;

/*run macro for the three example datasets using the same cutoffs used in the DecisionErrorSimulatorAndRawDatasets macro call*/
%createExampleDatasetAndVerify( 1, 65, 59 );
%createExampleDatasetAndVerify( 2, 65, 59 );
%createExampleDatasetAndVerify( 3, 65, 59 );
