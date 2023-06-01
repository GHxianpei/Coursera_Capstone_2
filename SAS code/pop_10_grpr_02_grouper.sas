
%LET pop_10_grpr_02_sas_code     = pop_10_grpr_02_grouper.sas;
%LET pop_10_grpr_02_version_date = 15DEC2016;

                                                   /*=================================*/
                                                   /* INCLUDE SES MACRO              */
                                                   /*=================================*/
%INCLUDE POP_CODE (pop_10_grpr_03_ses_macro.sas);


                                                   /*=================================*/
                                                   /* INCLUDE HPG MACRO              */
                                                   /*=================================*/
%INCLUDE POP_CODE (pop_10_grpr_04_hpg_macro.sas);



%MACRO not_in_the_use_case;

==> Keep counters for LOWEST / HIGHEST Health Conditon

        seq_id_lowest_hc = 0;
        seq_id_highest_hc = 0;
                        
%PUT &index_n44_healthy_newborn;

%PUT &index_s01_palliative_state;

%MEND not_in_the_use_case;



/*=========================================================================================*/
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*=========================================================================================*/
/*                                                                                         */
/* STRINGS set up in the METHODOLOGY TABLES                                                */
/*                                                                                         */
/* &HC_LIST - is a list of HC "A01 A02 A03 A04 . . . S81" no commas                        */
/*                                                                                         */
/* &HC_COMMA_LIST - is a list of HC "A01, A02, A03, . . ., S81" separated with commas      */
/*                                                                                         */
/* &CNT_P_HC - is a list of HC "A01, A02, A03, . . ., S81" separated with commas           */
/*                                                                                         */
/*=========================================================================================*/
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_OUT.registry_input_to_pop                                             */
/*                                                                                         */
/*               DTA_OUT.func_status_input_to_pop                                          */
/*                                                                                         */
/*               DTA_OUT.diag_input_to_pop                                                 */
/*                                                                                         */
/*                                                                                         */
/* Output File(s):                                                                         */
/*                                                                                         */
/*               DTA_OUT.pop_diag_exception
/*                                                                                         */
/*               temp_diag_blank 
/*                                                                                         */
/*               DTA_OUT.pop_diag_hcn_not_in_scope
/*               
/*               DTA_OUT.func_status_hcn_not_in_scope
/*               
/*               
/*               DTA_OUT.pop_TOTAL_DEFINE_POPULATION                                       */
/*                
/*               DTA_OUT.pop_grouper_hc_riw
/*               
/*               DTA_OUT.pop_grouper_assign_all_hc; 
/*               
/*               


/* Modifications                                                                           */
/* =============                                                                           */
/*                                                                                         */
/* 17Mar2016 - Added omhrs_flag and related DX fields                                      */
/*           - Added code to KEEP N44 and Q82 (new for 1.0)                                */
/*                                                                                         */
/* 24Mar2016 Changes for NUM_pop_HC name to sys_hc_cnt (for Beta this count is 225)        */
/*           Changes for NUM_HC references to sys_hc_cnt                                   */
/*           Use hc_LOOP_cnt for loops                                                     */
/*                                                                                         */
/*                                                                                         */
/* 31Mar2016 Added variable for index_s01_palliative_state                                 */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*=========================================================================================*/
             

                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _NULL_;

   CALL SYMPUTX ("pop_10_grpr_02_start", DATETIME() );

RUN;





                                                                              /*=================================*/
                                                                              /* UC146066 INPUT POP PARAMETERS   */
                                                                              /*=================================*/
%MACRO SET_POP_PARAMETERS;


DATA parameters_define_pop_and_group;
    SET DTA_OUT.parameters_define_pop_and_group;

                               /* ============================================= */
                               /* Check USER POP Concurrent Period parameters   */
                               /* ============================================= */

    t_day = DAY (pop_start_date);
    t_month = MONTH (pop_start_date);
    t_year = YEAR (pop_start_date) + POP_CONCURRENT_PERIOD_YEARS;

    t_ref_date = MDY(t_month, t_day, t_year) - 1;

    IF t_ref_date = pop_reference_date
    THEN user_pop_parameter_error = "N";
    ELSE user_pop_parameter_error = "Y";
   
DROP T_:;

RUN;


DATA _null_;
    SET parameters_define_pop_and_group;
    

    LENGTH methodology_year 4.   methodology_version_num 4 ;
    FORMAT methodology_year 4.   methodology_version_num 4.1 ;

    LENGTH YEAR1 YEAR2 YEAR3 4.;

    FORMAT pop_reference_date DATE9.;
    FORMAT pop_start_date DATE9.;

    YEAR1 = YEAR(pop_start_date);
    YEAR2 = year1 + 1;
    YEAR3 = year1 + 2;
    
    
    CALL SYMPUTX("methodology_year", methodology_year);
    CALL SYMPUTX("methodology_version_num", methodology_version_num);
    
    CALL SYMPUTX("pop_reference_date"         , pop_reference_date); 
    CALL SYMPUTX("pop_start_date"             , pop_start_date);

    CALL SYMPUTX("pop_concurrent_period_years", pop_concurrent_period_years);

    CALL SYMPUTX("YEAR1", YEAR1);
    CALL SYMPUTX("YEAR2", YEAR2);
    CALL SYMPUTX("YEAR3", YEAR3);
    
    CALL SYMPUTX("FUNCTIONAL_STATUS_INPUT_FLAG", FUNCTIONAL_STATUS_INPUT_FLAG);
    

    CALL SYMPUTX("USER_pop_PARAMETER_ERROR", user_pop_parameter_error);
    


RUN;

%MEND SET_POP_PARAMETERS;

%SET_POP_PARAMETERS;



%PUT &pop_start_date.;

%PUT &YEAR1.;
%PUT &YEAR2.;
%PUT &YEAR3.;
%PUT &pop_concurrent_period_years.;
%PUT &USER_pop_PARAMETER_ERROR;

%PUT &index_s01_palliative_state;

%PUT &index_n44_healthy_newborn;



/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/*                          PART 1 - PROCESS DIAGNOSIS INPUT (UC146071)                                  */
/* ===================================================================================================== */
/* ===================================================================================================== */


%MACRO PROCESS_NON_BLANK_DX_CODES;
                                      /* ============================================================================== */
                                      /*                                                                                */
                                      /* Only NON-BLANK DX codes are sent here */
                                      /*                                                                                */
                                      /* - pop_data_source_code = OK
                                      /*   ==> If the Dx is on the table count diag_processed_cnt + 1
                                      /*   ==> If the Dx is NOT on the table count DIAG_EXCEPTION_cnt
                                      /*                                                                                */
                                      /* ============================================================================== */


%POP_HEALTH_CONDITION_ASSIGN;  /* Set pop_HEALTH_COND_ASSIGN_lookup  */


IF pop_health_cond_assign_lookup = ""
THEN DO;
        /* ======================================== */
        /* POP_HEALTH_COND_ASSIGN_LOOKUP is blank   */
        /* ======================================== */
        diag_exception_cnt = diag_exception_cnt + 1;

        pop_diag_return_code = "30"; 
		OUTPUT  DTA_OUT.pop_diag_exception;
     END; 

ELSE DO;
        /* ================================================= */
        /* pop_health_cond_assign_lookup is NOT (it's valid!)  */
        /* ================================================= */
        diag_processed_cnt = diag_processed_cnt + 1;

        health_condition_code = SUBSTR(pop_health_cond_assign_lookup, 1, 4);

        IF health_condition_code NE "ZZZZ" 
        THEN DO;                            /* HC NE "ZZZZ" */

                plpb_tag_rule = SUBSTR(pop_health_cond_assign_lookup, 8, 1);

                hc_seq_id = SUBSTR(pop_health_cond_assign_lookup, 5, 3) * 1.0;

                IF pop_data_source_code = "PLPB" 
                THEN DO;
                        /* ================================== */   
                        /* The TAG RULES apply ONLY to PLPB   */
                        /* ================================== */   
                        IF plpb_tag_rule = "0" 
                        THEN DO;
                                /* ========================================== */
                                /* Nothing - the PLPB data is ignored !       */
                                /* ==> This condition must be set             */
                                /*     using DAD, NACRS, CCRS or OMHRS data   */
                                /* ========================================== */
                             END;
                        ELSE 

                        IF plpb_tag_rule = "1" 
                        THEN DO;
                                health_condition_{hc_seq_id} = 1;
                             END;
                        ELSE 

                        IF plpb_tag_rule > "1" 
                        THEN DO;
                                plpb_hc_cnt_{hc_seq_id} = plpb_hc_cnt_{hc_seq_id} + 1;
                                plpb_tag_rule_{hc_seq_id} = plpb_tag_rule * 1.0;
                             END;

                    END;
               ELSE DO;
                       /* ================================== */   
                       /* pop_data_source_code is NOT PLPB        */
                       /* The TAG RULES do NOT apply here    */
                       /* ================================== */ 
                       health_condition_{hc_seq_id} = 1;
                    END; 

             END;                          /* HC NE "ZZZZ" */

     END;


%MEND PROCESS_NON_BLANK_DX_CODES;



DATA temp_pop_grouper_assign
        (DROP = pop_health_cond_assign_key 
                pop_health_cond_assign_lookup
                physician_id
                service_date
                pop_data_source_code
                data_source_id
                diag_classification_code
                diag_code
                diag_orig_code
                health_condition_code
                hc_seq_id
                plpb_tag_rule)


     DTA_OUT.pop_diag_exception
            (KEEP = methodology_year
                    methodology_version_num
                    province_code
                    person_id
                    pop_data_source_code
                    data_source_id
                    service_date
                    physician_id
                    diag_classification_code
                    diag_orig_code
                    diag_code
                    reg_dob
                    reg_gender_code
                    reg_date_of_death

                    pop_diag_return_code)

     temp_system_diag_counts
            (KEEP = sys_diag_person_id_cnt
                    sys_diag_input_to_pop_cnt
                    sys_diag_processed_cnt
                    sys_diag_exception_cnt
                    sys_diag_blank_cnt)
              ;


    LENGTH  health_condition_code $4.  
            pop_diag_return_code  $2.;

    LENGTH  inpatient_flag 
            day_surgery_flag 
            emergency_flag 
            clinic_flag 
            physician_flag 
            ltc_flag 
            ccc_flag
            omhrs_flag 
            pop_exclusion_flag    $1.;

    RETAIN inpatient_flag 
            day_surgery_flag 
            emergency_flag 
            clinic_flag 
            physician_flag 
            ltc_flag 
            ccc_flag    
            omhrs_flag 
            pop_exclusion_flag;
           
                                                                 /* Arrays for EACH POP HC (but NOT ZZZZ) */ 
    ARRAY health_condition_{&sys_hc_cnt.} 3. &HC_LIST. ;
    RETAIN &HC_LIST.;

    ARRAY plpb_tag_rule_{&sys_hc_cnt.}    3. plpb_tag_rule_001 - plpb_tag_rule_%SYSFUNC(PUTN(&sys_hc_cnt., Z3));
    RETAIN plpb_tag_rule_001 - plpb_tag_rule_%SYSFUNC(PUTN(&sys_hc_cnt., Z3)) ;

    ARRAY plpb_hc_cnt_{&sys_hc_cnt.}      3. &CNT_P_HC. ;
    RETAIN &CNT_P_HC.;

    SET DTA_OUT.diag_input_to_pop
        END = last;

    BY person_id;


RETAIN diag_input_to_pop_cnt   sys_diag_input_to_pop_cnt
       diag_processed_cnt      sys_diag_processed_cnt
       diag_exception_cnt      sys_diag_exception_cnt
       diag_blank_cnt          sys_diag_blank_cnt
                               sys_diag_person_id_cnt;

IF _n_ = 1
THEN DO;
        sys_diag_input_to_pop_cnt = 0;
        sys_diag_blank_cnt = 0;
        sys_diag_exception_cnt = 0;
        sys_diag_processed_cnt = 0;
        sys_diag_person_id_cnt = 0;
     END; 


                                      /* ========================================== */
                                      /* UC146077: INITIALIZE HC VARIABLES          */
                                      /* ========================================== */
IF FIRST.person_id 
THEN DO;

        pop_diag_return_code = "00";
        sys_diag_person_id_cnt + 1;

        DO i = 1 TO &sys_hc_cnt.;
            health_condition_{i} = 0;
            plpb_tag_rule_{i}    = 0;
            plpb_hc_cnt_{i}      = 0;
        END;

        inpatient_flag = "N";
        day_surgery_flag = "N";
        emergency_flag = "N";
        clinic_flag = "N";
        physician_flag = "N";
        ltc_flag = "N";
        ccc_flag = "N";
        omhrs_flag = "N";

        pop_exclusion_flag = "N";

        diag_input_to_pop_cnt = 0;
        diag_blank_cnt = 0;
        diag_exception_cnt = 0;
        diag_processed_cnt = 0;

     END; 


diag_input_to_pop_cnt = diag_input_to_pop_cnt + 1;
   

                                      /* ============================================================================== */
                                      /* UC146073: ASSIGN HEALTH CONDITION                                              */
                                      /* Note - Each HC can be set to one MULTIPLE times (no check for "already set")   */ 
                                      /* ============================================================================== */

                                      /* =========================================================== */
                                      /* UC165991: DERIVE DATA FLAGS   (check pop_data_source_code)       */
                                      /* 2016-04-20 MAJOR re-wrtite of approach /logic               */
                                      /* =========================================================== */




/* ========================================================================= */
/* DROP_BLANKS_PROCESS_OTHERS                                                */
/* - LOTS of PLPB (and some other records) will have a BLANK DX code         */
/* ========================================================================= */
%MACRO drop_blanks_process_others;

  IF diag_code = " "
  THEN DO;
          diag_blank_cnt + 1;
       END;
  ELSE DO;
          %PROCESS_NON_BLANK_DX_CODES;
       END;

%MEND drop_blanks_process_others;



IF pop_data_source_code = "PLPB"                  
THEN DO;
        physician_flag = "Y";    /* PLPB has the highest volume */
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "DAD-IP"                
THEN DO;
        inpatient_flag = "Y" ;  
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code IN ("DAD-DS",
                            "NACRS-DS") 
THEN DO;
        day_surgery_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "NACRS-ED"              
THEN DO;
        emergency_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "NACRS-CL"              
THEN DO;
        clinic_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "CCRS-LTC"              
THEN DO;
        ltc_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "CCRS-CCC"              
THEN DO;
        ccc_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE 

IF pop_data_source_code = "OMHRS"                 
THEN DO;
        omhrs_flag = "Y" ;
        %DROP_BLANKS_PROCESS_OTHERS;
     END;
ELSE DO;
        /* ===================================== */
        /* pop_data_source_code is invalid            */
        /* ===================================== */
        diag_exception_cnt = diag_exception_cnt + 1;
        pop_diag_return_code = "10";
        OUTPUT DTA_OUT.pop_diag_exception;                  /* This should NOT happen !! */
     END; 


                                      /* ========================================== */
                                      /* UC146075: PROCESS TAGGING RULES for PLPB data */
                                      /* ========================================== */
IF LAST.person_id  
THEN DO;

        seq_id_lowest_hc = 0;
        seq_id_highest_hc = 0;
            

        DO loop_hc_cnt = 1 TO &sys_hc_cnt.;

           IF health_condition_{loop_hc_cnt} = 0 AND 
              plpb_tag_rule_{loop_hc_cnt} > 1 
           THEN DO;
                    IF plpb_hc_cnt_{loop_hc_cnt} >= plpb_tag_rule_{loop_hc_cnt} 
                    THEN DO;
                            health_condition_{loop_hc_cnt} = 1;
                         END;
                END;

            IF health_condition_{loop_hc_cnt} = 1
            THEN DO;
                    IF seq_id_lowest_hc = 0 
                    THEN seq_id_lowest_hc = loop_hc_cnt;

                    seq_id_highest_hc = loop_hc_cnt;
 
                 END;

        END; /* Loop */

        person_hc_orig_cnt = SUM(OF &HC_LIST.) ;
 
        OUTPUT temp_pop_grouper_assign;

        sys_diag_input_to_pop_cnt + diag_input_to_pop_cnt;
        sys_diag_blank_cnt + diag_blank_cnt;
        sys_diag_exception_cnt + diag_exception_cnt;
        sys_diag_processed_cnt + diag_processed_cnt;

    END; 


IF last
THEN DO;
        OUTPUT temp_system_diag_counts;
     END;


DROP i;


RUN;


OPTIONS LS = 100;



%MACRO review;

PROC CONTENTS DATA = temp_pop_grouper_assign;
RUN;


PROC PRINT DATA = temp_system_diag_counts NOOBS UNIFORM;
    TITLE3       "temp_system_diag_counts                                  Step 1 ";

    FORMAT sys_diag_person_id_cnt
           sys_diag_input_to_pop_cnt 
           sys_diag_blank_cnt 
           sys_diag_exception_cnt 
           sys_diag_processed_cnt   COMMA012.;

RUN;

PROC PRINT DATA = temp_pop_grouper_assign NOOBS UNIFORM;
    TITLE3       "temp_pop_grouper_assign                                  Step 1 ";
    WHERE diag_exception_cnt > 0;

    VAR person_id

        person_hc_orig_cnt
        seq_id_lowest_hc
        seq_id_highest_hc
        diag_input_to_pop_cnt 
        diag_blank_cnt 
        diag_exception_cnt 
        diag_processed_cnt 
        ;
RUN;



%MEND review;



/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */



                                       /* ========================================== */
                                      /* UC146076: MERGE FILES                      */
                                      /* UC146078: ASSIGN USER code                 */
                                      /* ========================================== */


DATA temp_pop_grouper_assign
            (DROP = population_cnt 
                    non_user_cnt
                    user_cnt 
                    user_with_hc_cnt 
                    user_zero_hc_cnt
                    ) 

     DTA_OUT.pop_diag_hcn_not_in_scope
            (KEEP = methodology_year
                    methodology_version_num
                    province_code
                    person_id

                    pop_diag_return_code
                    )

     temp_user_non_user_counters       
            (KEEP = population_cnt 
                    non_user_cnt
                    user_cnt 
                    user_with_hc_cnt 
                    user_zero_hc_cnt
                    ) 
            ;

LENGTH methodology_year 4.   methodology_version_num 4 ;
RETAIN methodology_year          &METHODOLOGY_YEAR.
       methodology_version_num   &METHODOLOGY_VERSION_NUM.;

    FORMAT  reg_dob  
            reg_date_of_death    
            pop_reference_date  
            pop_start_date  DATE9.;
            
    LENGTH pop_user_code $2.
           pop_return_code $2.;

    LENGTH  non_user_cnt  
            user_cnt

            user_with_hc_cnt
            user_zero_hc_cnt
            population_cnt   8.;


    ARRAY health_condition_ {&sys_hc_cnt.}  3. &HC_LIST. ;
    ARRAY plpb_tag_rule_    {&sys_hc_cnt.}  3. plpb_tag_rule_001 - plpb_tag_rule_%SYSFUNC(PUTN(&sys_hc_cnt., Z3));
    ARRAY plpb_hc_cnt_      {&sys_hc_cnt.}  3. &CNT_P_HC. ;        

    RETAIN population_cnt      0
           non_user_cnt        0 
           user_cnt            0
           user_with_hc_cnt    0
           user_zero_hc_cnt    0;


    MERGE   DTA_OUT.reg_input_to_pop
                (IN = registry
                 KEEP = province_code
                        person_id
                        reg_dob
                        reg_gender_code
                        reg_date_of_death

                        pop_age_num
                        hcn_valid_on_ref_date_flag 


                        reg_postal_code         /* Required for GEO mapping */
						region_code
						da06uid
						qaippe06
						da11uid
						qaippe11
                 )

            temp_pop_grouper_assign  
                (IN = pop_health_conditions
                 DROP = methodology_year
                        methodology_version_num
                 )
           END = last_record;

    BY  province_code
                
        person_id
        reg_dob
        reg_gender_code
        reg_date_of_death;
 

RETAIN  pop_reference_date          &POP_REFERENCE_DATE.  
        pop_start_date              &POP_start_DATE.
        pop_concurrent_period_years &POP_CONCURRENT_PERIOD_YEARS.;

FORMAT  pop_reference_date  
        pop_start_date  DATE009.;

    
IF registry &
   pop_health_conditions
THEN DO;
        pop_return_code = "00";

        /* ======================================================= */
        /* USERS - On both the registry and diagnoses files        */
        /*   pop_user_code = 00 if there are Zero HCs              */
        /*                 = 01 if there are 1+ HCs                */
        /* ======================================================= */
 

        /* ======================================================= */
        /* UC192741 Assign Newborns                   2016-05-12   */
        /* ======================================================= */
        %MACRO USER_n44_update_lo_hi;

                N44 = 1;
                person_hc_orig_cnt = person_hc_orig_cnt + 1;

				IF person_hc_orig_cnt = 1
				THEN DO;
                        seq_id_lowest_hc = &index_n44_healthy_newborn.;
                        seq_id_highest_hc = &index_n44_healthy_newborn.;
	                 END;
				ELSE

                IF seq_id_lowest_hc > &index_n44_healthy_newborn.
                THEN seq_id_lowest_hc = &index_n44_healthy_newborn.;

                IF seq_id_highest_hc < &index_n44_healthy_newborn.
                THEN seq_id_highest_hc = &index_n44_healthy_newborn.;

        %MEND USER_n44_update_lo_hi;        

        IF &POP_CONCURRENT_PERIOD_YEARS. = 2 &           /* EXPECTATION is that this is most frequent */
           pop_age_num IN (0, 1)
        THEN DO;
                 %USER_N44_UPDATE_LO_HI;
             END;
        ELSE
        IF &POP_CONCURRENT_PERIOD_YEARS. = 3 & 
           pop_age_num IN (0, 1, 2)
        THEN DO;
                 %USER_N44_UPDATE_LO_HI;
             END;
        ELSE
        IF &POP_CONCURRENT_PERIOD_YEARS. = 1 & 
           pop_age_num IN (0)
        THEN DO;
                 %USER_N44_UPDATE_LO_HI;
             END;


        /* ======================================================= */
        /* USERS - On both the registry and diagnoses files        */
        /*   pop_user_code = 00 if there are Zero HCs              */
        /*                 = 01 if there are 1+ HCs                */
        /* ======================================================= */

        population_cnt = population_cnt + 1; 

        user_cnt = user_cnt + 1;

        IF person_hc_orig_cnt > 0 
        THEN DO;
                pop_user_code = "01" ;   /* Users WITH health conditions */
				                         /* ==> Includes Babies with N44 who have no other conditions */
                user_with_hc_cnt + 1;
             END;
        ELSE DO;
                pop_user_code = "00" ;   /* Users WITH ZERO health conditions */
                user_zero_hc_cnt + 1;
             END;


        OUTPUT temp_pop_grouper_assign;
    END;

ELSE
IF registry and 
   NOT pop_health_conditions                                                       /* STEP 6B */
THEN DO;
        /* ======================================================= */
        /* NON-USERS                     pop_user_code = 98        */
        /*      - On the registry ONLY (no diagnoses records)      */
        /*      - Initializae Ds related POP variables to zero     */
        /* ======================================================= */
        pop_return_code = "00";
        pop_user_code = "98";

        non_user_cnt = non_user_cnt + 1;

        population_cnt = population_cnt + 1;      


        /* =================================== */
        /* UC146077: INITIALIZE HC VARIABLE    */
        /* =================================== */

        inpatient_flag = "N";
        day_surgery_flag = "N";
        emergency_flag = "N";
        clinic_flag = "N";
        physician_flag = "N";
        ltc_flag = "N";
        ccc_flag = "N";
        omhrs_flag = "N";

        pop_exclusion_flag = "N";

        diag_input_to_pop_cnt = 0;
        diag_processed_cnt = 0;
        diag_exception_cnt = 0;
        diag_blank_cnt = 0;

        DO hc_seq_id = 1 TO &sys_hc_cnt.;
              health_condition_{hc_seq_id} = 0 ;
              plpb_tag_rule_{hc_seq_id} = 0;
              plpb_hc_cnt_{hc_seq_id} = 0;
        END;

        seq_id_lowest_hc = 0;
        seq_id_highest_hc = 0;

        person_hc_orig_cnt = 0;


        /* ======================================================= */
        /* UC192741 Assign Newborns                   2016-11-28   */
        /*                                                         */
        /*    Non-User BABIES are made into USERS                  */
        /*                                                         */
        /* ======================================================= */
        %MACRO non_user_n44_update_lo_hi;

                N44 = 1;
                pop_user_code = "01";

                person_hc_orig_cnt = person_hc_orig_cnt + 1;
                seq_id_lowest_hc = &index_n44_healthy_newborn.;
                seq_id_highest_hc = &index_n44_healthy_newborn.;

                                                     /* Adjust User Non-User counts */
		        non_user_cnt = non_user_cnt - 1;
		        user_cnt = user_cnt + 1;
				user_with_hc_cnt  = user_with_hc_cnt + 1;


        %MEND non_user_n44_update_lo_hi;        

        IF &POP_CONCURRENT_PERIOD_YEARS. = 2 &           /* EXPECTATION is that this is most frequent */
           pop_age_num IN (0, 1)
        THEN DO;
                 %non_user_N44_UPDATE_LO_HI;
             END;
        ELSE
        IF &POP_CONCURRENT_PERIOD_YEARS. = 3 & 
           pop_age_num IN (0, 1, 2)
        THEN DO;
                 %non_user_N44_UPDATE_LO_HI;
             END;
        ELSE
        IF &POP_CONCURRENT_PERIOD_YEARS. = 1 & 
           pop_age_num IN (0)
        THEN DO;
                 %non_user_N44_UPDATE_LO_HI;
             END;

        OUTPUT temp_pop_grouper_assign;
     END;

ELSE DO;

        /* ======================================================= */
        /* Only on the pop_HEALTH_CONDITIONS file                  */
        /* ==> NOT on the REGISTRY                                 */ 
        /* ======================================================= */
        pop_diag_return_code = "03";
        OUTPUT DTA_OUT.pop_diag_HCN_not_in_scope;
                        
     END;



IF last_record
THEN OUTPUT temp_user_non_user_counters;


                    /* ======================================================= */
                    /* The ARRAY variables are no longer needed                */
                    /* ======================================================= */
DROP hc_seq_id;

DROP  plpb_tag_rule:
      cnt_p:
      ;



RUN;




PROC PRINT DATA = temp_pop_grouper_assign;
   TITLE3 "temp_pop_grouper_assign                              DQ PROBLEM ";
   BY province_code;

   WHERE person_hc_orig_cnt = 1 & 
         seq_id_lowest_hc NE seq_id_highest_hc;

   VAR person_id
       person_hc_orig_cnt
       seq_id_lowest_hc
       seq_id_highest_hc;
RUN;


%MACRO review;

PROC PRINT DATA = temp_user_non_user_counters;
    TITLE3 "temp_user_non_user_counters";
RUN;

PROC FREQ DATA = temp_pop_grouper_assign;
   TITLE3 "temp_pop_grouper_assign                               BEFORE SES module";
   TITLE5 "DTA_OUT.";
   BY province_code;
   TABLES region_code * pop_user_code
          da06uid * da11uid
		  qaippe06 * qaippe11
         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA010.;
   FORMAT da06uid
          da11uid    $002.;
RUN;

PROC FREQ DATA = temp_pop_grouper_assign ;
    TITLE3       "temp_pop_grouper_assign              after SES module";
    BY pop_start_date
       pop_reference_date 
       pop_concurrent_period_years;
   TABLES pop_age_num * hcn_valid_on_ref_date_flag
          methodology_year
          methodology_version_num
         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA012.;
RUN;



PROC PRINT DATA = temp_user_non_user_counters NOOBS;
    TITLE3       "temp_user_non_user_counters";
RUN;


PROC PRINT DATA = DTA_OUT.pop_diag_HCN_not_in_scope NOOBS;
    TITLE3       "DTA_OUT.pop_diag_HCN_not_in_scope";
            BY methodology_year
       methodology_version_num;
    VAR person_id
        person_hc_orig_cnt
        diag_input_to_pop_cnt 
                        diag_blank_cnt 
                        diag_exception_cnt 
                        diag_processed_cnt 
                        M41
                        M42
                        M43

        ;
RUN;


PROC PRINT DATA = temp_pop_grouper_assign NOOBS;
    TITLE3       "temp_pop_grouper_assign             USERS + NON-USERS";
            BY methodology_year
       methodology_version_num;

    WHERE n41 = 1 OR n42 = 1 OR n43 = 1;
    WHERE SUBSTR (person_id, 001, 004) = "MOM_";

            VAR person_id
        pop_user_code
        person_hc_orig_cnt
        M:

        ;
RUN;

%MEND review;




/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/*  Input file(s) : temp_pop_grouper_assign
/*
/*  Output file(s): DTA_OUT.pop_grouper_ses
/* 
/*                  DTA_OUT.pop_total_ses
/* 
/* ===================================================================================================== */


%create_pop_grouper_ses;                  


%MACRO review_pop_grouper_ses;


PROC CONTENTS DATA = DTA_OUT.pop_grouper_ses ;
RUN;

PROC FREQ DATA = DTA_OUT.pop_grouper_ses ;
    TITLE3      "DTA_OUT.pop_grouper_ses";

   TABLES pop_ses_canmarg_return_code * pop_ses_inspq_return_code

          region_code
         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA012.;
RUN;

%MEND  review_pop_grouper_ses;


/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */


                                                  /* ========================================================== */
                                                  /* UC169751: MERGE FUNCTIONAL STATUS                          */
                                                  /* ==>  functional_status_input_flag                          */
                                                  /* ========================================================== */


%MACRO functional_status_input_flag_N;

/* ================================================ */
/* The functional_status_input_flag was NOT  "Y"    */
/*                                                  */
/* Set                                              */
/*   - the functional status scores to blanks       */
/*   - pop_func_status_return_code = 35             */
/*                                                  */
/* ================================================ */

DATA temp_pop_grouper_assign;
   SET temp_pop_grouper_assign;

RETAIN pop_func_status_return_code "35";
       

LENGTH functional_status_input_flag $001.;

functional_status_input_flag = "&FUNCTIONAL_STATUS_INPUT_FLAG.";

LENGTH aggression_behaviour_scale 
       act_daily_living_hier_score  
       cognitive_performance_score 
       chess_level
       pain_scale 
       pressure_ulcer_risk_scale    3.;


aggression_behaviour_scale = .;
act_daily_living_hier_score = .;  
cognitive_performance_score = .;
chess_level = .;
pain_scale = .;
pressure_ulcer_risk_scale = .;

RUN;


%MEND functional_status_input_flag_N;


%MACRO functional_status_input_flag_Y;


/* ================================================================ */
/* The functional_status_input_flag = "Y"                           */
/*                                                                  */
/* - Add the functional status scores                               */
/* - Set POP_FUNC_STATUS_RETURN_CODE                                */
/*       00 - Match                                                 */
/*       37 - OK (No FS record for the person)                      */
/*                                                                  */
/*       36 - FS record but the person is NOT on the grouper file   */
/*                                                                  */
/* ================================================================ */

DATA temp_pop_grouper_assign
            (DROP = service_date)

     DTA_OUT.pop_func_hcn_not_in_scope 
	        (KEEP = province_code
                    person_id
                    service_date
                    pop_func_status_return_code);

    LENGTH pop_func_status_return_code $002.;


    MERGE temp_pop_grouper_assign
                 (IN = pop_grouper)
          DTA_OUT.func_status_input_to_pop
                 (IN = FUNC_STATUS
                  KEEP = province_code
                         person_id
                         service_date

                         aggression_behaviour_scale 
                         act_daily_living_hier_score 
                         chess_level 
                         cognitive_performance_score 
                         pain_scale 
                         pressure_ulcer_risk_scale);

    BY province_code
       person_id; 

RETAIN functional_status_input_flag "&FUNCTIONAL_STATUS_INPUT_FLAG.";

IF pop_grouper AND
   NOT (FUNC_STATUS) 
THEN DO; 
        /* ==================================================== */
        /* Most cases (these are NOT CCRS residents)            */ 
        /* - There is NO Func Status record                     */
        /* - the values will be MISSING                         */
        /* ==================================================== */
        pop_func_status_return_code = "37";
        OUTPUT temp_pop_grouper_assign;
    END;
ELSE 

IF pop_GROUPER AND
   FUNC_STATUS
THEN DO; 
        IF MISSING(aggression_behaviour_scale)  THEN aggression_behaviour_scale = "99";
        IF MISSING(act_daily_living_hier_score) THEN act_daily_living_hier_score = "9";  
        IF MISSING(cognitive_performance_score) THEN cognitive_performance_score = "9";
        IF MISSING(chess_level)                 THEN chess_level = "9";
        IF MISSING(pain_scale)                  THEN pain_scale = "9";
        IF MISSING(pressure_ulcer_risk_scale)   THEN pressure_ulcer_risk_scale = "9";
 
        pop_func_status_return_code = "00";
        OUTPUT temp_pop_grouper_assign;
    END;

ELSE DO;
        /* ==================================================== */
        /* These records are on the Functional Status file ONLY */
        /* ==================================================== */
        pop_func_status_return_code = "36";
        OUTPUT DTA_OUT.pop_func_hcn_not_in_scope;
     END;


RUN;

%MEND functional_status_input_flag_Y;



%MACRO FUNCTIONAL_STATUS_PATH_Y_OR_N;

%IF "&FUNCTIONAL_STATUS_INPUT_FLAG." = "Y"
%THEN %functional_status_input_flag_Y;    
%ELSE %functional_status_input_flag_N;     

%MEND FUNCTIONAL_STATUS_PATH_Y_OR_N;

%FUNCTIONAL_STATUS_PATH_Y_OR_N;



%MACRO review_func_status;


PROC FREQ DATA = temp_pop_grouper_assign;
    TITLE3      "temp_pop_grouper_assign";
    BY functional_status_input_flag ;
    TABLES pop_age_num * pop_func_status_return_code 
ltc_flag

         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA012.;
RUN;

%MEND  review_func_status;


/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */

                             /* ================================================== */
                             /* Create POP_GROUPER_ASSIGN_ALL_HC                   */
                             /* - This file has the HCs . . . BEFORE OVERRIDES     */
                             /* ================================================== */



DATA DTA_OUT.pop_grouper_assign_all_hc;

   SET temp_pop_grouper_assign;
   BY methodology_year
      methodology_version_num;

                                              /* Identify variables to KEEP on pop_grouper_assign */
KEEP  province_code
      person_id
	  reg_gender_code
      methodology_year
      methodology_version_num

      pop_start_date
      pop_reference_date
      pop_concurrent_period_years

      diag_input_to_pop_cnt
      diag_processed_cnt
      diag_exception_cnt
      diag_blank_cnt

      pop_start_date
      pop_reference_date
      pop_concurrent_period_years

	  pop_return_code
      pop_user_code

      person_hc_orig_cnt


      &HC_LIST. ;           /* hc_LIST contains ALL POP Health Conditions (A01 . . . S81) */

RUN;


%MACRO pop_grouper_assign_all_hc;

PROC FREQ DATA = DTA_OUT.pop_grouper_assign_all_hc;  ;
   TITLE3       "DTA_OUT.pop_grouper_assign_all_hc; ";
   BY methodology_year
      methodology_version_num;
   TABLES
          f: * pop_user_code
              n: * pop_user_code
              p0: * pop_user_code
              p4: * pop_user_code
          s: * pop_user_code

          m4: * reg_gender_code

          person_hc_orig_cnt * pop_user_code 

pop_user_code * person_hc_orig_cnt * n44    

         /MISSING NOROW NOCOL NOPERCENT  FORMAT = COMMA009.;
RUN;


PROC PRINT DATA = DTA_OUT.pop_grouper_assign_all_hc;  ;
   TITLE3        "DTA_OUT.pop_grouper_assign_all_hc; ";
   WHERE S01 = 1;
   WHERE SUBSTR (person_id,001, 008) = "PRED_LTC";

RUN;

%MEND pop_grouper_assign_all_hc;



/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */
/* ===================================================================================================== */

/* ================================================ */
/* Multiple processed                               */
/*    - Assign Clinical Overrides                   */
/*                                                  */
/*    - Assign Additive Weights                     */
/*                                                  */
/*    - Assign HSG info (included SAS Macro)        */
/*                                                  */
/*                                                  */
/* ================================================ */



/* ======================================================================================================= */
/* POP_ASSIGN_CLINICAL_OVERRIDES ==> UC146079: ASSIGN HC OVERRIDE                                          */
/*                                                                                                         */
/* 2016-03-29 Override LOOP change from '1 To &sys_hc_cnt." to "seq_id_lowest_hc TO seq_id_highest_hc)       */
/*                                                                                                         */
/* ======================================================================================================= */
%MACRO POP_ASSIGN_CLINICAL_OVERRIDES;

person_hc_cnt = 0;

/* ============================================ */
/* make a copy of the ORIG health conditions    */
/* ============================================ */
DO i = 1 TO &sys_hc_cnt.;
    health_condition_orig_{i} = health_condition_{i};
END; 


/*============================================*/
/* If S01 - Palliative State is set
/* ==> OVERRIDE all other conditions        
/*
/*============================================*/
IF health_condition_{&index_s01_palliative_state.} = 1 
THEN DO;

         person_hc_cnt = 1;

         DO i = 1 TO (&index_s01_palliative_state. - 1);
                health_condition_{i} = 0;
         END;

         DO i = (&index_s01_palliative_state. + 1) TO &sys_hc_cnt.;
                health_condition_{i} = 0;
         END;

    END;  /* S01 = 1 processing */
    
ELSE
IF person_hc_orig_cnt > 1    /* 1+ HCs and not S01 */
THEN DO;

         /* ======================================================== */
         /* POP health Condition Override                            */
         /* Two codes - HEALTH_CONDITION_code and hc_override_code   */
         /* ==> If you have both set the "override" to zero          */
         /*     i = FIRST HC                                         */
         /*     j = Override HC                                      */
         /*                                                          */
         /* 1.0 New flags for Lowest / Highest HC                    */
         /*        seq_id_lowest_hc                                   */
         /*        seq_id_highest_hc                                  */
         /*                                                          */
         /* ======================================================== */

         DO i = seq_id_lowest_hc TO seq_id_highest_hc;

                 IF health_condition_orig_{ i } = 1 
                 THEN DO j = seq_id_lowest_hc TO seq_id_highest_hc;

                               IF health_condition_orig_{ j } = 1 
                               THEN DO;
                                       health_condition_code_1 = VNAME(health_condition_{ i });
                                       health_condition_code_2 = VNAME(health_condition_{ j });  

                                       %POP_HEALTH_CONDITION_OVERRIDE;  /* See METHODOLOGY TABLES */

                                       IF pop_hc_override_lookup = "Y" 
                                       THEN DO;
                                               health_condition_{ j } = 0;
                                            END;
                                   END;

                     END; ;

           END; 

         person_hc_cnt = SUM(OF &HC_LIST.) ;

     END;
ELSE DO;
        /* ================================================== */
        /* Zero or one HCs are set - no interactions possible */
        /* ================================================== */
        person_hc_cnt = person_hc_orig_cnt;
     END;
       
 
person_hc_override_cnt = person_hc_orig_cnt - person_hc_cnt;


DROP i
     j
     ;

%MEND POP_ASSIGN_CLINICAL_OVERRIDES;



/* ======================================================================================================= */
/*                                                                                                         */
/* UC146084: Assign Additive Weight                                                                        */
/*                                                                                                         */
/*                                                                                                         */
/* 2016-03-29 Changes to make loops easier to read / more efficient                                        */
/*                                                                                                         */
/* ======================================================================================================= */


%MACRO POP_ASSIGN_ADDITIVE_WEIGHTS;

pop_prospective_riw = 0;
pop_concurrent_riw = 0;

pop_riw_return_code = "00" ;
pop_age_group_code = "99"; 


LENGTH pop_hc_riw_key $8. 
       pop_hc_riw_lookup $20.;

                                          /* ======================================= */
                                          /* UC146082: ASSIGN AGE GROUPS             */
                                          /* ======================================= */
%POP_AGE_GROUP_ASSIGN;

IF pop_age_group_assign_lookup = " "
THEN DO;
        pop_exclusion_flag = "Y";
        pop_riw_return_code = "30";
     END;
ELSE DO;
         pop_age_group_code = pop_age_group_assign_lookup;
     END;



IF pop_user_code IN ("01") 
THEN DO;                            /* User with 1+ Health conditions */



%MACRO add_NUSER_wts;      /* TESTING TESTING TESTING */

     pop_user_code = "98";
   %POP_NO_HC_RIW;   /* See POP_METHODOLGOY_TABLES */
   NUSER_prospective_riw = SUBSTR(POP_NO_HC_RIW_lookup, 1, 10) * 1.0;
   NUSER_concurrent_riw  = SUBSTR(POP_NO_HC_RIW_lookup, 11, 10)* 1.0;

     pop_user_code = "00";
   %POP_NO_HC_RIW;   /* See POP_METHODOLGOY_TABLES */
   NOHC_prospective_riw = SUBSTR(POP_NO_HC_RIW_lookup, 1, 10) * 1.0;
   NOHC_concurrent_riw  = SUBSTR(POP_NO_HC_RIW_lookup, 11, 10)* 1.0;

%MEND add_NUSER_wts;      /* TESTING TESTING TESTING */



%ADD_NUSER_WTS;



        pop_user_code = "01";

        max_prospective_factor = 0;

        max_concurrent_factor = 0; 

        hc_index = 1;     /* HC_INDEX is set to find pre-set HCs*/


		/* ============================= */
        /* Derive the ADDITIVE weights   */
        /* ============================= */
        DO loop_hc_cnt = /*  seq_id_lowest_hc TO seq_id_highest_hc */ 1 TO &sys_hc_cnt. ;

            IF health_condition_ { loop_hc_cnt } = 1 
            THEN DO;

                    hc_{hc_index} = loop_hc_cnt;
                    hc_index = hc_index + 1;

                    health_condition_code = COMPRESS(VNAME(health_condition_ {loop_hc_cnt}));

                    pop_hc_riw_key = PUT(methodology_year, Z4.) || health_condition_code ;

                    pop_hc_riw_lookup = PUT(pop_hc_riw_key, $POP_HEALTH_CONDITION_RIW.);
                

                    IF NOT MISSING(pop_hc_riw_lookup) 
                    THEN DO;
                            hc_prospective_factor = SUBSTR(pop_hc_riw_lookup, 1, 10) * 1.0;

                            IF hc_prospective_factor > max_prospective_factor 
                            THEN max_prospective_factor = hc_prospective_factor;

                            hc_concurrent_factor = SUBSTR(pop_hc_riw_lookup, 11, 10) * 1.0;

                            IF hc_concurrent_factor > max_concurrent_factor 
                            THEN max_concurrent_factor = hc_concurrent_factor;

                            pop_prospective_riw = pop_prospective_riw + hc_prospective_factor;

                            pop_concurrent_riw = pop_concurrent_riw + hc_concurrent_factor;
                        END;

                   ELSE DO;
                                            /* HC RIW lookup failed !!!! */
                           pop_exclusion_flag = "Y";
                           pop_riw_return_code = "42";
                           pop_prospective_riw = 0;
                           pop_concurrent_riw = 0;
    
                           loop_hc_cnt = &sys_hc_cnt. ;   /* Get out of the loop */

                        END;

                END; /* HEALTH_CONDITION(loop_hc_cnt) is 1 */

        END;


       hc_index = hc_index - 1;


       /*===================================*/
       /* Adjust RIWs for INTERACTIONS      */
       /*===================================*/
        
       original_prospective_riw = pop_prospective_riw;
       original_concurrent_riw = pop_concurrent_riw;
       original_max_prospective_factor = max_prospective_factor;
       original_max_concurrent_factor = max_concurrent_factor;

       person_interaction_cnt = 0;

       IF person_hc_cnt >= 2 
       THEN DO;

               /* =================================================== */
               /* UC 170384: ASSIGN HC INTERACTION                    */ 
               /* =================================================== */
               DO i = 1 TO (person_hc_cnt - 1);  

                        DO j = (i + 1) TO person_hc_cnt ;

                              hc_id1 = hc_ {i};
                              hc_id2 = hc_ {j};

                              health_condition_code_1 = VNAME( health_condition_{hc_id1} );
                              health_condition_code_2 = VNAME( health_condition_{hc_id2} );

                              pop_hc_interaction_riw_key = PUT(methodology_year, 004.) ||
                                                           health_condition_code_1 || 
                                                           health_condition_code_2 ;

                              pop_hc_interaction_riw_lookup = PUT(pop_hc_interaction_riw_key, $pop_hc_interaction_riw.); 
                                    
                              IF NOT MISSING(pop_hc_interaction_riw_lookup)
                              THEN DO;
                                      pop_riw_return_code = "44";

                                      person_interaction_cnt = person_interaction_cnt + 1;

                                      hc_CONCUR_INTERACTION_factor = SUBSTR(pop_hc_interaction_riw_lookup, 1, 10) * 1.0;

                                      pop_concurrent_riw = pop_concurrent_riw + hc_CONCUR_INTERACTION_factor;

                                      hc_PROSP_INTERACTION_factor = SUBSTR(pop_hc_interaction_riw_lookup, 11 , 10) * 1.0;

                                      pop_prospective_riw = pop_prospective_riw + hc_PROSP_INTERACTION_factor;
                                 END;

                       END; /* j loop */ 

               END;  /* i loop */


             IF person_interaction_cnt > 0
			 THEN DO;
                    IF (pop_concurrent_riw < max_concurrent_factor) & 
                       (pop_prospective_riw < max_prospective_factor)
                    THEN DO;
                            pop_concurrent_riw = max_concurrent_factor;
                            pop_prospective_riw = max_prospective_factor;

                            pop_riw_return_code = "46";  /* BOTH Concurrent and Prospective */
                         END;
                    ELSE

                    IF pop_prospective_riw < max_prospective_factor 
                    THEN DO;
                            pop_prospective_riw = max_prospective_factor;
                            pop_riw_return_code = "45";  /* Prospective only */
                         END;
                    ELSE

                    IF pop_concurrent_riw < max_concurrent_factor
                    THEN DO;
                            pop_concurrent_riw = max_concurrent_factor;
                            pop_riw_return_code = "47"; /* Concurrent only */
                         END; 
			      END;

            END;  /* TWO or more HCs */


     END;  /* pop_user_code 01 */

ELSE DO; /* pop_user_code IN ("00" "98") */

         IF pop_exclusion_flag = "N" 
         THEN DO;
                  /* ================================== */
		          /* UC146083: ASSIGN NO HC WEIGHT      */
                  /* ================================== */
                  pop_exclusion_flag = "N";
                  person_interaction_cnt = 0;

                  %POP_NO_HC_RIW;

                  IF NOT MISSING(POP_NO_HC_RIW_lookup) 
                  THEN DO;
                          pop_prospective_riw = SUBSTR(POP_NO_HC_RIW_lookup, 1, 10) * 1.0;
                          pop_concurrent_riw  = SUBSTR(POP_NO_HC_RIW_lookup, 11, 10)* 1.0;
                       END;
                  ELSE DO;
                           pop_exclusion_flag = "Y";
                           pop_riw_return_code = "40";
                       END;
              END;

        END;



pop_concurrent_riw  = ROUND(pop_concurrent_riw , 0.0001);
pop_prospective_riw = ROUND(pop_prospective_riw, 0.0001);

                                                      /* ================================================= */
                                                      /* 2016-06-17                                        */
                                                      /* hcn_valid_ON_REF_DATE_FLAG is set in DEFINE POP   */
                                                      /* ================================================= */
IF hcn_valid_on_ref_date_flag = "N"
THEN DO;
         pop_prospective_riw = 0;
     END;


%MEND POP_ASSIGN_ADDITIVE_WEIGHTS;


/* ======================================================================================== */
/* ======================================================================================== */
/* ======================================================================================== */
/* ======================================================================================== */
/* ======================================================================================== */


/* =================================================================================== */
/*                                                                                     */
/*                                                                                     */
/* =================================================================================== */




/* ============================================================== */
/*                                                                */
/*  FYI - T_SEQ_LOWEST_HC and T_SEQ_HIGHEST_HC are assigned       */
/*                                                                */
/* ============================================================== */


DATA DTA_OUT.pop_grouper_hc_riw;

    SET temp_pop_grouper_assign  ;
    BY methodology_year
       methodology_version_num;


LENGTH  pop_riw_return_code $2.
        pop_age_group_code $2.

        health_condition_code
        health_condition_code_1 
        health_condition_code_2 $4.

        pop_hc_interaction_riw_key    $12. 
        pop_hc_interaction_riw_lookup $20.;

        
ARRAY health_condition_      {&sys_hc_cnt.}   3.  &HC_LIST. ;

ARRAY health_condition_orig_ {&sys_hc_cnt.}   3.  orig_hc_001 - orig_hc_%SYSFUNC(PUTN(&sys_hc_cnt., Z3.)) ;

ARRAY hc_                    {*} hc_001 - hc_%SYSFUNC(PUTN(&sys_hc_cnt., Z3.));


%POP_ASSIGN_CLINICAL_OVERRIDES;

%POP_ASSIGN_ADDITIVE_WEIGHTS;


%POP_10_ASSIGN_HPG; 



                                              /* Identify variables to KEEP on pop_grouper_hc_riw */
KEEP  province_code
      person_id
      methodology_year
      methodology_version_num
              
      pop_start_date
      pop_reference_date
      pop_concurrent_period_years

	  pop_return_code

      reg_gender_code
      reg_date_of_death
      reg_postal_code
	  region_code              
      pop_age_num
      pop_age_group_code

      hcn_valid_on_ref_date_flag 

      inpatient_flag
      day_surgery_flag
      emergency_flag
      clinic_flag
      physician_flag
      ltc_flag
      ccc_flag
      omhrs_flag

      diag_input_to_pop_cnt
      diag_processed_cnt
      diag_exception_cnt
      diag_blank_cnt
  
      pop_user_code

      person_hc_orig_cnt
      person_hc_cnt
      person_hc_override_cnt

	  seq_id_lowest_hc
	  seq_id_highest_hc

      &HC_LIST.            /* HC_LIST contains ALL POP Health Conditions (A01 . . . S81) */



      pop_riw_return_code
      pop_exclusion_flag
      person_interaction_cnt

      pop_prospective_riw
      pop_concurrent_riw

                                           /* ================================ */ 
                                           /* CCRS Functional Status fields    */
                                           /* ================================ */ 
	  pop_func_status_return_code 

      functional_status_input_flag
      aggression_behaviour_scale
      act_daily_living_hier_score
      chess_level
      cognitive_performance_score
      pain_scale
      pressure_ulcer_risk_scale

	                                  /* ============== */
	                                  /* HPG variables  */
	                                  /* ============== */
	  pop_hpg_return_code

      hpg_code
      hpg_concurrent_riw
      hpg_prospective_riw
      hpg_category_code
      ;

RUN; 







                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _NULL_;

   CALL SYMPUTX ("pop_10_grpr_02_finish", DATETIME() );

RUN;



                                                           /*==================================================*/
                                                           /* Create a file with record counts                   */
                                                           /*==================================================*/
%MACRO create_pop_total_grouper;

%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;



DATA DTA_OUT.pop_total_grouper
            (KEEP = use_case_name
                    pop_10_grpr_02_SAS_CODE
                    pop_10_grpr_02_VERSION_DATE
                    pop_10_grpr_02_start 
                    pop_10_grpr_02_finish

					                                       /* GRPR_04 = HSG assignment */ 
                    pop_10_grpr_04_SAS_CODE
                    pop_10_grpr_04_VERSION_DATE

                    reg_input_to_pop_cnt
                    sys_diag_person_id_cnt
                    pop_diag_hcn_not_in_scope_cnt

                    sys_diag_input_to_pop_cnt
                    sys_diag_blank_cnt
                    sys_diag_exception_cnt
                    sys_diag_processed_cnt


                    FUNC_STATUS_INPUT_TO_pop_cnt
                    pop_func_hcn_not_in_scope_cnt

                    population_cnt
                    non_user_cnt
                    user_cnt
                    user_with_hc_cnt
                    user_zero_hc_cnt
                    );

                                           /* ========================================== */
					                       /* Combine the counts from the two TEMP files */
                                           /* ========================================== */
   SET temp_user_non_user_counters;

   SET temp_system_diag_counts;

LENGTH reg_input_to_pop_cnt

       func_status_input_to_pop_cnt
       pop_func_hcn_not_in_scope_cnt  008.

       pop_10_grpr_02_SAS_code 
       use_case_name             $060.;


use_case_name = "POP 1.0 - Totals from Grouping";
pop_10_grpr_02_SAS_code         = "&pop_10_grpr_02_SAS_code.";
pop_10_grpr_02_VERSION_DATE     = "&pop_10_grpr_02_VERSION_DATE.";

pop_10_grpr_02_start  = &pop_10_grpr_02_start.;
pop_10_grpr_02_finish = &pop_10_grpr_02_finish.;


FORMAT pop_10_grpr_02_start 
       pop_10_grpr_02_finish   DATETIME020.;



use_case_name = "POP 1.0 - HSG Assignment";
pop_10_grpr_04_SAS_code         = "&pop_10_grpr_04_SAS_code.";
pop_10_grpr_04_VERSION_DATE     = "&pop_10_grpr_04_VERSION_DATE.";




                                                                         /* ================  */
                                                                         /* registry         */
                                                                         /* ================  */

%NOBS(DTA_OUT.reg_input_to_pop);
reg_input_to_pop_cnt = &NUM;
IF reg_input_to_pop_cnt = . THEN reg_input_to_pop_cnt = 0;

%NOBS(DTA_OUT.pop_hc_NO_REGISTRY);
pop_hc_NO_reg_cnt = &NUM;
IF pop_hc_NO_reg_cnt = . THEN pop_hc_NO_reg_cnt = 0;


                                                                         /* ================  */
                                                                         /* Diag VS REG       */
                                                                         /* ================  */
%NOBS(DTA_OUT.pop_diag_HCN_not_in_scope);
   pop_diag_hcn_not_in_scope_cnt = &NUM;
IF pop_diag_hcn_not_in_scope_cnt = . THEN pop_diag_hcn_not_in_scope_cnt = 0;



                                                                         /* ================  */
                                                                         /* Func Status       */
                                                                         /* ================  */
%NOBS(DTA_OUT.func_status_input_to_pop);
func_status_input_to_pop_cnt = &NUM;
IF func_status_input_to_pop_cnt = . THEN func_status_input_to_pop_cnt = 0;
 
%NOBS(DTA_OUT.pop_func_hcn_not_in_scope);
pop_func_hcn_not_in_scope_cnt = &NUM;
IF pop_func_hcn_not_in_scope_cnt = . THEN pop_func_hcn_not_in_scope_cnt = 0;




FORMAT reg_input_to_pop_cnt
       sys_diag_person_id_cnt
       pop_diag_hcn_not_in_scope_cnt

       sys_diag_input_to_pop_cnt
       sys_diag_exception_cnt
       sys_diag_blank_cnt
       sys_diag_processed_cnt


       population_cnt
       user_cnt
       user_with_hc_cnt
       user_zero_hc_cnt
       non_user_cnt

       func_status_input_to_pop_cnt
       pop_func_hcn_not_in_scope_cnt    COMMA014.; 

RUN;


PROC PRINT DATA = DTA_OUT.pop_total_grouper NOOBS;
  TITLE3         "DTA_OUT.pop_total_grouper";
  TITLE5         "&DTA_OUT";
  BY use_case_name
     pop_10_grpr_02_start 
     pop_10_grpr_02_finish;

  VAR reg_input_to_pop_cnt
      sys_diag_person_id_cnt
      pop_diag_hcn_not_in_scope_cnt

      sys_diag_input_to_pop_cnt
      sys_diag_exception_cnt
      sys_diag_processed_cnt
      sys_diag_blank_cnt

      population_cnt
      user_cnt
      user_with_hc_cnt
      user_zero_hc_cnt
      non_user_cnt

	  func_status_input_to_pop_cnt
      pop_func_hcn_not_in_scope_cnt

      ;
RUN;


%MEND create_pop_total_grouper;

%create_pop_total_grouper;



/*================*/
/* End of program */
/*================*/

