
%LET pop_10_pred_01_sas_code     = pop_10_pred_01_indicators.sas;
%LET pop_10_pred_01_version_date = 15DEC2016;

/*=========================================================================================*/
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*=========================================================================================*/
/*                                                                                         */
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_OUT.parameters_pred_indicators                                        */
/*                                                                                         */
/*               DTA_OUT.pop_grouper_hc_riw                                                */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/* Output File(s):                                                                         */
/*                                                                                         */
/*               DTA_OUT.pop_total_pred_indicators                                         */
/*                                                                                         */
/*               DTA_OUT.pop_grouper_pred_indicators                                       */
/*                    phc_pros_return_code                                                 */
/*                    ed_conc_return_code                                                  */
/*                    ed_pros_return_code                                                  */
/*                    ltc_pros_return_code                                                 */
/*                                                                                         */
/*=========================================================================================*/


                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
%GLOBAL pop_10_pred_01_start
        pop_10_pred_01_finish;

DATA _NULL_;

FILE print;

FORMAT start_time DATETIME020.;

start_time = DATETIME();

CALL SYMPUTX ("pop_10_pred_01_start", start_time );


PUT // @ 010 "PRED SAS code     : &pop_10_pred_01_sas_code.                     has started running"
    // @ 010 "     Version date : &pop_10_pred_01_version_date."

    // @ 060 " Start time : " start_time
       ; 

RUN;






/* =========================================================================== */
/* Macro for PHC Prospective indicator                                         */
/*      phc_visit_pros_unscaled_cnt                                            */
/*      phc_pros_return_code                                                   */
/* =========================================================================== */
%MACRO PHC_indicator;

phc_base_prospective_coef = .;
phc_hc_prospective_coef = .;
health_condition_code = "----";
health_condition_1_code = "----";
health_condition_2_code = "----";
phc_interact_prospective_coef = .;


phc_visit_pros_unscaled_cnt = .;
phc_pros_return_code = "bb";


IF hcn_valid_on_ref_date_flag = "Y"
THEN DO;

		%POP_PHC_BASE;
		phc_base_prospective_coef = SUBSTR (pop_phc_base_lookup, 010, 008) + 0.0;
        phc_visit_pros_unscaled_cnt = phc_base_prospective_coef;

/* OUTPUT  phc_pros_indicator;  */
phc_base_prospective_coef = .;

        IF person_hc_cnt > 0
        THEN DO i = t_seq_lowest_hc TO t_seq_highest_hc;

		        IF health_condition_{i} = 1
                THEN DO;
 
				        health_condition_code = VNAME(health_condition_{ i });
                        %POP_PHC_HC;

						IF pop_phc_hc_lookup = " "
						THEN phc_hc_prospective_coef = 0.0;
				        ELSE phc_hc_prospective_coef = SUBSTR (pop_phc_hc_lookup, 009, 008) * 1.0;

                        phc_visit_pros_unscaled_cnt = phc_visit_pros_unscaled_cnt + phc_hc_prospective_coef;

/* OUTPUT phc_pros_indicator;  */
health_condition_code = "----";
phc_hc_prospective_coef = .;

                     END;
             END;

        

        IF person_hc_cnt > 1
        THEN DO;                /* 4 - Check for interactions  */ 

                DO i = t_seq_lowest_hc TO (t_seq_highest_hc - 1);

                    IF health_condition_{ i } = 1 
                    THEN DO j = (i + 1) TO t_seq_highest_hc;

                               IF health_condition_{ j } = 1 
                               THEN DO;
                                       health_condition_1_code = VNAME(health_condition_{ i });
                                       health_condition_2_code = VNAME(health_condition_{ j });  

                                       %POP_PHC_INTERACT;

                                       IF pop_phc_interact_lookup NE " "
                                       THEN DO;
                                               phc_interact_prospective_coef = SUBSTR (pop_phc_interact_lookup, 013, 008) * 1.0;
						                       phc_visit_pros_unscaled_cnt = phc_visit_pros_unscaled_cnt + phc_interact_prospective_coef;
                                            END;

/* OUTPUT phc_pros_indicator;  */
health_condition_1_code = "----";
health_condition_2_code = "----";
phc_interact_prospective_coef = .;

                                   END;
                         END;  /* J loop */ 

                  END; /* I loop */

             END; 

        phc_pros_return_code = "00";

        IF phc_visit_pros_unscaled_cnt < 0
		THEN DO;
                phc_visit_pros_unscaled_ORIG_cnt = phc_visit_pros_unscaled_cnt;
                phc_visit_pros_unscaled_cnt = 0.00;
                phc_pros_return_code = "81";
		     END;
                   
/* OUTPUT phc_pros_indicator; */

     END;
ELSE DO;
                                         /* ========================================= */
                                         /* Person is NOT in the indicator population */
                                         /* ========================================= */
	    phc_visit_pros_unscaled_cnt = .;
        phc_visit_pros_unscaled_ORIG_cnt = .;
        phc_pros_return_code = "65";

/* OUTPUT  phc_pros_indicator; */
     END;


%MEND PHC_indicator;


/* =========================================================================== */
/* Macro for ED Concurrent indicator                                           */
/*      ed_visit_conc_unscaled_cnt                                             */
/*      ed_conc_return_code                                                    */
/* =========================================================================== */

%MACRO ED_CONCURRENT_INDICATOR;

ed_base_concurrent_exp_coef = .;
ed_base_concurrent_lin_coef = .;
ed_hc_concurrent_exp_coef = .;
ed_hc_concurrent_lin_coef = .;
ed_conc_exp_product = .;
ed_conc_lin_sum = .;
ed_conc_return_code = "--";


IF pop_user_code IN ("00" "01")
THEN DO;

		%POP_ED_BASE;
		ed_base_concurrent_lin_coef  = SUBSTR (pop_ed_base_lookup, 010, 008) * 1.0;
        ed_base_concurrent_exp_coef  = SUBSTR (pop_ed_base_lookup, 018, 008) * 1.0;

        ed_conc_exp_product = ed_base_concurrent_exp_coef;
        ed_conc_lin_sum = ed_base_concurrent_lin_coef;

/* OUTPUT  ed_conc_indicator; */
ed_base_concurrent_exp_coef = .;
ed_base_concurrent_lin_coef = .;

        IF person_hc_cnt > 0
        THEN DO i = t_seq_lowest_hc TO t_seq_highest_hc;

		        IF health_condition_{i} = 1
                THEN DO;
 
				        health_condition_code = VNAME(health_condition_{ i });
                        %POP_ED_HC;

						IF pop_ed_hc_lookup NE " "
						THEN DO;
								ed_hc_concurrent_lin_coef  = SUBSTR (pop_ed_hc_lookup, 009, 008) * 1.0;
                                ed_hc_concurrent_exp_coef  = SUBSTR (pop_ed_hc_lookup, 017, 008) * 1.0;
                                ed_hc_prospective_lin_coef = SUBSTR (pop_ed_hc_lookup, 025, 008) * 1.0;
                                ed_hc_prospective_exp_coef = SUBSTR (pop_ed_hc_lookup, 033, 008) * 1.0;

								ed_conc_exp_product = ed_conc_exp_product * ed_hc_concurrent_exp_coef;
                                ed_conc_lin_sum     = ed_conc_lin_sum     + ed_hc_concurrent_lin_coef;
                             END;


/* OUTPUT  ed_conc_indicator; */

                     END;
             END;

        health_condition_code = "----";
		ed_hc_concurrent_exp_coef = .;
		ed_hc_concurrent_lin_coef = .;

		ed_visit_conc_unscaled_cnt = ed_conc_exp_product / (1 + ed_conc_exp_product) * ed_conc_lin_sum ;
        ed_conc_return_code = "00";   

        IF  ed_visit_conc_unscaled_cnt < 0
		THEN DO;
                ed_visit_conc_unscaled_ORIG_cnt = ed_visit_conc_unscaled_cnt;
                ed_visit_conc_unscaled_cnt = 0.00; 
                ed_conc_return_code = "81";      
		     END;
 
/* OUTPUT  ed_conc_indicator; */

     END;
ELSE DO;
                                         /* ========================================= */
                                         /* Person is NOT in the indicator population */
                                         /* ========================================= */
		ed_visit_conc_unscaled_cnt = .;
		ed_visit_conc_unscaled_ORIG_cnt = .;
        ed_conc_return_code = "65";    
 
/* OUTPUT  ed_conc_indicator; */

     END;


%MEND ED_CONCURRENT_INDICATOR;




/* =========================================================================== */
/* Macro for ED Prospective indicator                                          */
/*      ed_visit_pros_unscaled_cnt                                             */
/*      ed_pros_return_code                                                    */
/* =========================================================================== */
%MACRO ED_PROSPECTIVE_INDICATOR;

ed_base_prospective_exp_coef = .;
ed_base_prospective_lin_coef = .;
ed_hc_prospective_exp_coef = .;
ed_hc_prospective_lin_coef = .;
ed_pros_exp_product = .;
ed_pros_lin_sum = .;
ed_pros_return_code = "--";

IF hcn_valid_on_ref_date_flag = "Y"
THEN DO;

		%POP_ED_BASE;
        ed_base_prospective_lin_coef = SUBSTR (pop_ed_base_lookup, 026, 008) * 1.0;
        ed_base_prospective_exp_coef = SUBSTR (pop_ed_base_lookup, 034, 008) * 1.0;

        ed_pros_exp_product = ed_base_prospective_exp_coef;
        ed_pros_lin_sum     = ed_base_prospective_lin_coef;

/* OUTPUT  ed_pros_indicator; */
ed_base_prospective_exp_coef = .;
ed_base_prospective_lin_coef = .;

        IF person_hc_cnt > 0
        THEN DO i = t_seq_lowest_hc TO t_seq_highest_hc;

		        IF health_condition_{i} = 1
                THEN DO;
 
				        health_condition_code = VNAME(health_condition_{ i });
                        %POP_ED_HC;

						IF pop_ed_hc_lookup NE " "
						THEN DO;
                                ed_hc_prospective_lin_coef = SUBSTR (pop_ed_hc_lookup, 025, 008) * 1.0;
                                ed_hc_prospective_exp_coef = SUBSTR (pop_ed_hc_lookup, 033, 008) * 1.0;

								ed_pros_exp_product = ed_pros_exp_product * ed_hc_prospective_exp_coef;
                                ed_pros_lin_sum     = ed_pros_lin_sum     + ed_hc_prospective_lin_coef;
                             END;

/* OUTPUT  ed_pros_indicator; */
health_condition_code = "----";
ed_hc_prospective_exp_coef = .;
ed_hc_prospective_lin_coef = .;

                     END;
             END;

		ed_visit_pros_unscaled_cnt = ed_pros_exp_product / (1 + ed_pros_exp_product) * ed_pros_lin_sum ;
        ed_pros_return_code = "00";      

        IF  ed_visit_pros_unscaled_cnt < 0
		THEN DO;
                ed_visit_pros_unscaled_ORIG_cnt = ed_visit_pros_unscaled_cnt;
                ed_visit_pros_unscaled_cnt = 0.00; 
                ed_pros_return_code = "81";      
		     END;

     END;
ELSE DO;
                                         /* ========================================= */
                                         /* Person is NOT in the indicator population */
                                         /* ========================================= */
		ed_pros_return_code = "65";
        ed_visit_pros_unscaled_ORIG_cnt = .;
		ed_visit_pros_unscaled_cnt = .;

     END;


%MEND ED_PROSPECTIVE_INDICATOR;


/* =========================================================================== */
/* MACRO for LTC indicator                                                     */
/*      ltc_admit_unscaled_probability                                         */
/*      ltc_pros_return_code                                                   */
/* =========================================================================== */
%MACRO ltc_indicator;

ltc_base_prospective_exp_coef = .;
ltc_hc_prospective_exp_coef = .;
ltc_hc_user_prosp_exp_coef = .;
ltc_inter_prospective_exp_coef = .;
ltc_a = .;

ltc_admit_unscaled_probability = .;
ltc_pros_return_code = "--";

IF ltc_flag = "N" & 
   hcn_valid_on_ref_date_flag = "Y" &
   pop_age_group_code >= "16"
THEN DO;

        %POP_LTC_BASE_PROBABILITY;
		ltc_base_prospective_exp_coef = SUBSTR (pop_ltc_base_prob_lookup, 010, 011) * 1.0;
        ltc_a = ltc_base_prospective_exp_coef;

/* OUTPUT ltc_pros_indicator; */
ltc_base_prospective_exp_coef = .;


        %POP_LTC_HC_USER_PROBABILITY;
				                                    /* ============================================= */
				                                    /* There is ONLY a factor for POP_USER_CODE = 01 */
				                                    /* ============================================= */
        IF pop_ltc_hc_user_prob_lookup = " "
        THEN ltc_hc_user_prosp_exp_coef = 1.0;
        ELSE ltc_hc_user_prosp_exp_coef = SUBSTR (pop_ltc_hc_user_prob_lookup, 007, 011) * 1.0;;
        
        ltc_a = ltc_a * ltc_hc_user_prosp_exp_coef ;

/* OUTPUT ltc_pros_indicator; */
ltc_hc_user_prosp_exp_coef = .;

        IF person_hc_cnt > 0
        THEN DO i = t_seq_lowest_hc TO t_seq_highest_hc;

		        IF health_condition_{i} = 1
                THEN DO;
 
				        health_condition_code = VNAME(health_condition_{ i });
                        %POP_LTC_HC_PROBABILITY;

				                                      /* =============================================== */
				                                      /* There are ONLY five HCs A02, A04, Q01, Q03, Q81 */
                                                      /* =============================================== */
						IF pop_ltc_hc_prob_lookup = " "
						THEN ltc_hc_prospective_exp_coef = 1.0;
				        ELSE ltc_hc_prospective_exp_coef = SUBSTR (pop_ltc_hc_prob_lookup, 009, 011) * 1.0;

                       ltc_a = ltc_a * ltc_hc_prospective_exp_coef;

/* OUTPUT ltc_pros_indicator; */
health_condition_code = "----";
ltc_hc_prospective_exp_coef = .;

                     END;
             END;


        IF person_hc_cnt > 1
        THEN DO;

                DO i = t_seq_lowest_hc TO (t_seq_highest_hc - 1);

                    IF health_condition_{ i } = 1 
                    THEN DO j = (i + 1) TO t_seq_highest_hc;

                               IF health_condition_{ j } = 1 
                               THEN DO;
                                       health_condition_1_code = VNAME(health_condition_{ i });
                                       health_condition_2_code = VNAME(health_condition_{ j });  

                                       %POP_LTC_INTERACT_PROBABILITY;

                                       IF pop_ltc_interact_lookup NE " "
                                       THEN DO;
                                               ltc_inter_prospective_exp_coef = SUBSTR (pop_ltc_interact_lookup, 013, 011) * 1.0;
											   ltc_a = ltc_a * ltc_inter_prospective_exp_coef;

/* OUTPUT ltc_pros_indicator; */
health_condition_1_code = "----";
health_condition_2_code = "----";
ltc_inter_prospective_exp_coef = .;
                                            END;

                                   END;
                         END;  /* J loop */ 

                  END; /* I loop */

             END; 

        ltc_pros_return_code = "00";
        ltc_admit_unscaled_probability = ltc_a / (1 + ltc_a);

     END;
ELSE DO;
                                         /* ========================================= */
                                         /* Person is NOT in the indicator population */
                                         /* ========================================= */
        ltc_pros_return_code = "65";
        ltc_admit_unscaled_probability = .;
     END;


/* OUTPUT ltc_pros_indicator;  */   

%MEND ltc_indicator;



/* =========================================================================== */
/* Main program                                                                */
/*       Assign UNSCALED Predictive Indicators                                 */
/* =========================================================================== */

DATA predictive_indicators;

   SET DTA_OUT.pop_grouper_hc_riw
         (
          KEEP = methodology_year
		         methodology_version_num
                 province_code

				 pop_start_date
				 pop_reference_date

                 person_id
				 pop_user_code
				 person_hc_cnt
                 reg_gender_code
                 pop_age_group_code
				 hcn_valid_on_ref_date_flag
				 ltc_flag         

                 &HC_LIST.            /* HC_LIST contains ALL POP Health Conditions (A01 . . . S81) */
                );



ARRAY health_condition_{&sys_hc_cnt.} 3. &HC_LIST. ;
RETAIN &HC_LIST.;



LENGTH health_condition_code
       health_condition_1_code 
       health_condition_2_code  $004.;


/* ========================================= */
/* Set LOWEST and HIGHEST SEQ_ID             */
/* ========================================= */

t_seq_lowest_hc  = 999;
t_seq_highest_hc = 000;

IF person_hc_cnt > 0
THEN DO i = 1 TO &SYS_HC_CNT.;
        IF health_condition_{i} = 1
        THEN DO;
                IF i < t_seq_lowest_hc
                THEN t_seq_lowest_hc = i;

                t_seq_highest_hc = i;

             END;
    END;


%PHC_INDICATOR;

%ED_CONCURRENT_INDICATOR;

%ED_PROSPECTIVE_INDICATOR;

%LTC_INDICATOR;



OUTPUT predictive_indicators;


FORMAT        
       phc_visit_pros_unscaled_ORIG_cnt
	   phc_visit_pros_unscaled_cnt

	   ed_visit_pros_unscaled_ORIG_cnt
	   ed_visit_pros_unscaled_cnt

       ed_visit_pros_unscaled_ORIG_cnt
       ed_visit_pros_unscaled_cnt

       ltc_admit_unscaled_probability 12.9;


KEEP methodology_year
     methodology_version_num

     province_code
     pop_start_date
     pop_reference_date

     person_id
     reg_gender_code
     hcn_valid_on_ref_date_flag
     pop_age_group_code
     ltc_flag
     pop_user_code
     person_hc_cnt
	
	 phc_pros_return_code
     phc_visit_pros_unscaled_ORIG_cnt
     phc_visit_pros_unscaled_cnt

	 ed_conc_return_code
     ed_visit_conc_unscaled_ORIG_cnt
     ed_visit_conc_unscaled_cnt

	 ed_pros_return_code
     ed_visit_pros_unscaled_ORIG_cnt
     ed_visit_pros_unscaled_cnt

	 ltc_pros_return_code
     ltc_admit_unscaled_probability ;


RUN;




                                                                  /* =============================== */
                                                                  /* Derive UNSCALED stats           */
                                                                  /* =============================== */

DATA pred_indicator_UNSCALED_stats
       (KEEP = pop_start_date
               pop_reference_date
			   pop_grouper_pred_ind_cnt
               ed_conc_pop_cnt   ed_conc_UNSCALED_average   ed_conc_pop_reset_cnt 
               ed_pros_pop_cnt   ed_pros_UNSCALED_average   ed_pros_pop_reset_cnt
               phc_pros_pop_cnt  phc_pros_UNSCALED_average  phc_pros_pop_reset_cnt 
               ltc_pros_pop_cnt  ltc_pros_UNSCALED_average  ltc_pros_pop_reset_cnt);

   SET predictive_indicators
       END = eof;

RETAIN pop_grouper_pred_ind_cnt
	   phc_pros_pop_cnt   sum_phc_pros phc_pros_pop_reset_cnt 
       ed_conc_pop_cnt    sum_ed_conc  ed_conc_pop_reset_cnt 
       ed_pros_pop_cnt    sum_ed_pros  ed_conc_pop_reset_cnt 
	   ltc_pros_pop_cnt   sum_ltc_pros ltc_pros_pop_reset_cnt ;

IF _N_ = 0
THEN DO;
       pop_grouper_pred_ind_cnt = 0;

       ed_conc_pop_cnt = 0;
	   ed_conc_pop_reset_cnt = 0;
	   sum_ed_conc = 0;

       ed_pros_pop_cnt = 0;
	   ed_pros_pop_reset_cnt = 0;
	   sum_ed_pros = 0;

	   phc_pros_pop_cnt = 0;
	   phc_pros_pop_reset_cnt = 0;
  	   sum_phc_pros = 0;

	   ltc_pros_pop_cnt = 0;
	   ltc_pros_pop_reset_cnt = 0;
  	   sum_ltc_pros = 0;

     END;


pop_grouper_pred_ind_cnt + 1;


IF ed_conc_return_code 
IN ( "00" "81")
THEN DO;
        ed_conc_pop_cnt + 1;

   		IF ed_conc_return_code = "81"
		THEN ed_conc_pop_reset_cnt + 1;

        sum_ed_conc + ed_visit_conc_unscaled_cnt;

     END;


IF ed_pros_return_code  
IN ( "00" "81")
THEN DO;
        ed_pros_pop_cnt + 1;

   		IF ed_pros_return_code = "81"
		THEN ed_pros_pop_reset_cnt + 1;

        sum_ed_pros + ed_visit_pros_unscaled_cnt;
     END;


IF phc_pros_return_code  
IN ( "00" "81")
THEN DO;
        phc_pros_pop_cnt + 1;

		IF phc_pros_return_code = "81"
		THEN phc_pros_pop_reset_cnt + 1;

		sum_phc_pros + phc_visit_pros_unscaled_cnt;
     END;


IF ltc_pros_return_code  
IN ( "00" "81")
THEN DO;
        ltc_pros_pop_cnt + 1;

		IF ltc_pros_return_code = "81"
		THEN ltc_pros_pop_reset_cnt + 1;

		sum_ltc_pros + ltc_admit_unscaled_probability;
     END;

IF eof
THEN DO;

        ed_conc_UNSCALED_average = sum_ed_conc / ed_conc_pop_cnt;

        ed_pros_UNSCALED_average = sum_ed_pros / ed_pros_pop_cnt;

        phc_pros_UNSCALED_average = sum_phc_pros / phc_pros_pop_cnt;

        ltc_pros_UNSCALED_average = sum_ltc_pros / ltc_pros_pop_cnt;

        OUTPUT;
     END;


FORMAT pop_grouper_pred_ind_cnt
       ed_conc_pop_cnt
       ed_pros_pop_cnt
       phc_pros_pop_cnt
       ltc_pros_pop_cnt COMMA012.

       phc_pros_UNSCALED_average
       ed_conc_UNSCALED_average
       ed_pros_UNSCALED_average
       ltc_pros_UNSCALED_average     11.8;

RUN;


                                                                                  /* =================== */
                                                                                  /* FORMATTED PRINT     */
                                                                                  /* =================== */

DATA _null_;

 SET pred_indicator_UNSCALED_stats ;

FILE print;


FORMAT POP_start_date 
       POP_reference_date       DATE009.;

%LET print_a_line = "----------------------------------------------------------"
                    "------------------";

PUT
    // @ 001  &PRINT_A_LINE.

    // @ 010 "POP_GROUPER_PRED_IND_CNT : " 
              pop_grouper_pred_ind_cnt
    // @ 015 "POP_START_DATE    : " pop_start_date 
     / @ 015 "POP_REFERENCE_DATE: " pop_reference_date

    // @ 010 "PRED INDICATORS "
       @ 035 "Population CNT"   @ 050 "Average UNSCALED"
     / @ 035 "--------------"   @ 050 "----------------"

    // @ 015 "PHC Prospective : " 
       @ 035 phc_pros_pop_cnt
       @ 050 phc_pros_UNSCALED_average 

    // @ 015 "ED Concurrent  : " 
       @ 035 ed_conc_pop_cnt
       @ 050 ed_conc_UNSCALED_average 

    // @ 015 "ED Prospective : " 
       @ 035 ed_pros_pop_cnt
       @ 050 ed_pros_UNSCALED_average 

    // @ 015 "LTC Prospective : " 
       @ 035 ltc_pros_pop_cnt
       @ 050 ltc_pros_UNSCALED_average 
       ;
				  
RUN;




/* ====================================================================================== */
/* Scale the predictive indicators                                                        */
/* ====================================================================================== */

DATA DTA_OUT.pop_grouper_pred_indicators
                                                /* FIRST DATASET is data */
            (KEEP = methodology_year
                    methodology_version_num
                    province_code
                    pop_start_date
                    pop_reference_date
                    person_id

                    reg_gender_code
                    hcn_valid_on_ref_date_flag
                    pop_age_group_code
                    ltc_flag
                    pop_user_code
                    person_hc_cnt 

                    user_ed_visit_avg_cnt
                    user_phc_visit_avg_cnt
                    user_ltc_admit_probability

                    phc_pros_return_code
                    phc_visit_pros_unscaled_ORIG_cnt 
                    phc_visit_pros_unscaled_cnt 
                    phc_visit_pros_scaled_cnt 

                    ed_conc_return_code
                    ed_visit_conc_unscaled_ORIG_cnt 
                    ed_visit_conc_unscaled_cnt 
                    ed_visit_conc_SCALED_cnt

                    ed_pros_return_code
                    ed_visit_pros_unscaled_cnt 
                    ed_visit_pros_unscaled_ORIG_cnt 
                    ed_visit_pros_SCALED_cnt

                   ltc_pros_return_code

                   ltc_admit_scaled_probability 
                   ltc_admit_unscaled_probability )

				                                /* ====================================== */
                                                /* SECOND OUTPUT DATASET is SCALED stats */
				                                /* ==================================== */
      pred_indicator_SCALED_stats
       (KEEP = pop_grouper_pred_ind_cnt
               pop_start_date
               pop_reference_date
               phc_pros_pop_cnt phc_pros_UNSCALED_average   USER_phc_visit_avg_cnt     phc_pros_SCALED_average 
               ed_conc_pop_cnt  ed_conc_UNSCALED_average    USER_ed_visit_avg_cnt      ed_conc_SCALED_average
               ed_pros_pop_cnt  ed_pros_UNSCALED_average                               ed_pros_SCALED_average
               ltc_pros_pop_cnt ltc_pros_UNSCALED_average   user_ltc_admit_probability ltc_pros_SCALED_average);

    SET predictive_indicators
        END = eof;


RETAIN  USER_ed_visit_avg_cnt    
        USER_phc_visit_avg_cnt   
        USER_ltc_admit_probability 

		pop_grouper_pred_ind_cnt
        ed_conc_pop_cnt   ed_conc_UNSCALED_average    sum_ed_conc_SCALED 
        ed_pros_pop_cnt   ed_pros_UNSCALED_average    sum_ed_pros_SCALED 
        phc_pros_pop_cnt  phc_pros_UNSCALED_average   sum_phc_pros_SCALED
        ltc_pros_pop_cnt  ltc_pros_UNSCALED_average   sum_ltc_pros_SCALED;


IF _n_ = 1
THEN DO;

		                                                        /* ========================== */
		                                                        /* Read the UNSCALED stats    */
		                                                        /* ========================== */
         SET pred_indicator_UNSCALED_stats
		            (KEEP = pop_grouper_pred_ind_cnt
                            phc_pros_pop_cnt phc_pros_UNSCALED_average
                            ed_conc_pop_cnt  ed_conc_UNSCALED_average
                            ed_pros_pop_cnt  ed_pros_UNSCALED_average
                            ltc_pros_pop_cnt ltc_pros_UNSCALED_average);


		                                                        /* ========================== */
                                                                /* Read the USER SCALERS      */
		                                                        /* ========================== */
         SET DTA_OUT.parameters_pred_indicators
		            (KEEP = user_phc_visit_avg_cnt
                            user_ed_visit_avg_cnt
                            user_ltc_admit_probability);

 

		                                                        /* ========================== */
		                                                        /* Set SUMS to zero           */
		                                                        /* ========================== */
         sum_ltc_pros_SCALED = 0;
         sum_ed_conc_SCALED = 0;
         sum_ed_pros_SCALED = 0;
         sum_phc_pros_SCALED = 0;

     END;



IF ed_conc_return_code = "00" &
   0.00 < USER_ed_visit_avg_cnt <= 999.99
THEN DO;
        ed_visit_conc_SCALED_cnt = 
           ed_visit_conc_unscaled_cnt * USER_ed_visit_avg_cnt / ed_conc_UNSCALED_average;
		sum_ed_conc_SCALED + ed_visit_conc_SCALED_cnt;
     END;


IF ed_pros_return_code = "00" &
   0.00 < USER_ed_visit_avg_cnt <= 999.99
THEN DO;
        ed_visit_pros_SCALED_cnt = 
           ed_visit_pros_unscaled_cnt * USER_ed_visit_avg_cnt / ed_pros_UNSCALED_average;
		sum_ed_pros_SCALED + ed_visit_pros_SCALED_cnt;
     END;

IF phc_pros_return_code = "00" &
    0.00 < USER_phc_visit_avg_cnt <= 999.99
THEN DO;
        phc_visit_pros_SCALED_cnt = 
            phc_visit_pros_unscaled_cnt * USER_phc_visit_avg_cnt / phc_pros_UNSCALED_average;
		sum_phc_pros_SCALED + phc_visit_pros_SCALED_cnt;
     END;


IF ltc_pros_return_code = "00" &
   0.00 < USER_ltc_admit_probability < 1.0000
THEN DO;
        ltc_admit_SCALED_probability =
            ltc_admit_unscaled_probability * USER_ltc_admit_probability / ltc_pros_UNSCALED_average;
		sum_ltc_pros_SCALED + ltc_admit_SCALED_probability;
     END;


OUTPUT DTA_OUT.pop_grouper_pred_indicators;

IF eof
THEN DO;
        ed_conc_SCALED_average = sum_ed_conc_SCALED / ed_conc_pop_cnt;

        ed_pros_SCALED_average = sum_ed_pros_SCALED / ed_pros_pop_cnt;

        phc_pros_SCALED_average = sum_phc_pros_SCALED / phc_pros_pop_cnt;
 
        ltc_pros_SCALED_average = sum_ltc_pros_SCALED / ltc_pros_pop_cnt;

         OUTPUT pred_indicator_SCALED_stats;
     END;


FORMAT ed_conc_pop_cnt
       ed_pros_pop_cnt
       phc_pros_pop_cnt
       ltc_pros_pop_cnt COMMA012.

       ltc_pros_SCALED_average    8.5;


RUN;


                                                                                  /* =================== */
                                                                                  /* FORMATTED PRINT     */
                                                                                  /* =================== */
OPTIONS LS = 100;

DATA _null_;

 SET pred_indicator_SCALED_stats ;

FILE print;


FORMAT POP_start_date 
       POP_reference_date       DATE009.;

%LET print_a_line = "----------------------------------------------------------"
                    "------------------";

%LET COLC = 75;

%LET COLD = 90;


PUT
    // @ 001  &PRINT_A_LINE.
    // @ 010 "PRED INDICATORS                                                        UNSCALED and SCALED   "

	// @ 020 "POP_START_DATE     : " pop_start_date
	 / @ 020 "POP_REFERENCE_DATE : " pop_reference_date

    /
	   @ &COLD "DQ Averge"
    /  @ 035 "Population CNT"   @ 050 "Average UNSCALED"
	   @ &COLC "USER"
	   @ &COLD "USER ?"

     / @ 035 "--------------"   @ 050 "----------------"

    // @ 015 "POP_GROUPER_PRED_IND_CNT : " 
             pop_grouper_pred_ind_cnt

    // @ 015 "PHC Prospective : " 
       @ 035 phc_pros_pop_cnt
       @ 050 phc_pros_UNSCALED_average 
       @ &COLC. USER_phc_visit_avg_cnt 
       @ &COLD. phc_pros_SCALED_average 

    // @ 015 "ED Concurrent  : " 
       @ 035 ed_conc_pop_cnt
       @ 050 ed_conc_UNSCALED_average 
       @ &COLC. USER_ed_visit_avg_cnt 
       @ &COLD. ed_conc_SCALED_average 

    // @ 015 "ED Prospective : " 
       @ 035 ed_pros_pop_cnt
       @ 050 ed_pros_UNSCALED_average 
       @ &COLC. USER_ed_visit_avg_cnt 
       @ &COLD. ed_pros_SCALED_average 

	   
    // @ 015 "LTC Prospective : " 
       @ 035 ltc_pros_pop_cnt
       @ 050 ltc_pros_UNSCALED_average 
       @ &COLC. user_ltc_admit_probability 
       @ &COLD. ltc_pros_SCALED_average 
       ;


RUN;

	


                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */


DATA _NULL_;

FILE print;


FORMAT start_time 
       finish_time DATETIME020.;

start_time = &pop_10_pred_01_start.;
finish_time = DATETIME();


CALL SYMPUTX ("pop_10_pred_01_finish", finish_time);


PUT // @ 010 "PRED SAS code     : &pop_10_pred_01_sas_code.                     has started running"
    // @ 010 "     Version date : &pop_10_pred_01_version_date."

    // @ 060 " Start time : " start_time
    // @ 060 "Finish time : " finish_time
       ;

RUN;

%PUT &pop_10_pred_01_start;
%PUT &pop_10_pred_01_finish;



                                                           /*==================================================*/
                                                           /* POP Total - record counts, etc                   */
                                                           /*==================================================*/
%MACRO create_pop_total_pred_indicators;


%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;



DATA DTA_OUT.pop_total_pred_indicators;

       SET DTA_OUT.parameters_pred_indicators
		            (KEEP = user_ed_visit_avg_cnt
                            user_phc_visit_avg_cnt
                            user_ltc_admit_probability);

       SET  pred_indicator_UNSCALED_stats
            (KEEP = phc_pros_pop_cnt phc_pros_UNSCALED_average phc_pros_pop_reset_cnt
                    ed_conc_pop_cnt  ed_conc_UNSCALED_average  ed_conc_pop_reset_cnt
                    ed_pros_pop_cnt  ed_pros_UNSCALED_average  ed_pros_pop_reset_cnt
                    ltc_pros_pop_cnt ltc_pros_UNSCALED_average
                    );

       SET  pred_indicator_SCALED_stats
            (KEEP = pop_grouper_pred_ind_cnt
                    pop_start_date
                    pop_reference_date
                    ed_conc_pop_cnt  ed_conc_SCALED_average
                    ed_pros_pop_cnt  ed_pros_SCALED_average
                    phc_pros_pop_cnt phc_pros_SCALED_average
                    ltc_pros_pop_cnt ltc_pros_SCALED_average
                    );




LENGTH pop_grouper_hc_riw_cnt               008.

       pop_10_pred_01_sas_code
       use_case_name             $060.;

use_case_name = "POP 1.0 - Predictive Indicators";

pop_10_pred_01_sas_code         = "&POP_10_PRED_01_SAS_CODE.";
pop_10_pred_01_version_date     = "&POP_10_PRED_01_VERSION_DATE.";

pop_10_pred_01_start  = &POP_10_PRED_01_START.;
pop_10_pred_01_finish = &POP_10_PRED_01_FINISH.;

FORMAT pop_10_pred_01_start
       pop_10_pred_01_finish     DATETIME020.;


                                                                         /* ================  */
                                                                         /* registry         */
                                                                         /* ================  */

%NOBS(DTA_OUT.pop_grouper_hc_riw);

pop_grouper_hc_riw_cnt = &NUM;
IF pop_grouper_hc_riw_cnt = . THEN pop_grouper_hc_riw_cnt = 0;



FORMAT pop_grouper_hc_riw_cnt         COMMA014.; 


RUN;

PROC PRINT DATA = DTA_OUT.pop_total_pred_indicators NOOBS;
  TITLE3         "DTA_OUT.pop_total_pred_indicators";
  TITLE5         "&DTA_OUT";
  BY use_case_name
     pop_10_pred_01_start
     pop_10_pred_01_finish;

  VAR pop_grouper_hc_riw_cnt

      user_ed_visit_avg_cnt
      user_phc_visit_avg_cnt
      user_ltc_admit_probability

      ed_conc_pop_cnt  ed_conc_pop_reset_cnt
      ed_pros_pop_cnt  ed_pros_pop_reset_cnt
      phc_pros_pop_cnt phc_pros_pop_reset_cnt
      ltc_pros_pop_cnt
      ;
RUN;


%MEND create_pop_total_pred_indicators;

%create_pop_total_pred_indicators;



/*================*/
/* End of program */
/*================*/

