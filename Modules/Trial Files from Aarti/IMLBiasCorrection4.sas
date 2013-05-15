/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	12/12/11
 
Description:
This macro bias corrects the AUC for randomly generated binormal data.  The motivating 
example is a screening population where the sample consists of cases and non-cases.  There 
are two screening test scores associated with each participant.  The means, variances, and 
correlations of the test scores are conditional on whether the participant is a case or a 
non-case.

The user inputs required for the program are as follows:
seed        	seed for random number generation
errorCode		code for undefined entries - missing value not allowed, 
                avoid values that could be misconstrued as a data point
nrep     		number of realizations of the study
sampsize 		sample size in each study
tolerance		tolerance of Nath algorithm
maxIteraions	maximum number of iterations allowed for Nath algorithm
tmuc1    		mean of test 1 scores for cases
tmuc2    		mean of test 2 scores for cases
tsigc1   		standard deviation of test 1 scores for cases
tsigc2   		standard deviation of test 2 scores for cases
trhoc    		correlation between test 1 and 2 scores for cases
tmun1    		mean of test 1 scores for non-cases
tmun2    		mean of test 2 scores for non-cases
tsign1   		standard deviation of test 1 scores for non-cases
tsign2   		standard deviation of test 2 scores for non-cases
trhon    		correlation between test 1 and 2 scores for non-cases
p      			disease prevalence
co1co2			cutoffs for tests 1 and 2
psi				rate of signs and symptoms
changer			variable that changes, choices are:  diseasePrevalence, rateSignsSymptoms, 
                populationRhoCases, populationRhoNonCases, cutoffs
vector			vector or matrix of values for the changing variable

********************************************************************************************/

*assigns pathnames and storage library;
%include "CommonMacro.sas";
%include "../Macros/CommonMacro.sas";

%CommonMacro;

*simulate a whole bunch of bivariate normal stuff;
*subset it into quadrants;
*figure out which quadrants have < 2 observations;
*find summary statistics for quadrants with >= 2 observations;
%macro IMLBiasCorrection4( seed, errorCode, nrep, sampsize, tolerance, maxIterations, tmuc1, tmuc2, tsigc1, tsigc2, trhoc, tmun1,
                         tmun2, tsign1, tsign2, trhon, p, co1co2, psi, changer, vector ) / store source; 

	*clear dataset;  
	proc datasets lib = out01 nolist;
		delete results;  
	run;
	quit;

	*create empty file with preferred characteristics;
	data out01.results ( compress = no );

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
		empty1							length = 8 label = "Less than 2 observed cases in quadrant 1"
		empty2							length = 8 label = "Less than 2 observed cases in quadrant 2"
		empty3							length = 8 label = "Less than 2 observed cases in quadrant 3"
		empty4							length = 8 label = "Less than 2 observed cases in quadrant 4"
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
		outcome1						length = 8 label = "Outcome of Nath Algorithm in Quadrant 1"
		outcome2						length = 8 label = "Outcome of Nath Algorithm in Quadrant 2"
		outcome3						length = 8 label = "Outcome of Nath Algorithm in Quadrant 3"
		outcome4						length = 8 label = "Outcome of Nath Algorithm in Quadrant 4"
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
	
		flag  							length = 8 label = "Flag to check error condition in the setErrorCodes module";

		if _n_= 1 then delete;

	run;

	reset log print;

	proc iml worksize = 3000 symsize = 6000;	

		/*define storage location for modules and load all modules*/
		reset storage = mlib.IMLModules;
		load _all_;

		/*open dataset to edit*/
		edit out01.results;

		/*free variables that do not change within the do loop*/
		/*note:  in order to make the program more flexible, we also free the experimental variable but then reassign it later*/
		free errCode cumErrors pastErrors 
			 maxIterations tolerance sampSize
			 tmuc1 tmuc2 tmun1 tmun2 tsigc1 tsigc2 tsign1 tsign2
             rateSignsSymptoms diseasePrevalence cutoffs populationRhoCases populationRhoNonCases
			 populationAUCT1 populationAUCT2 populationDeltaAUC
			 quadrantContainingMLECases quadrantContainingMLENonCases
	         ncat vectorRow;

		start main;    
			print "start entering main"; 

			errCode = { "if cumErrors >= 0 then do;",
							"cumErrors = cumErrors + 1;",
							"call push( errCode ); resume;",
						"end;" };

			cumErrors = 0;
			pastErrors = 0;
			flag = &errorCode;

			call push( errCode );

			/* Description: 
Set the error code for variables based on the error encountered at several steps in IMLBiasCorrection module. */

			print "done with main";

			start setErrorCodes;
				print 'Entering set error codes module';
				if (numberObsCasesQuadrant1 < 2 & flag = 1) then do;
										
										print ,'Inside empty quad 1', flag;
										meanT1ObsCasesQuadrant1 = &errorCode;
										meanT2ObsCasesQuadrant1 = &errorCode;
										stdT1ObsCasesQuadrant1 = &errorCode;
										stdT2ObsCasesQuadrant1 = &errorCode;
										corrObsCasesQuadrant1 = &errorCode;
										outcome1 = &errorCode;
										nathQ1Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ1 = &errorCode;
										print 'done with setting error code for quad 1';
										

				end; /*end quadrant 1 is empty*/

				else if (numberObsCasesQuadrant2 < 2 & flag = 2) then do;
										
										print 'Inside empty quad 2', flag;
										meanT1ObsCasesQuadrant2 = &errorCode ;
										meanT2ObsCasesQuadrant2 = &errorCode ;
										stdT1ObsCasesQuadrant2 = &errorCode ;
										stdT2ObsCasesQuadrant2 = &errorCode ;
										corrObsCasesQuadrant2 = &errorCode ;
										outcome2 = &errorCode;
										nathQ2Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ2 = &errorCode;
										print 'done with setting error code for quad 2';

				end; /*end quadrant 2 is empty*/
		
			    else if (numberObsCasesQuadrant3 < 2 & flag = 3) then do;
										
										print 'Inside empty quad 3', flag;
										meanT1ObsCasesQuadrant3 = &errorCode;
										meanT2ObsCasesQuadrant3 = &errorCode;
										stdT1ObsCasesQuadrant3 = &errorCode;
										stdT2ObsCasesQuadrant3 = &errorCode;
										corrObsCasesQuadrant3 = &errorCode;
										outcome3 = &errorCode;
										nathQ3Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ3 = &errorCode;
										print 'done with setting error code for quad 3';

										/*numberObsCasesQuadrant1 = 10;*/

				end; /*end quadrant 3 is empty*/

				else if (numberObsCasesQuadrant4 < 2 & flag = 4) then do;

										print 'Inside empty quad 4', flag;
										meanT1ObsCasesQuadrant4 = &errorCode;
										meanT2ObsCasesQuadrant4 = &errorCode;
										stdT1ObsCasesQuadrant4 = &errorCode;
										stdT2ObsCasesQuadrant4 = &errorCode;
										corrObsCasesQuadrant4 = &errorCode;
										outcome4 = &errorCode;
										nathQ4Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										logLQ4 = &errorCode;
										meanT1ObsCasesQ123 = &errorCode;
										meanT2ObsCasesQ123 = &errorCode;
										stdT1ObsCasesQ123 = &errorCode;
										stdT2ObsCasesQ123 = &errorCode;
										corrObsCasesQ123 = &errorCode;

				end; /*end quadrant 4 is empty*/

				else if ( outcome1 ^= 0 & outcome2 ^= 0 & outcome3 ^= 0 & outcome4 ^= 0 & flag = 91) then do;

									print 'Inside NATH ERROR', flag;	
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

				else if ( (correctedNumberCasesNonCases[ , 1 ] > &sampSize |
		                            correctedNumberCasesNonCases[ , 1 ] = 0) & flag = 92 ) then do;
									correctedNumberCasesError = 1;
									correctedAUCT1 = &errorCode || &errorCode || &errorCode ;
									correctedAUCT2 = &errorCode || &errorCode || &errorCode ;
									correctedHypTest = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
									hypErrorCorrected = &errorCode;
									directionCorrectedHypTest = &errorCode;
									uncorrectedBias = &errorCode;
				end;

				else if ((numberCases < 2 | numberNonCases < 2) & flag = 100) then do;
									obsError = &errorCode;
									correctedNumberCasesError = &errorCode;
									empty123 = &errorCode;
									empty1 = &errorCode;
									empty2 = &errorCode;
									empty3 = &errorCode;
									empty4 = &errorCode;
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
									outcome1 = &errorCode;
									outcome2 = &errorCode;
									outcome3 = &errorCode;
									outcome4 = &errorCode;
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
				end;

				else if ( (numberObsCases < 2 | numberObsNonCases < 2) & flag = 101 ) then do;
								correctedNumberCasesError = &errorCode;
								empty123 = &errorCode;
								empty1 = &errorCode;
								empty2 = &errorCode;
								empty3 = &errorCode;
								empty4 = &errorCode;
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
								outcome1 = &errorCode;
								outcome2 = &errorCode;
								outcome3 = &errorCode;
								outcome4 = &errorCode;
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
				end; 
			
				else if (numberObsCasesQ123 < 2 & flag = 102) then do;
								meanT1ObsCasesQuadrant1 = &errorCode; 
								meanT2ObsCasesQuadrant1 = &errorCode;
								stdT1ObsCasesQuadrant1 = &errorCode;
								stdT2ObsCasesQuadrant1 = &errorCode;
								corrObsCasesQuadrant1 = &errorCode;
								outcome1 = &errorCode;
								nathQ1Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ1 = &errorCode;
								meanT1ObsCasesQuadrant2 = &errorCode;
								meanT2ObsCasesQuadrant2 = &errorCode;
								stdT1ObsCasesQuadrant2 = &errorCode;
								stdT2ObsCasesQuadrant2 = &errorCode;
								corrObsCasesQuadrant2 = &errorCode;
								outcome2 = &errorCode;
								nathQ2Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ2 = &errorCode;
								meanT1ObsCasesQuadrant3 = &errorCode;
								meanT2ObsCasesQuadrant3 = &errorCode;
								stdT1ObsCasesQuadrant3 = &errorCode;
								stdT2ObsCasesQuadrant3 = &errorCode;
								corrObsCasesQuadrant3 = &errorCode;
								outcome3 = &errorCode;
								nathQ3Row = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
								logLQ3 = &errorCode;
								meanT1ObsCasesQ123 = &errorCode;
								meanT2ObsCasesQ123 = &errorCode;
								stdT1ObsCasesQ123 = &errorCode;
								stdT2ObsCasesQ123 = &errorCode;
								corrObsCasesQ123 = &errorCode;
				end;

				else
					print 'nothing';

				print 'Exiting setErrorCodes Module';
				
			finish; /* finish setErrorCodes */

			print 'finished defining set error codes';
			

			start biasCorrection;
				print 'starting bias correction module';
				/*give values to constants*/
				/*we have to assign the macro variables as local variables because the IML modules*/
				/*do not like to use macro variables as operands*/
				maxIterations = &maxIterations;
				tolerance = &tolerance;
				sampSize = &sampSize;
				tmuc1 = &tmuc1;
				tmuc2 = &tmuc2;
				tmun1 = &tmun1;
				tmun2 = &tmun2;
				tsigc1 = &tsigc1;
				tsigc2 = &tsigc2;
				tsign1 = &tsign1;
				tsign2 = &tsign2;

				/*give values to experimental variables*/
				/*note: we will overwrite the experimental variable(s) with new values*/
				rateSignsSymptoms = &psi;
				diseasePrevalence = &p;
				cutoffs = &co1co2;
				populationRhoCases = &trhoc;
				populationRhoNonCases = &trhon;

				/*calculate true AUCs and difference in AUCs*/
				populationAUCT1 = calculateAUC( errCode, cumErrors, tmuc1, tmun1, tsigc1, tsign1 ); 
				populationAUCT2 = calculateAUC( errcode, cumErrors, tmuc2, tmun2, tsigc2, tsign2 );
				populationDeltaAUC = populationAUCT1[ , 3 ] - populationAUCT2[ , 3 ];

				/*find the quadrant containing the MLE for cases and non-cases*/
				if &tmuc1 >= cutoffs[ , 1 ] & &tmuc2 >= cutoffs[ , 2 ] then quadrantContainingMLECases = 1;
					else if &tmuc1 >= cutoffs[ , 1 ] & &tmuc2 < cutoffs[ , 2 ] then quadrantContainingMLECases = 2;
						else if &tmuc1 < cutoffs[ , 1 ] & &tmuc2 >= cutoffs[ , 2 ] then quadrantContainingMLECases = 3;
							else quadrantContainingMLECases = 4;

				if &tmun1 >= cutoffs[ , 1 ] & &tmun2 >= cutoffs[ , 2 ] then quadrantContainingMLENonCases = 1;
					else if &tmun1 >= cutoffs[ , 1 ] & &tmun2 < cutoffs[ , 2 ] then quadrantContainingMLENonCases = 2;
						else if &tmun1 < cutoffs[ , 1 ] & &tmun2 >= cutoffs[ , 2 ] then quadrantContainingMLENonCases = 3;
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
					do rep = 1 to &nrep;

						/*free variable names used in last iteration of rep do loop*/
						/*do not free variables assigned outside this do loop*/
						free / errCode cumErrors pastErrors
							   maxIterations tolerance sampSize
			                   tmuc1 tmuc2 tmun1 tmun2 tsigc1 tsigc2 tsign1 tsign2
							   rateSignsSymptoms diseasePrevalence cutoffs populationRhoCases populationRhoNonCases 
							   populationAUCT1 populationAUCT2 populationDeltaAUC quadrantContainingMLECases quadrantContainingMLENonCases
							   ncat vectorRow rep &changer;

						/*generate binormal data*/
						/*make a matrix with id disease t1score t2score and signs and symptoms in it*/
						/*set a seed for random number generator calls*/
						call randseed( &seed, 0 );

						/*generates a random number of cases from a binomial distribution with n = sample size and p = prevalence*/
						call randgen( numberCases, 'BINOM', diseasePrevalence, &sampSize );

						numberNonCases = &sampSize - numberCases;

						if numberCases < 2 | numberNonCases < 2 then do;
							print 'inside numberCases < 2';
							trueError = 1;
							flag = 100;
							run setErrorCodes;
						end; /*end not enough true cases*/

						else do;
							
							/*print 'inside numberCases > 2';*/
							
							trueError = 0;

							/*matrix of participant ids*/
							id = ( 1:&sampSize )`;

							/*create matrices of indicators for case or non-case*/
							/*create a matrix of 1 with length equal to the number of cases*/
							casesDisease = j( numberCases, 1, 1 );

							/*create a matrix of 0's of length equal to the sample size - number of cases*/
							nonCasesDisease = j( numberNonCases, 1, 0 );

							/*create disease index matrix*/
							disease = casesDisease // nonCasesDisease;

							/*generate binormal test scores for cases and non-cases*/
							/*cases*/
							meanCases = { &tmuc1 &tmuc2 };
							rhoMatrixCases = { 1 &trhoc, &trhoc 1 };
							sigmaMatrixCases = { &tsigc1 &tsigc2 };
							covMatrixCases = rhoMatrixCases # ( sigmaMatrixCases` * sigmaMatrixCases );
							scoreMatrixCases = randnormal( numberCases, meanCases, covMatrixCases );
							t1scoreCases = scoreMatrixCases[ , 1 ]; 
							t2scoreCases = scoreMatrixCases[ , 2 ];
						
							/*non-cases*/
							meanNonCases = { &tmun1 &tmun2 };
							rhoMatrixNonCases = { 1 &trhon, &trhon 1 };
							sigmaMatrixNonCases = { &tsign1 &tsign2 };
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
							matrix = id || disease || ss || t1score || t2score;	

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

								print 'inside numberObsCases < 2';
								obsError = 1;
								flag = 101;
								run setErrorCodes;
							end; /*end not enough observed cases*/

							else do;

								/*print 'inside numberObsCases > 2';*/

								obsError = 0;

								/*subset the true cases and non-cases*/
								cases = matrix[ ( loc( matrix[ , 2 ] = 1 ) )`, ];
								nonCases = matrix[ ( loc( matrix[ , 2 ] = 0 ) )`, ];

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
								if numberObsCasesQ123 < 2 then do;

									print 'inside numberObsCasesQ123 < 2';
									empty123 = 1;
									empty1 = 1;
									empty2 = 1;
									empty3 = 1;
									flag = 102;

									/*Since Q123 is empty, then all observations must be in Q4*/
									/*Calculate summary stats for Q4 only*/
									empty4 = 0;

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
									outcome4 = nathQ4Row[ , 2 ];

									/*maximize the log likelihood if the algorithm converged*/
									if outcome4 = 0 then logLQ4 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ4Row[ , 3 ], nathQ4Row[ , 4 ], 
						                                           		                 nathQ4Row[ , 5 ], nathQ4Row[ , 6 ], nathQ4Row[ , 7 ], 
						                                            	                 meanT1ObsCases, meanT2ObsCases, 
						                                            	                 stdT1ObsCases, stdT2ObsCases, 
						                                            	                 corrObsCases );

									else logLQ4 = &errorCode;
				
								end; /*end q123 is empty*/

								else do;

									/*print 'inside numberObsCasesQ123 > 2';*/

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
										print 'quad 1 is EMPTY';
										empty1 = 1;
										print flag;
										flag = 1;
										print flag;
										run setErrorCodes;
									end; /*end quadrant 1 is empty*/

									else do;

										print 'quad 1 NOT EMPTY';

										empty1 = 0;
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
										outcome1 = nathQ1Row[ , 2 ];

										/*maximize the log likelihood if the algorithm converged*/
										if outcome1 = 0 then logLQ1 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ1Row[ , 3 ], nathQ1Row[ , 4 ], 
							                                           		                 nathQ1Row[ , 5 ], nathQ1Row[ , 6 ], nathQ1Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

										else logLQ1 = &errorCode;

									end; /*end quadrant 1 is not empty*/

									if numberObsCasesQuadrant2 < 2 then do;
										print 'quad 2 is EMPTY';
										empty2 = 1;
										print flag;
										flag = 2;
										print flag;
										run setErrorCodes;

									end; /*end quadrant 2 is empty*/

									else do;

										print 'quad 2 is NOT EMPTY';

										empty2 = 0;
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
										outcome2 = nathQ2Row[ , 2 ];

										/*maximize the log likelihood if the algorithm converged*/
										if outcome2 = 0 then logLQ2 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ2Row[ , 3 ], nathQ2Row[ , 4 ], 
							                                           		                 nathQ2Row[ , 5 ], nathQ2Row[ , 6 ], nathQ2Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

										else logLQ2 = &errorCode;

									end; /*end quadrant 2 is not empty*/

									if numberObsCasesQuadrant3 < 2 then do;
										print 'quad 3 is EMPTY';
										empty3 = 1;
										print flag;
										flag = 3;
										print flag;
										run setErrorCodes;
									end; /*end quadrant 3 is empty*/

									else do;

										print 'quad 3 is NOT EMPTY';

										empty3 = 0;
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
										outcome3 = nathQ3Row[ , 2 ];

										/*maximize the log likelihood if the algorithm converged*/
										if outcome3 = 0 then logLQ3 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ3Row[ , 3 ], nathQ3Row[ , 4 ], 
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
										print 'quad 4 is EMPTY';
										empty4 = 1;
										print flag;
										flag = 4;	
										print flag;
										run setErrorCodes;
									end; /*end quadrant 4 is empty*/

									else do;
										
										print 'quad 4 is NOT EMPTY';

										empty4 = 0;

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
										outcome4 = nathQ4Row[ , 2 ];

										/*maximize the log likelihood if the algorithm converged*/
										if outcome4 = 0 then logLQ4 = maximizeLogLikelihood( errcode, cumErrors, numberObsCases, nathQ4Row[ , 3 ], nathQ4Row[ , 4 ], 
							                                           		                 nathQ4Row[ , 5 ], nathQ4Row[ , 6 ], nathQ4Row[ , 7 ], 
							                                            	                 meanT1ObsCases, meanT2ObsCases, 
							                                            	                 stdT1ObsCases, stdT2ObsCases, 
							                                            	                 corrObsCases );

										else logLQ4 = &errorCode;	

									end; /*end quadrant 4 is not empty*/

								end; /*end q123 is not empty*/

								/*if the Nath estimates are missing for all 4 quadrants then set remaining values to missing*/
								if ( outcome1 ^= 0 &
				                     outcome2 ^= 0 &
				                     outcome3 ^= 0 &
				                     outcome4 ^= 0 ) then do;
									print 'Found NATH ERROR';
									nathError = 1;
									flag = 91;
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
									if empty123 = 1 | empty4 = 1 then do;

										print 'WEIGHTED ESTIMATES NOT AVAILABLE';

										weighted = 0;
										weightedEstimatesRow = &errorCode || &errorCode || &errorCode || &errorCode || &errorCode ;
										bivNormProbsWeighted = &errorCode || &errorCode ;

										/*calculate corrected number of cases/non-cases based on bivariate probabilities*/
										correctedEstimatesRow = nathEstimatesRow[ , { 5, 6, 7, 8, 9 } ];
										correctedNumberCasesNonCases = calcCorrectedNumCasesNonCases( errcode, cumErrors, bivariateNormalProbabilitiesNath[ , 1 ], 
								            													      &sampSize, numberObsCasesQ123 );
									end; /*end use corrected estimates*/

									/*if there are at least 2 observations in q123 AND q4 then we can calculate the weighted estimates*/
									/*we will use these estimates as the corrected estimates*/
									else do;

										print 'WEIGHTED ESTIMATES AVAILABLE';

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
								            													      &sampSize, numberObsCasesQ123 );

									end; /*end use weighted estimates*/

									/*sometimes the corrected number of cases will be greater than the sample size*/
									/*this happens because the bivariate probabilties (f1, f2) are estimated with error*/
									/*if the corrected number of cases is greater than the sample size, then do not bias correct*/
									/*also, the corrected number of cases could be 0, which would blow up R in the hypothesis test*/
									/*this is bad, so return an error if this happens and do not do bias correction*/
									/*essentially, you cannot do bias correction if you have an extreme number of observed cases or non-cases*/
									if ( correctedNumberCasesNonCases[ , 1 ] > &sampSize |
		                                 correctedNumberCasesNonCases[ , 1 ] = 0 ) then do;
									   print 'CORRECTED NUMBER OF CASES IS > SAMPLE SIZE';
									   flag = 92;
									   run setErrorCodes;
									end; /*end corrected number of cases is greater than sample size*/

									else do;

										print 'CORRECTED NUMBER NO ERROR';
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

							end; /*end enough observed cases/non-cases*/

						end; /*end enough true cases/non-cases*/

						output =    rep || vectorRow || 
								    trueError || obsError || nathError || weighted || correctedNumberCasesError || 
									hypErrorComplete || hypErrorObserved || hypErrorCorrected ||
								    empty123 || empty1 || empty2 || empty3 || empty4 ||

									diseasePrevalence || rateSignsSymptoms || cutoffs || populationRhoCases || populationRhoNonCases ||

									maxIterations || tolerance || sampSize ||
									tmuc1 || tmuc2 || tmun1 || tmun2 || tsigc1 || tsigc2 || tsign1 || tsign2 ||
									
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

									outcome1 || outcome2 || outcome3 || outcome4 ||

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

						/*there should 163 columns in the output matrix (one row per rep)*/
						/*if there are not 163 columns then add enough columns to make it that many*/
						/*we do this so the output row can be appended to the previous output row, even if there was an error during the current iteration*/
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

				end; /*end psi loop*/

				cumErrors = -1;

			finish; /* finish biasCorrection */

			print 'finished defining bias correction module';

			

			run biasCorrection;
			

		

		finish main; /* finish main */

		

		run; /* run main */
			
		close out01.results; 

	quit;

%mend;

