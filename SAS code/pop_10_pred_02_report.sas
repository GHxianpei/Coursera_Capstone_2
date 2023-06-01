
%LET pop_10_pred_02_sas_code     = pop_10_pred_02_report.sas;
%LET pop_10_pred_02_version_date = 15DEC2016;

/* ======================================================================================= */
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*                                                                                         */
/* ==> Print a summary "report" for Predictive Indicators                                  */
/*                                                                                         */
/* ======================================================================================= */

OPTIONS PS = 200
        LS = 160;

DATA parameters_and_counts;                             /* Create ONE record with fileds from TWO files */ 

   SET  DTA_OUT.parameters_pred_indicators;

   SET  DTA_OUT.pop_total_pred_indicators;

RUN;


DATA _null_;

 SET parameters_and_counts;

FILE print;

FORMAT POP_start_date 
       POP_reference_date       DATE009.;

%LET print_a_line = "----------------------------------------------------------------------------";

                                               /*====================*/
                                               /* Header info        */
                                               /*====================*/

PUT
          @ 001 "CIHI Population Grouping Methodology 1.0 - Predictive Indicator Report"
        / @ 001 &PRINT_A_LINE.

       // @ 001 "SAS code and data folders"
        / @ 001 &PRINT_A_LINE.
        / @ 001 "MY_FOLDER:  "
        / @ 010 "&MY_FOLDER."

       // @ 001 "'POP_CODE' folder (SAS code supplied by CIHI)   "
        / @ 010 "&POP_CODE."

       // @ 001 "'METHTAB' folder (Methodology tables supplied by CIHI)"
        / @ 010 "&METHTAB."
       // @ 010 "Methodology tables read by this SAS code: "
        / @ 015 "pop_10_methtab_sas_code    : &POP_10_methtab_sas_code. "
        / @ 015 "pop_10_methtab_version_date: &POP_10_methtab_version_date. "

       // @ 001 "'DTA_OUT' folder (Files prepared by USER)"
        / @ 010 "&DTA_OUT."
       // @ 001 "This report created by this SAS code: "
        / @ 010 "pop_10_pred_02_sas_code    : &pop_10_pred_02_sas_code. "
        / @ 010 "pop_10_pred_02_version_date: &pop_10_pred_02_version_date. "
          ;


                         /*====================*/
                         /* Parameters         */
                         /*====================*/
PUT 
       / @ 001 "USER specified parameters"
       / @ 001 "Parameter File: DTA_OUT.parameters_pred_indicators"
       / @ 001 &PRINT_A_LINE.
       / @ 010 "Methodology year             : " methodology_year
       / @ 010 "Methodology version number   : " methodology_version_num

      // @ 010 "USER_PHC_VISIT_AVG_CNT      : " user_phc_visit_avg_cnt      8.5
       / @ 010 "USER_ED_VISIT_AVG_CNT       : " user_ed_visit_avg_cnt       8.5 
       / @ 010 "USER_LTC_ADMIT_PROBABILITY  : " user_ltc_admit_probability  8.5
         ; 


%LET col_a = 025;
%LET col_b = 035;
%LET col_c = 052;



	                                                        /* ========================================= */
	                                                        /*   Predictive Ind 'source file'            */
	                                                        /* ========================================= */
PUT   // @ 001 "POP_GROUPER_HC_RIW file (input for Predictive Indicators)"
       / @ 001 &PRINT_A_LINE.

      // @ 005 "POP start date         : "  pop_start_date  DATE009.
       / @ 005 "POP reference date     : "  pop_reference_date  DATE009.
      // @ 005 "  POP_GROUPER_HC_RIW file - population : "  pop_grouper_hc_riw_cnt COMMA012.

	     ;

	                                                        /* =========================================== */
	                                                        /* USER_PHC_VISIT_AVERAGE_CNT 0.00 to 999.99   */
	                                                        /* =========================================== */


PUT   / @ 001 &PRINT_A_LINE.
      / @ 001 "Primary Health Care (PHC) Prospective Visits"
       
      // @ 005 "Prospective PHC Population             : " phc_pros_pop_cnt       COMMA012.
      // @ 005 "Average UNSCALED PHC Visits            : " phc_pros_UNSCALED_average 12.5
	     ;

IF user_phc_visit_avg_cnt = .
THEN PUT 
         / @ 005 "USER_PHC_VISIT_AVG_CNT: "  user_phc_visit_avg_cnt 6.2   
                 "   No USER supplied value - PHC visit scaling did not occur"
		   ;
ELSE

IF 0.01 <= user_phc_visit_avg_cnt <= 999.99
THEN PUT 
         / @ 005 "USER_PHC_VISIT_AVG_CNT: " user_phc_visit_avg_cnt 7.3
         / @ 005 "==> Used for PHC visit scaling"
		   ;
ELSE 
     PUT 
         / @ 005 "USER_PHC_VISIT_AVG_CNT: "  user_phc_visit_avg_cnt 6.2  " ***"
        // @ 005 "*** INVALID USER value - PHC visit scaling did not occur"
		   ;


	                                                        /* ========================================= */
	                                                        /* ED Concurrent                             */
	                                                        /* ========================================= */
PUT   // @ 001 &PRINT_A_LINE.
       / @ 001 "Emergency Department (ED) Concurrent Visits"
      

      // @ 005 "Concurrent ED Population               : " ed_conc_pop_cnt       COMMA012.
      // @ 005 "Average UNSCALED ED Concurrent Visits  : " ed_conc_UNSCALED_average 12.5
	     ;


IF user_ed_visit_avg_cnt = .
THEN PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: "  user_ed_visit_avg_cnt 6.2   
                 "   No USER supplied value - ED visit scaling did not occur"
		   ;
ELSE

IF 0.01 <= user_ed_visit_avg_cnt <= 999.99
THEN PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: " user_ed_visit_avg_cnt 7.3
         / @ 005 "==>  Used for ED visit scaling"
		   ;
ELSE PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: "  user_ed_visit_avg_cnt 6.2 " ***"
        // @ 005 "*** INVALID USER value - ED visit scaling did not occur"
		   ;

	                                                        /* ========================================= */
	                                                        /* ED Prospective                            */
	                                                        /* ========================================= */

PUT   // @ 001 &PRINT_A_LINE.
       / @ 001 "Emergency Department (ED) Prospective Visits"
       
       / @ 005 "Prospective ED Population              : " ed_pros_pop_cnt          COMMA012.
      // @ 005 "Average UNSCALED ED Prospective Visits : " ed_pros_UNSCALED_average 12.05
	     ;


IF user_ed_visit_avg_cnt = .
THEN PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: "  user_ed_visit_avg_cnt 6.2   
                 "   No USER supplied value - ED visit scaling did not occur"
		   ;
ELSE

IF 0.01 <= user_ed_visit_avg_cnt <= 999.99
THEN PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: "  user_ed_visit_avg_cnt 6.3
         / @ 005 "==>  Used for ED visit scaling"

		   ;
ELSE PUT 
         / @ 005 "USER_ED_VISIT_AVG_CNT: "  user_ed_visit_avg_cnt 6.2  " ***"
        // @ 005 "*** INVALID USER value - ED visit scaling did not occur"
		   ;



	                                                        /* ========================================= */
	                                                        /* LTC Prospective Probability of admission  */
	                                                        /* ========================================= */
PUT  // @ 001 &PRINT_A_LINE.
      / @ 001 "LTC Prospective Admission Probability"
      
      // @ 005 "Prospective LTC Population             : " ltc_pros_pop_cnt       COMMA012.
      // @ 005 "Average UNSCALED LTC Probability       : " ltc_pros_UNSCALED_average 12.06
         ;

IF user_ltc_admit_probability = .
THEN PUT 
        // @ 005 "USER_LTC_ADMIT_PROBABILITY: " user_ltc_admit_probability  6.2   
                 "   No USER supplied value - LTC probability scaling did not occur"
		   ;
ELSE

IF 0.01 <= user_ltc_admit_probability <= 1.00
THEN PUT 
         / @ 005 "USER_LTC_ADMIT_PROBABILITY             : " user_ltc_admit_probability 12.06  
         / @ 005 "==> Used for LTC probability scaling"

         ;

ELSE PUT 
        // @ 005 "USER_LTC_ADMIT_PROBABILITY: " user_ltc_admit_probability  6.2  " ***"
        // @ 005 "*** INVALID USER value - LTC probability scaling did not occur"
		   ;


PUT   // @ 001 "End of report"
       / @ 001 &PRINT_A_LINE.
	     ;

RUN;




/*================*/
/* End of program */
/*================*/
