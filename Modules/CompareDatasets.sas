/*
Created By:			Brandy Ringham
Date:				1/15/13
Description:		Compare two SAS datasets.

Arguments:

data1				name of reference dataset
data2				name of comparison dataset
outputFile			path and name of the output file (must be pdf and must include extension)

Example:

%CompareDatasets( 	data1 = in01.Example1,
					data2 = in01.Example2,
					outputFile = ../../UnitTestCompareDatasets/UnitTestCompareDatasets.pdf );
*/

%include "CommonMacro.sas";

%CommonMacro;

%macro CompareDatasets( data1, data2, outputFile ) / store source;

	ods pdf file = "&outputFile";

	proc compare base = &data1 compare = &data2; 
	run;

	ods pdf close;

%mend;
