REM
REM This file runs all the modules for the bias correction process.
REM When it runs the modules, the compiled modules and the source code
REM are stored in a SAS catalog.
REM

del ..\Library\*.sas7bcat

"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorToolTable.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorSimulator.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./DecisionErrorTool.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionTool.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./BiasCorrectionToolTable.sas

"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calcCorrectedNumCasesNonCases.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calculateAUC.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./calculateWeightedEstimates.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./differenceInAUCHypothesisTest.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./estimateBivNormProbabilities.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./maximizeLogLikelihood.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./nathAlgorithm.sas
"C:\Program Files\SASHome\SASFoundation\9.3\sas.exe" -NOSPLASH -NOLOG -NOPRINT -sysin ./Prefix.sas

