
%LET pop_10_pre_01_sas_code     = pop_10_preprocess_01_registry.sas;
%LET pop_10_pre_01_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP 1.0 SAS GROUPER                                                                */
/*=========================================================================================*/
/* Use Case: UC167817: Pre-process Registry                                                */
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_IN.&registry_input.                                                   */
/*                                                                                         */
/* Output File(s):                                                                         */
/*               DTA_PRE.reg_valid                                                         */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       00 - OK                                                           */
/*                                                                                         */
/*               DTA_PRE.reg_exception                                                     */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       09 - Missing DOB                                                  */
/*                       10 - Gender blank or invalid                                      */
/*                       11 - DOB after Date of Death                                      */
/*                                                                                         */
/*               DTA_PRE.reg_duplicate                                                     */
/*                       POP_REG_RETURN_CODE values                                        */
/*                       01 - Duplicate PERSON_ID                                          */
/*                                                                                         */
/*                                                                                         */
/*               DTA_PRE.pop_total_pre_process_registry                                    */
/*                                                                                         */
/*=========================================================================================*/


                                                         /* ========================== */
                                                         /* Start / End time stamps    */
                                                         /* ========================== */
DATA _NULL_;

   CALL SYMPUTX ("pop_10_pre_01_start", DATETIME());

RUN;

/* ====================== */ 
/* SORT THE REGISTRY FILE */
/* ====================== */ 
PROC SORT 
    DATA = DTA_IN.&registry_input.
          (KEEP = province_code
		          person_id

				  reg_dob
				  reg_gender_code
				  reg_date_of_death
				  reg_postal_code

				  hcn_valid_:        /* Keep ALL USER defined HCN_VALID_20yy_INDICATOR variables */
	              )

    OUT = registry_input; 
    BY province_code 
       person_id;
RUN;



DATA DTA_PRE.reg_valid
     DTA_PRE.reg_exception
     DTA_PRE.reg_duplicate
     ;

    LENGTH  pop_reg_return_code    $2.;

    FORMAT reg_dob  
           reg_date_of_death    DATE9.;

    pop_reg_return_code = "00";

    SET  registry_input 
         END = LAST;
    BY person_id ;

                                                          /* PERSON_ID should only occur ONCE */
IF FIRST.person_id AND
   LAST.person_id 
THEN DO;

        IF MISSING (reg_dob)
        THEN DO;
                pop_reg_return_code = "09";
              	OUTPUT DTA_PRE.reg_exception;           /* EXCEPTION - No date of birth */
             END;
        ELSE
        IF NOT (reg_gender_code IN ("M", "F"))
        THEN DO;
                pop_reg_return_code = "10";
                OUTPUT DTA_PRE.reg_exception;           /* EXCEPTION - Gender Code is neither M nor F */
             END;
	    ELSE DO;
                IF MISSING(reg_date_of_death) 
                THEN DO;
                        OUTPUT DTA_PRE.reg_valid;      /* This is the majority - NO date of death = people are alive */
                    END; 
			    ELSE

                IF reg_date_of_death GE reg_dob 
                THEN DO;
                        OUTPUT DTA_PRE.reg_valid;      /* This is valid - dead people are on the historic registry */
                     END;
                ELSE DO; 
                        pop_reg_return_code = "11";
                        OUTPUT DTA_PRE.reg_exception;  /* EXCEPTION - Date of death is BEFORE the date of birth */
                     END;
            END;

    END;

                                                           
ELSE DO;
        pop_reg_return_code = "01";
        OUTPUT DTA_PRE.reg_duplicate;               /* DUPLICATE - The person_id appears more than once on the registry file  */
     END;
 
RUN;


                                                         /* ========================== */
                                                         /* Start / End time stamps    */
                                                         /* ========================== */
DATA _NULL_;

   CALL SYMPUTX ("pop_10_pre_01_finish", DATETIME());

RUN;


/* Macro to get record counts from SAS dataset "DS" */
%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;
	

DATA DTA_PRE.pop_total_pre_process_registry
            (KEEP = use_case_name

                    pop_10_pre_01_sas_code
                    pop_10_pre_01_version_date

                    pop_10_pre_01_start
                    pop_10_pre_01_finish

                    reg_input_cnt
                    reg_valid_cnt
                    reg_exception_cnt
                    reg_duplicate_cnt
                   );

LENGTH reg_input_cnt  
       reg_valid_cnt  
       reg_exception_cnt 
       reg_duplicate_cnt       8.           /* THREE IS NOT ENOUGH!!! */

       pop_10_pre_01_sas_code
       use_case_name                 $060.;


use_case_name = "POP Totals from Pre-process Registry";

pop_10_pre_01_sas_code         = "&pop_10_pre_01_sas_code.";
pop_10_pre_01_version_date     = "&pop_10_pre_01_version_date.";

pop_10_pre_01_start  = &pop_10_pre_01_start.;
pop_10_pre_01_finish = &pop_10_pre_01_finish.;

    %NOBS(DTA_IN.&registry_input.);
    reg_input_cnt = &NUM;
	IF reg_input_cnt = . THEN reg_input_cnt = 0;
	

    %NOBS(DTA_PRE.reg_duplicate);
    reg_duplicate_cnt = &NUM;
	IF reg_duplicate_cnt = . THEN reg_duplicate_cnt = 0;

    %NOBS(DTA_PRE.reg_exception);
    reg_exception_cnt = &NUM;
	IF reg_exception_cnt = . THEN reg_exception_cnt = 0;

    %NOBS(DTA_PRE.reg_valid);
    reg_valid_cnt = &NUM;
	IF reg_valid_cnt = . THEN reg_valid_cnt = 0;
	
FORMAT pop_10_pre_01_start
       pop_10_pre_01_finish    DATETIME0018.

       reg_input_cnt  
       reg_valid_cnt  
       reg_exception_cnt 
       reg_duplicate_cnt  COMMA009.; 

RUN;


PROC PRINT DATA = DTA_PRE.pop_total_pre_process_registry NOOBS;
  TITLE3         "DTA_PRE.pop_total_pre_process_registry";

  BY use_case_name;
  VAR 
      reg_input_cnt
      reg_exception_cnt 
      reg_duplicate_cnt  
      reg_valid_cnt;  

RUN;

PROC PRINT DATA = DTA_PRE.pop_total_pre_process_registry NOOBS;
  TITLE3         "DTA_PRE.pop_total_pre_process_registry";

  BY use_case_name;
  VAR pop_10_pre_01_sas_code
      pop_10_pre_01_version_date

      pop_10_pre_01_start
      pop_10_pre_01_finish;  

RUN;

/*=========================*/
/* End of UC167817 program */
/*=========================*/
