
%LET pop_10_grpr_01_sas_code     = pop_10_grpr_01_define_population.sas;
%LET pop_10_grpr_01_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*                                                                                         */
/* UC146065 Define Population                                                              */
/* ===========================                                                             */

/*=========================================================================================*/
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_PRE.reg_valid                                                         */
/*                                                                                         */
/*               DTA_PRE.diag_valid                                                        */
/*                                                                                         */
/*               CCRS_FS.&FUNCTIONAL_STATUS_INPUT. (USER file name)                        */
/*                                                                                         */
/*                                                                                         */
/*               DTA_OUT.parameters_define_pop_and_group                                   */
/*                                                                                         */
/*                                                                                         */
/* Output File(s):                                                                         */
/*               DTA_OUT.reg_input_to_pop                                                  */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       00 - OK                                                           */
/*                                                                                         */
/*               DTA_OUT.reg_age_exception                                                 */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       23 - Age is greater than 130                                      */
/*                                                                                         */
/*               DTA_OUT.reg_out_of_scope                                                  */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       00 - OK (but out-of-scope)                                        */
/*                       24 - DOB is after the concurrent period                           */
/*                       25 - Date of death is before the concurrent period                */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*               DTA_OUT.diag_input_to_pop                                                 */
/*               temp_diag_before_start_date                                               */
/*               temp_diag_after_ref_date                                                  */
/*                                                                                         */
/*               DTA_OUT.func_status_input_to_pop                                          */
/*               temp_func_before_start_date                                               */
/*               temp_func_after_ref_date                                                  */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*               DTA_OUT.pop_total_define_population                                       */
/*                                                                                         */
/*                                                                                         */
/*=========================================================================================*/



                                           /*=================================*/
                                           /* Start / End time stamps         */
                                           /*=================================*/
DATA _NULL_;

  CALL SYMPUTX ("pop_10_grpr_01_start", DATETIME());

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
    t_year = YEAR (pop_start_date) + pop_concurrent_period_years;

    t_ref_date = MDY(t_month, t_day, t_year) - 1;

    IF t_ref_date = pop_reference_date
	THEN user_pop_parameter_error = "N";
	ELSE user_pop_parameter_error = "Y";
   
DROP t_:;

RUN;

DATA _null_;
    SET parameters_define_pop_and_group;
    

    LENGTH methodology_year 4.   methodology_version_num 4 ;
    FORMAT methodology_year 4.   methodology_version_num 4.1 ;

    LENGTH YEAR1 YEAR2 YEAR3 4.;

    FORMAT pop_reference_date
           pop_start_date         DATE9.;

    YEAR1 = YEAR(pop_start_date);
    YEAR2 = year1 + 1;
    YEAR3 = year1 + 2;
    
    
    CALL SYMPUTX("methodology_year", methodology_year);
    CALL SYMPUTX("methodology_version_num", methodology_version_num);
    
    CALL SYMPUTX("POP_REFERENCE_DATE",pop_reference_date); 
    CALL SYMPUTX("POP_START_DATE", pop_start_date);

    CALL SYMPUTX("pop_concurrent_period_years", pop_concurrent_period_years);

    CALL SYMPUTX("YEAR1", YEAR1);
    CALL SYMPUTX("YEAR2", YEAR2);
    CALL SYMPUTX("YEAR3", YEAR3);
    
    CALL SYMPUTX("FUNCTIONAL_STATUS_INPUT_FLAG", FUNCTIONAL_STATUS_INPUT_FLAG);
    
    CALL SYMPUTX("FUNCTIONAL_STATUS_FILE_NAME", FUNCTIONAL_STATUS_FILE_NAME);
    
 
    CALL SYMPUTX("USER_POP_PARAMETER_ERROR", user_pop_parameter_error);
   

RUN;

%MEND SET_POP_PARAMETERS;

%SET_POP_PARAMETERS;


%PUT &pop_concurrent_period_years.;
%PUT &YEAR1.;
%PUT &YEAR2.;
%PUT &YEAR3.;

%PUT &POP_START_DATE.;
%PUT &POP_REFERENCE_DATE.;

%PUT &USER_POP_PARAMETER_ERROR.;

%PUT &FUNCTIONAL_STATUS_INPUT_FLAG.;

%PUT &FUNCTIONAL_STATUS_INPUT.;

%PUT &METHODOLOGY_YEAR.;

                                                                    /* ===================================================== */
                                                                    /* UC146065 - Extract REGISTRY                           */
                                                                    /* ===================================================== */

/* =================================================================================== */
/* POP_ASSIGN_HEALTH_REGION                                                            */
/*                                                                                     */
/* =================================================================================== */

%MACRO PCCF_REGION_CODE_DA06_DA11;

LENGTH region_code $004;

IF reg_postal_code = " "          
THEN DO;                                		/* Exception - Postal code is blank  */
		da11uid = "-7";
        qaippe11 = "-7";

        da06uid = "-7";
        qaippe06 = "-7";

     END;
ELSE DO;
        %POP_PCCF;

        IF NOT MISSING(pop_pccf_lookup) 
        THEN DO;
                region_code = SUBSTR (pop_pccf_lookup, 23, 04);

                da06uid = CATS(SUBSTR(pop_pccf_lookup, 9, 8));
                qaippe06 = CATS(SUBSTR(pop_pccf_lookup, 20, 3));

                da11uid = CATS(SUBSTR(pop_pccf_lookup, 1, 8));
                qaippe11 = CATS(SUBSTR(pop_pccf_lookup, 17, 3));

             END;
        ELSE DO;
                 /* ================================================= */
                 /* No match in the POP_PCCF table                    */
                 /* ================================================= */
				da11uid = "-7";
                qaippe11 = "-7";

                da06uid = "-7";
                qaippe06 = "-7";
        END;
  
     END;

DROP pop_pccf_lookup;



%MACRO RESET_REGION_CODE (value);

region_code = &VALUE.;

da11uid = "-7";
qaippe11 = "-7";

da06uid = "-7";
qaippe06 = "-7";

%MEND RESET_REGION_CODE;


IF province_code = "ON" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "35")
THEN DO;
         %RESET_REGION_CODE ("3599");
     END;
ELSE

IF province_code = "AB" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "48")
THEN DO;
         %RESET_REGION_CODE ("4899");
     END;
ELSE

IF province_code = "BC" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "59")
THEN DO;
         %RESET_REGION_CODE ("5999");
     END;
ELSE

IF province_code = "MB" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "46")
THEN DO;
         %RESET_REGION_CODE ("4699");
     END;
ELSE

IF province_code = "SK" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "47")
THEN DO;
         %RESET_REGION_CODE ("4799");
     END;
ELSE


IF province_code = "NL" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "10")
THEN DO;
         %RESET_REGION_CODE ("1099");
     END;
ELSE


IF province_code = "PE" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "11")
THEN DO;
         %RESET_REGION_CODE ("1199");
     END;
ELSE

IF province_code = "NS" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "12")
THEN DO;
         %RESET_REGION_CODE ("1299");
     END;
ELSE

IF province_code = "YT" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "60")
THEN DO;
         %RESET_REGION_CODE ("6099");
     END;
ELSE

IF province_code = "NT" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "61")
THEN DO;
         %RESET_REGION_CODE ("6199");
     END;
ELSE

IF province_code = "NU" &
   (region_code = " " OR
    SUBSTR (region_code, 001, 002) NE "62")
THEN DO;
         %RESET_REGION_CODE ("6299");
     END;


%MEND PCCF_REGION_CODE_DA06_DA11;



/* ======================================== */
/* DTA_PRE.reg_valid                        */
/* - Sorted by PERSON_ID                    */
/* - Exception records have been removed    */
/* ======================================== */

DATA DTA_OUT.reg_input_to_pop
             (DROP = pop_pccf_key)


     DTA_OUT.reg_age_exception
	        (DROP = pop_pccf_key
                    region_code
                    da06uid
                    qaippe06
                    da11uid
                    qaippe11)

     DTA_OUT.reg_out_of_scope
	        (DROP = pop_pccf_key
                    region_code
                    da06uid
                    qaippe06
                    da11uid
                    qaippe11);

   SET DTA_PRE.reg_valid;

   BY person_id; 


LENGTH da11uid             $008.
       qaippe11            $003.
       da06uid             $008.
       qaippe06            $003.

       death_indicator     $001. ;



	                                    /* ========================= */
	                                    /* System parameters         */
                                        /* ========================= */
RETAIN methodology_year 
       methodology_version_num

       pop_start_date
       pop_reference_date;

FORMAT methodology_year        4.
       methodology_version_num 4.1

       pop_start_date
       pop_reference_date    DATE009.;
 
IF _n_ = 1
THEN DO;
        methodology_year = &methodology_year.;
        methodology_version_num = &methodology_version_num.;

		pop_start_date = &POP_START_DATE.;
		pop_reference_date = &POP_REFERENCE_DATE.;
     END;




                		          /* ===============================*/
		                          /* Exclude AGE > 130              */
		                          /* ===============================*/

%MACRO check_ages;

IF REG_DOB <=  pop_reference_date
THEN DO;
        IF NOT MISSING(reg_date_of_death) 
        THEN DO;
		          /* ===============================*/
		          /* There is a Date Of Death       */
		          /* ===============================*/
                IF reg_date_of_death >= pop_start_date &
                   reg_date_of_death >  pop_reference_date
                THEN DO;
                       death_indicator = "2";

                       %DEFINE_AGE (reg_dob,  pop_reference_date, pop_age_num);    /* Age at reference date (in years) */

 					   IF pop_age_num < 131
                       THEN DO;
                               pop_reg_return_code = "00";
                               OUTPUT DTA_OUT.reg_input_to_pop;
                           END;
                       ELSE DO;
                               pop_reg_return_code = "23";
                               OUTPUT DTA_OUT.reg_age_exception;
                            END;

                     END;
                ELSE DO;
                        IF reg_date_of_death < pop_start_date
                        THEN DO;
                                pop_reg_return_code = "25";
                                OUTPUT DTA_OUT.reg_out_of_scope;  /* FAILSAFE - Should not happen (if hcn_valid are corrrect) */
                             END;
                        ELSE 
                        IF reg_date_of_death <=  pop_reference_date
                        THEN DO;
                                death_indicator = "1"; 

             					%DEFINE_AGE (reg_dob, reg_date_of_death, pop_age_num);    /* pop_age_num = Age at death (in years) */

                                IF pop_age_num < 131
                                THEN DO;
                                        pop_reg_return_code = "00";
                                        OUTPUT DTA_OUT.reg_input_to_pop;
                                     END;
                                ELSE DO;
                                        pop_reg_return_code = "23";
                                        OUTPUT DTA_OUT.reg_age_exception;
                                     END;

                            END;
                    END;


             END;
        ELSE DO;
                 /* ===============================*/
		         /* No Date Of Death reported      */
		         /* ===============================*/
                death_indicator = "0";

                %DEFINE_AGE (reg_dob, pop_reference_date, pop_age_num);    /* pop_age_num = Age at reference date (in years) */

                IF pop_age_num < 131
                THEN DO;
                        pop_reg_return_code = "00";
                        OUTPUT DTA_OUT.reg_input_to_pop;
                     END;
                ELSE DO;
                        pop_reg_return_code = "23";
                        OUTPUT DTA_OUT.reg_age_exception;
                     END;

             END;
     END;

ELSE DO;
        /* =================================== */
        /* DOB is after the concurrent period  */
        /* =================================== */
         pop_reg_return_code = "24";
         OUTPUT DTA_OUT.reg_out_of_scope;  /* FAILSAFE - Should not happen (if hcn_valid are corrrect) */
     END;

%MEND check_ages;


hcn_valid_on_ref_date_flag = "N";


IF "&USER_POP_PARAMETER_ERROR" = "Y"
THEN DO;
        pop_reg_return_code = "83";
        OUTPUT DTA_OUT.reg_out_of_scope;
     END;
ELSE


IF &pop_concurrent_period_years = 2                                        /* pop_concurrent_period_years = 2 */
THEN DO;
        IF hcn_valid_&YEAR1._indicator = 0 AND
           hcn_valid_&YEAR2._indicator = 0
        THEN DO;
		        /* =================================== */
                /* Leave POP_REG_RETURN_CODE as "00"   */
		        /* =================================== */
                OUTPUT DTA_OUT.reg_out_of_scope;
	         END;
        ELSE DO;
		        /* =========================================================== */
                /* HCN is valid for one or more years of the concurrent period */
		        /* =========================================================== */

			   IF hcn_valid_&YEAR2._indicator = "1"
               THEN hcn_valid_on_ref_date_flag = "Y";

               %PCCF_REGION_CODE_DA06_DA11;

               %CHECK_AGES;

             END;

     END;
ELSE

IF &pop_concurrent_period_years = 3                                        /* pop_concurrent_period_years = 3 */
THEN DO;
        IF hcn_valid_&YEAR1._indicator = 0 AND
           hcn_valid_&YEAR2._indicator = 0 AND
           hcn_valid_&YEAR3._indicator = 0
        THEN DO;
		        /* =================================== */
                /* Leave POP_REG_RETURN_CODE as "00"   */
		        /* =================================== */
                OUTPUT DTA_OUT.reg_out_of_scope;
	         END;
        ELSE DO;
		        /* =========================================================== */
                /* HCN is valid for one or more years of the concurrent period */
		        /* =========================================================== */
                IF hcn_valid_&YEAR3._indicator = "1"
                THEN hcn_valid_on_ref_date_flag = "Y";

                %PCCF_REGION_CODE_DA06_DA11;

                %CHECK_AGES;

            END;

     END;  

ELSE 
IF &pop_concurrent_period_years = 1                                        /* pop_concurrent_period_years = 1 */
THEN DO;
        IF hcn_valid_&YEAR1._indicator = 0
        THEN DO;
		        /* =================================== */
                /* Leave POP_REG_RETURN_CODE as "00"   */
		        /* =================================== */
                OUTPUT DTA_OUT.reg_out_of_scope;
	         END;
        ELSE DO;
		        /* ================================================== */
                /* HCN is valid for the year of the concurrent period */
		        /* ================================================== */

                IF hcn_valid_&YEAR1._indicator = "1"
                THEN hcn_valid_on_ref_date_flag = "Y";

                %PCCF_REGION_CODE_DA06_DA11;

                %CHECK_AGES;

             END;

     END; 

ELSE DO;
        /* ============================================================== */
        /* pop_concurrent_period_years = Other   INVALID LOOK BACK PERIOD */
        /* ============================================================== */
        pop_reg_return_code = "??";
        OUTPUT DTA_OUT.reg_out_of_scope;
     END;

RUN;


%MACRO review;


PROC FREQ DATA = DTA_OUT.reg_input_to_pop;
   TITLE3        "DTA_OUT.reg_input_to_pop";
   TITLE5 "&DTA_OUT.";
   BY methodology_year
      methodology_version_num
      province_code
      pop_reg_return_code;
   TABLES hcn_valid_on_ref_date_flag * reg_gender_code
          reg_dob     * reg_gender_code
          region_code * reg_gender_code
          da06uid * da11uid
         /MISSING NOROW NOCOL NOPERCENT NOCOL FORMAT = COMMA010.;
   FORMAT reg_dob DOB_YEAR.
          da06uid
          da11uid     $002.;
RUN;



%MEND review;




                                                         /* ===================================================== */
                                                         /* UC146066 - Extract DIAGNOSIS                          */
                                                         /* ===================================================== */

DATA DTA_OUT.diag_input_to_pop 

     temp_diag_USER_parameter_error

     temp_diag_before_start_date 
         (KEEP = person_id service_date pop_diag_return_code)
     temp_diag_after_ref_date
         (KEEP = person_id service_date pop_diag_return_code);

   SET DTA_PRE.diag_valid

       DTA_PRE.diag_plpb_not_icd9 ;
   BY person_id;

RETAIN methodology_year 
       methodology_version_num;
FORMAT methodology_year 4.
       methodology_version_num 4.1;

IF _n_ = 1
THEN DO;
        methodology_year = &methodology_year.;
        methodology_version_num = &methodology_version_num.;
     END;


IF "&USER_POP_PARAMETER_ERROR" = "Y"
THEN DO;
        OUTPUT temp_diag_USER_parameter_error;
     END;
ELSE

IF &POP_START_DATE. <= service_date <= &POP_REFERENCE_DATE. 
THEN OUTPUT DTA_OUT.diag_input_to_pop;
ELSE  

IF service_date < &POP_START_DATE.
THEN OUTPUT temp_diag_before_start_date;           /* TEMP - Just have counters for production */
ELSE OUTPUT temp_diag_after_ref_date;              /* TEMP - Just have counters for production */

RUN;


%MACRO review;

PROC FREQ DATA = DTA_OUT.diag_input_to_pop;
   TITLE3       "DTA_OUT.diag_input_to_pop                 RD DX file ";
   TITLE5 "&DTA_OUT.";
   BY methodology_year
      methodology_version_num
      province_code
      ;
   TABLES 
          service_date * pop_data_source_code 

         /MISSING NOROW NOCOL NOPERCENT NOCOL FORMAT = COMMA010.;
   FORMAT service_date FISCAL_YEAR.;
RUN;


%MEND review;



                                                                    /* ===================================================== */
                                                                    /* UC174559 - Extract Functional Status                  */
                                                                    /* ===================================================== */


%MACRO DEFINE_func_status_FILE;

                               /*=================================================*/
                               /* The FUNCTIONAL_STATUS_INPUT_FLAG is Y           */
                               /*=================================================*/

DATA func_status_input_to_pop_raw
     temp_func_before_start_date
     temp_func_after_ref_date;

   SET CCRS_FS.&FUNCTIONAL_STATUS_INPUT.;

IF &POP_start_date <= service_date <= &POP_reference_date
THEN OUTPUT func_status_input_to_pop_raw;
ELSE
IF service_date < &POP_START_DATE.
THEN OUTPUT temp_func_before_start_date;           /* TEMP - Just have counters for production */
ELSE OUTPUT temp_func_after_ref_date;              /* TEMP - Just have counters for production */


KEEP province_code
     person_id
     data_source_id
     service_date
      
     act_daily_living_hier_score 
     cognitive_performance_score 
     chess_level 
     aggression_behaviour_scale 
     pain_scale 
     pressure_ulcer_risk_scale;

RUN;


PROC SORT DATA = func_status_input_to_pop_raw;
    BY person_id 
       service_date;
RUN;

DATA DTA_OUT.func_status_input_to_pop
     temp_func_not_last;
   SET func_status_input_to_pop_raw;
   BY person_id 
      service_date;

IF LAST.person_id
THEN OUTPUT DTA_OUT.func_status_input_to_pop;
ELSE OUTPUT temp_func_not_last;

RUN;


%MEND DEFINE_func_status_FILE;



%MACRO CHECK_func_status_INPUT_FLAG;

%IF "&FUNCTIONAL_STATUS_INPUT_FLAG" = "Y" &  "&USER_POP_PARAMETER_ERROR" = "N"
%THEN %DEFINE_func_status_FILE;

%MEND CHECK_func_status_INPUT_FLAG;

%CHECK_func_status_INPUT_FLAG;




                                                                        /* Start / End time stamps    */
DATA _NULL_;
  
  CALL SYMPUTX ("pop_10_grpr_01_finish", DATETIME());

RUN;



                                                                             /* ========================================================= */
                                                                             /* Create POP_TOTAL record counts                            */
                                                                             /* ========================================================= */

/* Macro to get record counts from SAS dataset "DS" */
%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;


DATA DTA_OUT.pop_total_define_population
            (KEEP = use_case_name

                    pop_10_grpr_01_sas_code
                    pop_10_grpr_01_version_date
         			pop_10_grpr_01_start 
	                pop_10_grpr_01_finish

                    pop_start_date
                    pop_reference_date
                    pop_concurrent_period_years
                    USER_POP_PARAMETER_ERROR

                    reg_valid_cnt
					reg_age_exception_cnt
					reg_out_of_scope_cnt
					reg_input_to_pop_cnt

			        diag_valid_cnt
					diag_before_start_date_cnt
					diag_after_ref_date_cnt
                    diag_input_to_pop_cnt

					func_status_input_cnt

					func_before_start_date_cnt
					func_not_last_cnt
					func_status_input_to_pop_cnt
					func_after_ref_date_cnt
              );
   SET DTA_OUT.parameters_define_pop_and_group;
       

LENGTH reg_valid_cnt
       reg_age_exception_cnt
       reg_out_of_scope_cnt
	   reg_input_to_pop_cnt

       diag_valid_cnt
	   diag_before_start_date_cnt
       diag_after_ref_date_cnt
       diag_input_to_pop_cnt

       func_status_INPUT_cnt
       func_before_start_date_cnt
       func_not_last_cnt
       func_status_input_to_pop_cnt
       func_after_ref_date_cnt              008.
			
       use_case_name                      $060.;

use_case_name                  = "POP 1.0 - Totals from Define Population";
pop_10_grpr_01_sas_code         = "&pop_10_grpr_01_SAS_CODE.";
pop_10_grpr_01_version_date     = "&pop_10_grpr_01_VERSION_DATE.";

pop_10_grpr_01_start            = &pop_10_grpr_01_start.;
pop_10_grpr_01_finish           = &pop_10_grpr_01_finish.;

USER_POP_PARAMETER_ERROR = "&USER_POP_PARAMETER_ERROR.";

FORMAT pop_10_grpr_01_start 
	   pop_10_grpr_01_finish   DATETIME020.;


                                                          /* ========================= */
                                                          /* registry files */
                                                          /* ========================= */

%NOBS(DTA_PRE.reg_valid);
reg_valid_cnt = &NUM;
IF reg_valid_cnt = . THEN reg_valid_cnt = 0;
    
%NOBS(DTA_OUT.reg_age_exception);
reg_age_exception_cnt = &NUM;
IF reg_age_exception_cnt = . THEN reg_age_exception_cnt = 0;

%NOBS(DTA_OUT.reg_out_of_scope);
reg_out_of_scope_cnt = &NUM;
IF reg_out_of_scope_cnt = . THEN reg_out_of_scope_cnt = 0;

%NOBS(DTA_OUT.reg_input_to_pop);
reg_input_to_pop_cnt = &NUM;
IF reg_input_to_pop_cnt = . THEN reg_input_to_pop_cnt = 0;

                                                          /* ========================= */
                                                          /* diagnosis files */
                                                          /* ========================= */
%NOBS(DTA_PRE.diag_valid);
diag_valid_cnt = &NUM;
IF diag_valid_cnt = . THEN diag_valid_cnt = 0;


%NOBS(temp_diag_before_start_date);
diag_before_start_date_cnt = &NUM;
IF diag_before_start_date_cnt = . THEN diag_before_start_date_cnt = 0;

%NOBS(DTA_OUT.diag_input_to_pop);
diag_input_to_pop_cnt = &NUM;
IF diag_input_to_pop_cnt = . THEN diag_input_to_pop_cnt = 0;


%NOBS(temp_diag_after_ref_date);
diag_after_ref_date_cnt = &NUM;
IF diag_after_ref_date_cnt = . THEN diag_after_ref_date_cnt = 0;


                                                          /* ========================= */
                                                          /* Functional Status counts  */
                                                          /* ========================= */

%MACRO COUNTS_FOR_func_status_FILES;

%NOBS(CCRS_FS.&FUNCTIONAL_STATUS_INPUT.);
func_status_INPUT_cnt = &NUM;
IF func_status_INPUT_cnt = . THEN func_status_INPUT_cnt = 0;


%NOBS(temp_func_after_ref_date);
func_after_ref_date_cnt = &NUM;
IF func_after_ref_date_cnt = . THEN func_after_ref_date_cnt = 0;
    
%NOBS(temp_func_before_start_date);
func_before_start_date_cnt = &NUM;
IF func_before_start_date_cnt = . THEN func_before_start_date_cnt = 0;
    
%NOBS(temp_func_not_last);
func_not_last_cnt = &NUM;
IF func_not_last_cnt = . THEN func_not_last_cnt = 0;
   

%NOBS(DTA_OUT.func_status_input_to_pop);
func_status_input_to_pop_cnt = &NUM;
IF func_status_input_to_pop_cnt = . THEN func_status_input_to_pop_cnt = 0;

%MEND COUNTS_FOR_func_status_FILES;


IF "&FUNCTIONAL_STATUS_INPUT_FLAG" = "Y"
THEN DO;
        %COUNTS_FOR_func_status_FILES;
     END;

ELSE DO;
        func_status_INPUT_cnt = -1;
		func_before_start_date_cnt = -1;
		func_after_ref_date_cnt = -1;
		func_not_last_cnt = -1;
		func_status_input_to_pop_cnt = -1;
     END;

FORMAT reg_valid_cnt
       reg_age_exception_cnt
	   reg_out_of_scope_cnt
	   reg_input_to_pop_cnt

       diag_valid_cnt
	   diag_before_start_date_cnt
       diag_after_ref_date_cnt
       diag_input_to_pop_cnt


       func_status_INPUT_cnt
	   func_before_start_date_cnt
	   func_after_ref_date_cnt
       func_not_last_cnt
       func_status_input_to_pop_cnt     COMMA009.; 

RUN;



PROC PRINT DATA = DTA_OUT.pop_total_define_population NOOBS;
  TITLE3         "DTA_OUT/pop_total_define_population";
  VAR
      pop_10_grpr_01_sas_code 
      pop_10_grpr_01_version_date

      pop_10_grpr_01_start 
      pop_10_grpr_01_finish
      ;

RUN;



/*================*/
/* End of program */
/*================*/
