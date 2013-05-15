/*----------------------------------------------------------------------------------------------
Created By:		Brandy Ringham and Aarti Munjal   
Creation Date:	12/9/11

Copyright (C) 2010 Regents of the University of Colorado.

This program is free software; you can redistribute it and/or modify it under the terms of the 
GNU General Public License as published by the Free Software Foundation; either version 2 of the 
License, or (at your option) any later version. This program is distributed in the hope that it 
will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You 
should have received a copy of the GNU General Public License along with this program; if not, 
write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  
02110-1301, USA.
 
------------------------------------------------------------------------------------------------
									   DESCRIPTION
------------------------------------------------------------------------------------------------

This is an implementation of the Nath algorithm described in Nath, 1971.

------------------------------------------------------------------------------------------------
									   USER INPUTS
------------------------------------------------------------------------------------------------

The user inputs required for the program are as follows:

errCode					passed in value of error code variable
cumErrors				passed in value of cumulative errors variable
tolerance				tolerance
maxIterations			maximum number of iterations allowed before algorithm is stopped
errorCode				code designating an error
targetq					designates the type of truncation:  1 = both left, 2 = left, right,
                    	3 = right, left, 4 = right, right
co1						cutoff for variable 1
co2						cutoff for variable 2
mean1					starting value for variable 1 mean
mean2					starting value for variable 2 mean
std1					starting value for variable 1 std
std2					starting value for variable 2 std
corr					starting value for correlation between variable 1 and 2

------------------------------------------------------------------------------------------------
										  USAGE 
------------------------------------------------------------------------------------------------

Example:

nathAlgorithm( 0, 0, .0000001, 500, -99999, 4, 65, 59, 61.1, 62.1, 1.06, .89, .14 );

where

errCode					= 0
cumErrors				= 0
tolerance				= .0000001
maxIterations			= 500
errorCode				= -99999
targetq					= 4
co1						= 65
co2						= 59
mean1					= 61.1
mean2					= 62.1
std1					= 1.06
std2					= .89
corr					= .14

------------------------------------------------------------------------------------------------*/
*assigns pathnames and storage library;
%include "IncludeLibrary.sas";

%IncludeLibrary;

proc iml;

	/*summary stats matrix is the input for this next step*/
	start nathAlgorithm( errCode, cumErrors, tolerance, maxIterations, errorCode, targetq, co1, 
                         co2, mean1, mean2, std1, std2, corr );

		free / errCode cumErrors tolerance maxIterations errorCode targetq co1 co2 mean1 mean2 
               std1 std2 corr;

		/*initialize looping variables*/
		iteration = 0;
		outcome = 0;
		diff = tolerance * 10;

		/*if the target quadrant is not specified or is not in the right range then do not start*/
		if ( targetq ^= 1 && targetq ^= 2 && targetq ^= 3 && targetq ^= 4 ) then do;

			outcome = 1;
			mu1 = errorCode;
			mu2 = errorCode;
			sig1 = errorCode;
			sig2 = errorCode;
			rho = errorCode;

		end;

		else do; 

			/*if starting values are missing, error-coded, or out of range then do not start*/
			if ( mean1 = errorCode | mean2 = errorCode | std1 = errorCode | std2 = errorCode | 
                 corr = errorCode | mean1 = . | mean2 = . | std1 = . | std2 = . | corr = . | 
	             std1 < 0 | std2 < 0 | corr <= -1 | corr >= 1 ) then do;

				outcome = 2;
				mu1 = errorCode;
				mu2 = errorCode;
				sig1 = errorCode;
				sig2 = errorCode;
				rho = errorCode;

			end;

			else do; 

				/*set sample statistics as starting values*/
				mu1 = mean1;
				mu2 = mean2;
				sig1 = std1;
				sig2 = std2;
				rho = corr;

				/*iterative method to arrive at nath estimates*/
				/*stop loop if the difference between estimates is greater than or equal to the 
				 defined tolerance*/
				/*stop loop if previous iteration had an error*/
				do while ( diff > tolerance & outcome = 0 ); 
	
					/*increment interation number*/
					iteration = iteration + 1;

					/*Define initial values for current iteration*/
					mu10 = mu1;
					mu20 = mu2;
					sig10 = sig1;
					sig20 = sig2;
					rho0 = rho;

					/*Calculate eta, xi, rho, from updated values of mu, sigma, rho*/				
					xi = ( co1 - mu10 ) / sig10; 
					eta = ( co2 - mu20 ) / sig20; 

					/*Calculate G, P, Q, and A using eta, xi, rho values from previous iteration 
					  (or starting values)*/
					/*Calculate G*/
					/*this changes depending on truncated region*/
					if targetq = 1 then G = 1 - probnorm( xi ) - probnorm( eta ) + 
                                            probbnrm( xi, eta, rho0 );

					else if targetq = 2 then G = probnorm( eta ) - probbnrm( xi, eta, rho0 );

					else if targetq = 3 then G = probnorm( xi ) - probbnrm( xi, eta, rho0 );

					else G = probbnrm( xi, eta, rho0 );
				
					/*if G <= 0 then that means there is not enough information in the truncated 
					 region to form nath estimates*/
					if G <= 0 then do;

						outcome = 3;
						mu1 = errorCode;
						mu2 = errorCode;
						sig1 = errorCode;
						sig2 = errorCode;
						rho = errorCode;

					end;

					else do; 

						/*calculate x and e terms*/
						x = ( xi - rho0 * eta ) / sqrt( 1 - rho0**2 );
						e = ( eta - rho0 * xi ) / sqrt( 1 - rho0**2 );

						/*calculate the normal probability at xi and eta, inputs to P, Q, and A*/
						pdfxi = pdf( 'normal', xi );
						pdfeta = pdf( 'normal', eta );

						/*Calculate more inputs to P, Q, and A*/
						/*These change depending on the quadrant because I(t) changes*/
			    		if targetq = 1 then do;

							surve = 1 - probnorm( e );
		    				survx = 1 - probnorm( x );

						end;

						else if targetq = 2 then do;

			    			survx = 1 - probnorm( x );
							surve = probnorm( e );

						end;

						else if targetq = 3 then do;

			    			survx = probnorm( x );
							surve = 1 - probnorm( e );

						end;

						else do;

							survx = probnorm( x );
							surve = probnorm( e );

						end;

						/*Calculate P, Q, and A*/
						P = pdfxi * surve / G;
						Q = pdfeta * survx / G;
						A = pdf( 'normal', xi )*pdf( 'normal', e )*sqrt( 1 - rho0**2 ) / rho0 / G;

						/*P, Q, and A are different depending on which quadrant is truncated*/
						/*Only the sign changes so we do not have to recalculate the whole thing*/
						/*Rename P as Phat, etc to match notation in Nath paper*/
						if targetq = 1 then do;

							Qhat = Q;
							Phat = P;
							Ahat = A;

						end;

						else if targetq = 2 then do;

							Qhat = -Q;
							Phat = P;
							Ahat = -A;

						end;

						else if targetq = 3 then do;

							Qhat = Q;
							Phat = -P;
							Ahat = -A;

						end;

						else do;

							Qhat = -Q;
							Phat = -P;
							Ahat = A;

						end;

						/*Calculate updated parameters*/
						m = 1 + xi * Phat + rho0**2 * ( Ahat + eta * Qhat ) - 
	                        ( Phat + rho0 * Qhat )**2;
				
						n = 1 + eta * Qhat + rho0**2 * ( Ahat + xi * Phat ) - 
	                        ( Qhat + rho0 * Phat )**2;

						if ( m <= 0 | n <= 0 ) then do;

							outcome = 4;
							mu1 = errorCode;
							mu2 = errorCode;
							sig1 = errorCode;
							sig2 = errorCode;
							rho = errorCode;

						end;

						else do;

							sig1 = std1 / sqrt( m );
							sig2 = std2 / sqrt( n );

							/*stack overflow error occurs if values are too large or too small*/
							/*check size of values before they are used in further calculations*/
							/*if they are on the cusp of being too large, return error*/
							/*1e307 is the largest number iml will hold in memory*/
							/*it is easiest to test the size of a value by taking the log*/
							/*log( 1e307 ) is approx 706*/
							/*log( 1e-307 ) is approx -706*/

							logTestSig1 = log( sig1 );
							logTestSig2 = log( sig2 );

							/*return an error if values are too large or small*/
							if ( logTestSig1 <= -706 | logTestSig1 >= 706 |
					 		     logTestSig2 <= -706 | logTestSig2 >= 706 ) then do;

								outcome = 5;
								mu1 = errorCode;
								mu2 = errorCode;
								sig1 = errorCode;
								sig2 = errorCode;
								rho = errorCode;

							end;

							else do;

								mu1travel = -( Phat + rho0 * Qhat ) * sig1;
								mu2travel = -( Qhat + rho0 * Phat ) * sig2;
					
								mu1 = mean1 + mu1travel;
								mu2 = mean2 + mu2travel;

								/*stack overflow error occurs if values are too large or too small*/
								/*check size of values before they are used in further calculations*/
								/*if they are on the cusp of being too large, return error*/
								/*1e307 is the largest number iml will hold in memory*/
								/*it is easiest to test the size of a value by taking the log*/
								/*in order to take the log, we must make a test variable that is always 
								 positive*/
								/*log( 1e307 ) is approx 706*/
								/*log( 1e-307 ) is approx -706*/

								if mu1 < 0 then do;

									testMu1 = -mu1;

								end;

								else testMu1 = mu1;

								if mu2 < 0 then do;

									testMu2 = -mu2;

								end;

								else testMu2 = mu2;

								logTestMu1 = log( testMu1 );
								logTestMu2 = log( testMu2 );

								/*return an error if values are too large or small*/
								if ( logTestMu1 <= -706 | logTestMu1 >= 706 |
								     logTestMu2 <= -706 | logTestMu2 >= 706 ) then do;

									outcome = 6;
									mu1 = errorCode;
									mu2 = errorCode;
									sig1 = errorCode;
									sig2 = errorCode;
									rho = errorCode;

								end;

								else do;

									rho = corr * std1 * std2 / sig1 / sig2 / ( 1 + xi * Phat + 
	                                      eta * Qhat + Ahat - ( Phat + rho0 * Qhat ) * 
	                                      ( Qhat + rho0 * Phat) / rho0 );

									/*stack overflow error occurs if values are too large or too small*/
									/*check size of values before they are used in further calculations*/
									/*if they are on the cusp of being too large, return error*/
									/*1e307 is the largest number iml will hold in memory*/
									/*it is easiest to test the size of a value by taking the log*/
									/*in order to take the log, we must make a test variable that is always 
								     positive*/
									/*log( 1e307 ) is approx 706*/
									/*log( 1e-307 ) is approx -706*/

									if rho < 0 then do;

										testRho = -rho;

									end;

									else testRho = rho;

									logTestRho = log( testRho );

									/*return an error if values are too large or small*/
									if ( logTestRho <= -706 | logTestRho >= 706 ) then do;

										outcome = 7;
										mu1 = errorCode;
										mu2 = errorCode;
										sig1 = errorCode;
										sig2 = errorCode;
										rho = errorCode;

									end;

									else do;

										/*stop and return error if updated values are missing*/
										if ( mu1 = . | mu2 = . | sig1 = . | 
	                                         sig2 = . | rho = . ) then do;

											outcome = 8;
											mu1 = errorCode;
											mu2 = errorCode;
											sig1 = errorCode;
											sig2 = errorCode;
											rho = errorCode;

										end;

										/*stop and return missing if updated values are out of range*/
										else if ( sig1 < 0 | sig2 < 0 | 
	                                              rho <= -1 | rho >= 1 ) then do;

											outcome = 9;
											mu1 = errorCode;
											mu2 = errorCode;
											sig1 = errorCode;
											sig2 = errorCode;
											rho = errorCode;

										end;	

										else diff = max( abs( mu1 - mu10 ), 
				                        		         abs( mu2 - mu20 ),
												         abs( sig1 - sig10 ),
												         abs( sig2 - sig20 ),
												         abs( rho - rho0 ) );

										/*return missing values if loop has gone more than max 
	                                     iterations*/
										if ( iteration >= maxIterations && 
	                                         diff > tolerance  ) then do;

											outcome = 10;
											mu1 = errorCode;
											mu2 = errorCode;
											sig1 = errorCode;
											sig2 = errorCode;
											rho = errorCode;

										end;

									end; /*new rho is not too large or too small*/

								end; /*new mu1 and mu2 are not too large or too small*/

							end; /*new sig1 and sig2 are not too large or too small*/

						end; /*end m and n both > 0*/

					end; /*end G > 0*/

				end; /*end do while loop*/
		
			end; /*end starting values in correct range and not missing*/

		end; /*end target quadrant is in range*/

		return( iteration || outcome || mu1 || mu2 || sig1 || sig2 || rho );

	finish;

	/*set storage library*/
	reset storage = mlib.IMLModules;

	/*store module*/
	store;

quit;
