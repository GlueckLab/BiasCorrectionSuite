/********************************************************************************************
Created By:		Brandy Ringham    
Creation Date:	5/6/12
 
Description:
Runs the BiasCorrectionTool program on example datasets.

The arguments used to create the example datasets were:  

								( 	seed = 1066, 
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

********************************************************************************************/


%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\CommonMain.sas"; /*Added by Aarti 
/*%include "C:\Users\munjala\Dropbox\Bias Correction R03 - paired\BiasCorrectionSoftware\programs\Modules\IncludeLibraryProgram01.sas";*/


%CommonMain( BiasCorrectionTuneUp, BiasCorrectionToolValidation, BiasCorrectionToolValidation ); 

proc printto log = "&OUTPUT_FILE..log";
run;

/*results that we are supposed to get, based on the old version*/
%IMLBiasCorrectionBiasCorrection( 1066, -99999, 3, 50000, .000001, 500, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, { 65 59 }, .1, diseasePrevalence, vector = ( { .01 } ) );

/*IMLBiasCorrection outputs the results as one dataset with three observations*/
/*Example data set 1 should give the same results as observation 1*/
/*Example data set 2 should give the same results as observation 2*/
/*Example data set 3 should give the same results as observation 3*/
/*Split the results data set into three different datasets so they can be compared separately to each example*/



data out01.reference1;

	set out01.results ( where = ( rep = 1 ) );

run;

data out01.reference2;

	set out01.results ( where = ( rep = 2 ) );

run;

data out01.reference3;

	set out01.results ( where = ( rep = 3 ) );

run;

/*results that we get from the new version*/
/*%BiasCorrectionTool( example dataset 1, cutoffs, etc );*/
%BiasCorrectionTool04( Example1, -99999, 1, 50000, .000001, 500, { 65 59 } );

/*rename the results dataset so it doesn't get written over*/
data out01.experimental1;

	set out01.results;

run;

/*results that we get from the new version*/
%BiasCorrectionTool04( Example2, -99999, 1, 50000, .000001, 500, { 65 59 } );

/*rename the results dataset so it doesn't get written over*/
data out01.experimental2;

	set out01.results;

run;

/*results that we get from the new version*/
%BiasCorrectionTool04( Example3, -99999, 1, 50000, .000001, 500, { 65 59 } );

/*rename the results dataset so it doesn't get written over*/
data out01.experimental3;

	set out01.results;

run;

/*compare the datasets*/
%CompareDatasets( 	data1 = out01.reference1, /* refers to the reference run dataset */
					data2 = out01.experimental1, /* refers to the bias correction tool dataset */
					outputFile = &OUTPUT_FILE.1.pdf );

/*compare the datasets*/
%CompareDatasets( 	data1 = out01.reference2, /* refers to the reference run dataset */
					data2 = out01.experimental2, /* refers to the bias correction tool dataset */
					outputFile = &OUTPUT_FILE.2.pdf );

/*compare the datasets*/
%CompareDatasets( 	data1 = out01.reference3, /* refers to the reference run dataset */
					data2 = out01.experimental3, /* refers to the bias correction tool dataset */
					outputFile = &OUTPUT_FILE.3.pdf );

proc printto;
run;
