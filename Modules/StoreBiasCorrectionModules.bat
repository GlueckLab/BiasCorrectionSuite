REM
REM This file runs all the macros for the bias correction process.
REM When it runs the macros, it stores the compiled macro and the source code
REM in a SAS macro catalog.
REM


"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./IMLBiasCorrection5.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorSimulator01.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorSimulator02.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorSimulator03.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorTool02.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool01.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool02.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool03.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool04.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool05.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool06.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./IMLBiasCorrection.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOPRINT -sysin ./IMLBiasCorrectionDecisionError.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOPRINT -sysin ./IMLBiasCorrectionBiasCorrection.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calcCorrectedNumCasesNonCases.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calculateAUC.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calculateWeightedEstimates.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./differenceInAUCHypothesisTest.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./estimateBivNormProbabilities.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./maximizeLogLikelihood.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./nathAlgorithm.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./CompareDatasets.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./Prefix.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorToolTable.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionToolTable.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOPRINT -sysin ./IncludeLibraryProgram01.sas