/*
Created By:		Brandy Ringham    
Creation Date:	1/28/13
*/

title1 "UnitTestCompareDatasets.sas";
title2 "Unit test of the module CompareDatasets.sas";
title3 "The ""Different"" pdf file compares two different example datasets";
title4 "The ""Same"" pdf file compares two datasets that are exactly the same";

%include "../Modules/CommonMain.sas";

%CommonMain( UnitTestCompareDatasets, , UnitTestCompareDatasets );

libname in01 "../../output/CreateExampleDataset";

%CompareDatasetsExcel( 	data1 = in01.Example1,
						data2 = in01.Example2,
						outputFile = &OUTPUT_FILE.Different.pdf );

%CompareDatasetsExcel( 	data1 = in01.Example1,
						data2 = in01.Example1,
						outputFile = &OUTPUT_FILE.Same.pdf );

