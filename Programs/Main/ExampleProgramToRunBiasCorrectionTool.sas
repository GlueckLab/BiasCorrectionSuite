/********************************************************************************************
Created By:		Brandy Ringham and Aarti Munjal 
Creation Date:	5/6/12

Copyright (C) 2010 Regents of the University of Colorado. This program is free software; 
you can redistribute it and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version. This program is distributed in the hope that it will be 
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You 
should have received a copy of the GNU General Public License along with this program; if not, 
write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
02110-1301, USA.

Description:
This program compares the areas under the curves of two screening tests. Each participant
was given both screening tests. Researchers recorded their screening test scores and
observed disease status in the SAS dataset "Example1.sas7bdat". The dataset is saved in the
"Input" folder. The program outputs the results of two analyses, a standard analysis and 
a bias-corrected analysis.  The standard analysis is based on the method of Obuchowski and 
McClish (1997) and is not corrected for paired screening trial bias.  The bias-corrected 
analysis is also based on the method of Obuchowski and McClish, however, the inputs to the 
hypothesis test are corrected for paired screening trial bias using the method of Ringham 
et al. (in review). Results are saved in "Output\Project\Experiment".

********************************************************************************************/

/*define options and pathnames to find SAS modules and save output*/
%include "..\Modules\IncludeLibrary.sas";

%IncludeLibrary;

/*specify pathname for output*/
%CommonMain( Project, Experiment, ExampleProgramToRunBiasCorrectionTool ); 

/*bias correct data*/
%BiasCorrectionTool( Example1, -99999, { 65 59 } );



