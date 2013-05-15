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
This program simulates data for a paired screening trial.  It compares the areas under the 
curves of two screening tests. The program outputs the Type I error rate and power for
three analyses, a standard analysis, a bias-corrected analysis, and a reference analysis,
referred to as the complete analysis. The power is divided into two fractions, the correct
rejection fraction and the wrong rejection fraction.  The correct rejection fraction is the
power for the correct decision, while the wrong rejection fraction is the power for the
wrong decision.  The standard analysis is based on the method of Obuchowski and McClish 
(1997) and is not corrected for paired screening trial bias.  The bias-corrected analysis is 
also based on the method of Obuchowski and McClish, however, the inputs to the hypothesis test 
are corrected for paired screening trial bias using the method of Ringham et al. (in review).
The complete analysis assumes we know the true disease status of each participant.  It is
presented only as a reference to show the degree to which the other analyses align with the
true state of nature. Results are saved in "Output\Project\Experiment".

********************************************************************************************/

/*define options and pathnames to find SAS modules and save output*/
%include "..\Modules\IncludeLibrary.sas";

%IncludeLibrary;

/*specify pathname for output*/
%CommonMain( Project, Experiment, ExampleProgramToRunDecisionErrorTool ); 

/*conduct simulation*/
%DecisionErrorTool( 1066, -99999, 10000, 50000, 61.1, 62.5, 1, 5, .1, 60, 58, 1, 5, .1, .01, 
                    { 65 59 }, .1 ); 





