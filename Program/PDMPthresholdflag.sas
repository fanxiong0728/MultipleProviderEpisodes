/*-------------------------------------------------------------------*
  *    Name: PDMPthresholdflag.sas                                   *
  *   Title: Identify patients by the number of prescribers    	     *	
	     and dispensaries using PDMP data.                       *
        Doc:                 *
 *-------------------------------------------------------------------*
 *  Author:  Fan Xiong            <fanxiong0728@gmail.com>           *
 * Created:  27 Apr 2018                                             *
 * Revised:  07 Jul 2018 	                                     *
 * Version:  1.0                                                     *
 *-------------------------------------------------------------------*/
 
 /*------------------------------------------------------------------*/
 /* PURPOSE: Identify patients by specified number of prescribers    */	
 /*	     and dispensaries for epidemiological analysis.	     */
 /* INPUT:                                                           */
 /*   data=   	   name of your input PDMP data			     */
 /*   patient=     name of field for unique patient identifier       */
 /*   prescriber=  name of field for unique prescriber identifier    */
 /*   dispensary=  name of field for unique dispensary identifier    */
 /*   filled_date= name of field for date of prescription filled     */
 /*   Class=       specific the drug class of interest 		     */
 /*   MME=         name of field for opioid prescription morphine    */
 /*		   milligram equivalence.      			     */
 
 /* OUTPUT:                                                          */

 /*   VIEW1= 	   name of your SQL View appending or merging        */
 /*		   multiple years of data.                           */
 /*   OUT1=	   name of output summary table with number of       */
 /*		   patients exceeding threshold by report period.    */
 /*   RXFILLED=    number of filled prescriptions

 /*=

     ==Parameters:

      Report =   
		 Specify the reporting period interval of interest.
		 Options: 
		 	semiyear for semiyear calander
			qtr for quarter calander
			month for monthly calander
			day for daily calander


      Prescriber_threshold =

		Specify the number of unique prescribers a patient must exceed to flag 
		Example: 4 is equivalent to ">4 prescribers in a report period"

      dispensary_threshold =

		Specify the number of unique dispensaries a patient must exceed to flag 
		Example: 4 is equivalent to ">4 dispensaries in a report period"


   =*/


%LET data=  yourdata;	/*name of your input PDMP data	*/
%LET patient= patientid;/*name of field for unique patient identifier	*/
%LET prescriber=  prescriberid; /*name of field for unique prescriber identifier*/
%LET dispensary=  dispensaryid; /*name of field for unique dispensary identifier*/
%LET filled_date= filled_date; /*name of field for date of prescription filled  */
%LET Class=       Opioid; /*name of field for drug class of prescription	*/
%LET MME=         mme_dd; /*name of field for opioid prescription morphine   milligram equivalence. */


%LET VIEW1 = VIEW1; /*name of your SQL View appending or merging multiple years of data.   */
%LET OUT1= Out1; /*name of output summary table with number of patients exceeding threshold by report period.*/


%LET REPORT = QTR; /*Specify the reporting period interval of interest.
		        Options: 
		 	semiyear for semiyear calander
			qtr for quarter calander
			month for monthly calander
			day for daily calander   */

%LET Prescriber_threshold = 4; /*Specify the number of unique prescribers a patient must exceed to flag */
%LET dispensary_threshold = 4; /*Specify the number of unique dispensaries a patient must exceed to flag */



PROC SQL NOPRINT;

/*create SQL View process that can be modified by WHERE, KEEP, or JOINS to prepare your data*/

CREATE VIEW &VIEW1
AS SELECT &patient,&prescriber,&dispensary,
month(intnx("&REPORT",&filled_date,0)) as &REPORT,
COUNT(*) as RXFILLED,
avg(&mme) as avg_dailymme_per_rx

	FROM &data
		(keep=&patient &prescriber &dispensary dea_class &filled_date &mme
		
		WHERE=(dea_class="&class"))

	GROUP BY &patient,&prescriber,&dispensary, &REPORT;

	
/*Create summary table by reporting period*/

CREATE TABLE threshold&qtr&class as select

&REPORT, 
		WHEN     &class._prescriber_count GE &prescriber_threshold and 
			 &class._dispensary_count GE &dispensary_threshold then 1 
			 else 0 
		END as &class._MPE_STATUS,  

COUNT(DISTINCT(patient_identifier)) as &class.thresholdpatients,
SUM(TOTALRX_&CLASS) as TOTALRX_&CLASS,
SUM(avg_dailymme_per_rx) as cum_avg_dailymme_per_rx

	FROM 
		(
			SELECT &REPORT, &patient,SUM(RXFILLED) as TOTALRX_&CLASS,
			count(distinct(&prescriber))  as &class._prescriber_count,
			count(distinct(&dispensary))  as &class._dispensary_count
				FROM &VIEW1 WHERE RXFILLED GE 1
				GROUP BY &REPORT, &patient)


	GROUP BY &REPORT,CALCULATED &class._MPE_STATUS;
	QUIT;
