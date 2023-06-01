
%LET pop_10_pre_03_sas_code     = pop_10_preprocess_03_diagnosis.sas;
%LET pop_10_pre_03_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP 1.0 SAS GROUPER                                                                */
/*=========================================================================================*/
/*                                                                                         */
/* Use Case: UC167718: Pre-process Diagnosis                                               */
/*                                                                                         */
/*     Step 1 - Remove "duplicates"                                                        */
/*                                                                                         */
/*     Step 2 - "Validate" the Dx code                                                     */
/*                - PLPB Step 2.1 - MAP Province codes to ICD9                             */
/*                ==> for POP 1.0 there is mapping for ON, MB, Sk and BC                   */
/*                                                                                         */
/*                - PLPB Step 2.2. - Check ICD9 codes vs Age and Gender                    */
/*                                                                                         */
/*                - ALL - Basic Diag Classification / Code checks                          */
/*                                                                                         */
/*=========================================================================================*/
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_PRE.diag_with_reg                                                     */
/*                                                                                         */
/*               DTA_PRE.parameters_pre_processing                                         */
/*                                                                                         */
/*                                                                                         */
/* Output File(s):                                                                         */
/*               DTA_PRE.diag_duplicate                                                    */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       04 - Duplicate record                                             */
/*                                                                                         */
/*               DTA_PRE.diag_plpb_not_icd9                                                */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       05 - PLPB ICD-9 diagnosis code is invalid                         */
/*                                                                                         */
/*               DTA_PRE.diag_exception                                                    */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       02 Invalid POP data source or DIAG_CLASSIFIATION                  */
/*                                                                                         */
/*                       06 Service date < DOB                                             */
/*                       07 Service date > Date of death                                   */
/*                       08 Service Date missing                                           */
/*                                                                                         */
/*                       12 – Invalid diagnosis / classification                           */
/*                            ==================================                           */
/*                            Blank Dx when non-blank is required                          */
/*                            (DAD, NACRS, CCRS, OMHRS data)                               */
/*                                                                                         */
/*                       19 – CCRS or OMHRS DX not valid                                   */
/*                            ==================================                           */
/*                            Invalid ICD-10 code for DAD, NACRS or OMHRS (“0”)            */
/*                            OR                                                           */
/*                            Invalid DSM-iv code for OMHRS (“D”)                          */
/*                            OR                                                           */
/*                            Invalid Dx for CCRS (R data element codes)                   */
/*                            OR                                                           */
/*                            OMHRS (M data element codes)                                 */
/*                                                                                         */
/*                       16 – Age* not in range for PLPB dx                                */
/*                            * For validation AGE is based on REG_DOB and SERVICE_DATE    */
/*                                                                                         */
/*                       17 - Gender not valid for PLPB dx                                 */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*               DTA_PRE.diag_valid                                                        */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       00 - OK                                                           */
/*                       14 - PLPB Dx is blank                                             */
/*                       18 - Diag ZZZZ generated for a CCRS assessment                    */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*               DTA_PRE.pop_total_pre_process_diagnosis                                   */
/*                                                                                         */
/*=========================================================================================*/



                                                               /* Start / End time stamps    */
DATA _NULL_;
  
   CALL SYMPUTX ("pop_10_pre_03_start", DATETIME());

RUN;



                                                        /* ============================================== */
                                                        /*   Part 1 - Drop duplicates / standardize DX    */
                                                        /*          ==> Before Mapping                    */
                                                        /* ============================================== */

PROC SORT DATA = DTA_PRE.diag_with_reg;
   BY person_id
      pop_data_source_code
      service_date
	  diag_classification_code
      diag_code
      physician_id;
RUN;


DATA temp_diag_with_reg
     DTA_PRE.diag_duplicate;
  SET DTA_PRE.diag_with_reg;
  BY person_id
     pop_data_source_code
     service_date
     diag_classification_code
     diag_code
     physician_id;


                                            /* ====================================== */
                                            /*                                        */
                                            /* ====================================== */
RETAIN methodology_year 
       methodology_version_num;
FORMAT methodology_year 4.
       methodology_version_num 4.1;

IF _n_ = 1
THEN DO;
        SET DTA_PRE.parameters_pre_processing
                    (KEEP = methodology_year
                            methodology_version_num);

        CALL SYMPUTX("methodology_year", methodology_year);

        CALL SYMPUTX("methodology_version_num", methodology_version_num);
     END;


                                                      /* ==================================================== */
                                                      /* STANDARDIZE Diagnosis Codes                          */
                                                      /* - Make a back-up of the original                     */
                                                      /* - UPPERCASE and                                      */
                                                      /* - REMOVE any DECIMAL and                             */   
	                                                  /* - LEFT JUSTIFY                                       */
                                                      /* ==================================================== */
diag_orig_code = diag_code;
diag_code = LEFT(UPCASE(COMPRESS(diag_code, '.')));


                                                      /* ======================================================== */
                                                      /* Write the FIRST of each combination to the TEMP file     */
                                                      /* FYI - This ALSO removes DAD, NACRS duplicates            */
                                                      /* ======================================================== */
LENGTH pop_diag_return_code $2.;


IF FIRST.physician_id
THEN DO;
        pop_diag_return_code = "00";
        OUTPUT temp_diag_with_reg;
     END;
ELSE DO;
        pop_diag_return_code = "04";
        OUTPUT DTA_PRE.diag_duplicate;
     END;

RUN;


%MACRO review;

PROC FREQ DATA = temp_diag_with_reg;
   TITLE3       "temp_diag_with_reg";
   BY pop_diag_return_code;
   TABLES pop_data_source_code * diag_classification_code
          pop_data_source_code 
         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA009.;
RUN;

PROC PRINT DATA = temp_diag_with_reg NOOBS;
   TITLE3       "temp_diag_with_reg";

   WHERE person_id = "PLPB_DX_TO_ZZZ";
      WHERE person_id = "DX_EX_OMHRS1";


   BY province_code
      person_id;
   VAR pop_data_source_code
        service_date
		physician_id
		diag_classification_code
		diag_code
		diag_orig_code
       pop_diag_return_code;

RUN;

%MEND  review;


                                                                 /* ============================================== */
                                                                 /*   Part 2 - Validation                          */
                                                                 /* ============================================== */


/*=========================================================================================*/
/* MACRO TO VALIDATE ICD9 Diagnosis codes                                                  */
/*                                                                                         */
/*     Methodology Table: POP_ICD9_VALIDATION                                              */
/*                        Valid Age / Gender ranges for each ICD9 Dx                       */
/*                                                                                         */
/*=========================================================================================*/

%MACRO ICD9_AGE_GENDER_VALIDATION; 

LENGTH icd9_validation_key    $12.;
LENGTH icd9_validation_lookup $07.;

icd9_validation_key    = PUT(methodology_year, Z4.) || diag_classification_code || diag_code;
icd9_validation_lookup = PUT(icd9_validation_key, $POP_ICD9_VALIDATION.);


IF icd9_validation_lookup = " "
THEN DO;
        diag_code = " ";
        pop_diag_return_code = "05";                   /* EXCEPTION - No match in POP_ICD9_VALIDATION table */
     END;

ELSE DO;
        age_min                = SUBSTR(icd9_validation_lookup, 2, 3) * 1.0;
        age_max                = SUBSTR(icd9_validation_lookup, 5, 3) * 1.0;
        gender_validation_code = SUBSTR(icd9_validation_lookup, 1, 1);

		plpb_age_num = .;

        IF reg_dob <= service_date
        THEN DO;
                IF MISSING(reg_date_of_death)
                THEN DO; 
                        %DEFINE_AGE (reg_dob, service_date, plpb_age_num);    /* plpb_age_num = Age at 'service date' (in years) */
                     END;
			    ELSE
                IF service_date <= reg_date_of_death   
                THEN DO; 
                        %DEFINE_AGE (reg_dob, service_date, plpb_age_num);
				     END;
            END; 

        /* ============================================================================= */
        /* Any INVALID Dx, Age and Gender combination results in DAIG_CODE = Blank       */
        /* ============================================================================= */
        IF (age_min <= plpb_age_num <= age_max) 
        THEN DO;
                IF gender_validation_code NE "A" 
                THEN DO;
                        IF reg_gender_code NE gender_validation_code 
                        THEN DO;
                                diag_code = " ";
                                pop_diag_return_code = "17";   /*  EXCEPTION - Gender is not in the valid range for this Dx  */
                             END;
                     END;
             END;
        ELSE DO;  
                diag_code = " ";
                pop_diag_return_code = "16";                  /* EXCEPTION - AGE is not in the valid range for this Dx */
             END;

     END;


%MEND ICD9_AGE_GENDER_VALIDATION;



/*=========================================================================================*/
/* MACRO VALIDATE_DX_CODES                                                       Expanded  */
/* - These DX records have a VALID pop_data_source_code                                    */
/*                                                                                         */
/*=========================================================================================*/

%MACRO validate_dx_codes;

                                                                   /* =============================== */
                                                                   /* PLPB Dx codes                   */
                                                                   /* =============================== */
IF pop_data_source_code = "PLPB" 
THEN DO;  

        /*===============================================================*/
        /* VALIDATE PLPB DIAG                                            */
        /* For Ontario and BC perform PROV_DIAG_TO_ICD9 conversion       */
        /* For other province there is NO PROV_DIAG_TO_ICD9 conversion   */
        /*===============================================================*/

        IF diag_code = " "
		THEN DO;
		        pop_diag_return_code = "14";                        /* PLPB with Dx = Blank is OK */
		     END;
		ELSE

        DO;
            /* =================================================*/
		    /* 1 - Provincial PLPB mapping of codes to ICD 9    */
		    /* 2 - Check ICD-9 codes for valid Age Gender       */
            /* =================================================*/
             IF province_code IN ("ON" "MB" "SK" "BC") 
             THEN DO;
 
                     prov_diag_to_icd9_key = PUT(methodology_year, 004.) || province_code || diag_orig_code;

                     prov_diag_to_icd9_lookup = PUT(prov_diag_to_icd9_key, $PROVINCE_DIAG_TO_ICD.);


                     IF NOT MISSING(prov_diag_to_icd9_lookup) 
                     THEN DO;
                             diag_classification_code = SUBSTR(prov_diag_to_icd9_lookup, 1, 1);

                             diag_code = SUBSTR(prov_diag_to_icd9_lookup, 2, 7);

                             %ICD9_AGE_GENDER_VALIDATION;

                          END;
                     ELSE DO; 
                                  /* OK - No mapping found for this PLPB code (assumed to be ICD9) */
                                  %ICD9_AGE_GENDER_VALIDATION;
                              END;

                  END; /* ON BC */

             ELSE DO; 
                     /* ====================================== */ 
                     /* No PLPB mapping for other provinces   */
                     /* ====================================== */ 
                     %ICD9_AGE_GENDER_VALIDATION;

                 END;


        END;

     END; /* PLPB*/
ELSE

                                                                   /* =============================== */
                                                                   /* CCRS Dx codes          Expanded */
                                                                   /* =============================== */
IF pop_data_source_code 
IN ("CCRS-LTC" "CCRS-CCC")
THEN DO;
        IF diag_code = " " 
		THEN DO;
		        diag_code = " ";
		        pop_diag_return_code = "12";               /* EXCEPTION - Blank Dx code         */
		     END;
        ELSE

        IF diag_code = "ZZZZ"
		THEN DO;
		        diag_code = " ";
                pop_diag_return_code = "18";               /* OK - CCRS AX with ZERO real DX codes */
		     END;

        ELSE DO;
                %POP_HEALTH_CONDITION_ASSIGN;  /* Set pop_health_cond_assign_lookup */

                IF pop_health_cond_assign_lookup = " "
                THEN DO;
				        diag_code = " ";
                                                         /* ====================================== */
        	            pop_diag_return_code = "19";     /* EXCEPTION - DX not in HC Assign table  */
                                 					 	 /* ====================================== */
                     END;
                ELSE DO;
                        /* OK - No problem */
                     END;

             END;
      
      END;
ELSE


                                                                   /* =============================== */
                                                                   /* OMHRS Dx codes         Expanded */
                                                                   /* =============================== */
IF pop_data_source_code = "OMHRS"
THEN DO; 
        IF diag_classification_code = "D"
		THEN DO;
		        IF diag_code = " "
                THEN DO;
							                                      /* ============================================= */
                        pop_diag_return_code = "12";              /* EXCEPTION - Blank Dx code, non-blank required */
							                                      /* ============================================= */
                     END;

                ELSE DO;
                       %POP_HEALTH_CONDITION_ASSIGN;
 
                       IF pop_health_cond_assign_lookup = " "
                       THEN DO;
	    		               diag_code = " ";
                                                                  /* ====================================== */
                                pop_diag_return_code = "19";      /* EXCEPTION - DX not in HC Assign table  */
                                                                  /* ====================================== */
                            END;

		             END;
             END;
		ELSE
		IF diag_classification_code = "0"
		THEN DO;
		        IF diag_code = " "
                THEN DO;
							                                      /* ============================================= */
                        pop_diag_return_code = "12";              /* EXCEPTION - Blank Dx code, non-blank required */
							                                      /* ============================================= */
                     END;

                ELSE DO;
                       %POP_HEALTH_CONDITION_ASSIGN;
 
                       IF pop_health_cond_assign_lookup = " "
                       THEN DO;
	     		                diag_code = " ";
                                                                  /* ====================================== */
                                pop_diag_return_code = "19";      /* EXCEPTION - DX not in HC Assign table  */
                                                                  /* ====================================== */
                            END;

		        END;
             END;
		ELSE

		IF diag_classification_code = "M"
		THEN DO;
		        IF diag_code = " "
                THEN DO;
                                                                  /* =================================== */
                                pop_diag_return_code = "12";      /* EXCEPTION - Invalid DX for ICD-10   */
                                                                  /* =================================== */
                     END;
                ELSE

                IF diag_code = "ZZZZ"
		        THEN DO;
		                 diag_code = " ";
                         pop_diag_return_code = "18";               /* OK - OMHRS AX with ZERO real DX codes */
                     END;

                ELSE
                DO;
                    %POP_HEALTH_CONDITION_ASSIGN;
 
                    IF pop_health_cond_assign_lookup = " "
                    THEN DO;
			                diag_code = " ";
							                                 /* =======================================*/
                            pop_diag_return_code = "19";     /* EXCEPTION - DX not in HC Assign table  */
							                                 /* =======================================*/
                        END;

                END;
             END;
        

     END;  /* OMHRS */

ELSE DO; 
                                                  /* =============================================== */
                                                  /* POP_DATA_SOURCE_CODE is NACRS or DAD            */
                                                  /*  diag_classification_code MUST be "0"           */
                                                  /*  and                                            */
                                                  /*  diag_code MUST not be blank                    */
                                                  /* =============================================== */

       IF diag_code = " "
       THEN DO;
               pop_diag_return_code = "12";             /* EXCEPTION - Blank Dx code, non-blank required */
            END;

        ELSE
        IF diag_code = "ZZZZZZZ"
		THEN DO;
		        diag_code = " ";
                                                  /* =================================== */
                pop_diag_return_code = "13";      /* EXCEPTION - Invalid DX for ICD-10   */
				                                  /*   ==> Assigned by CIHI for DAD      */
                                                  /* =================================== */
		     END;
        ELSE DO;

		          /* ================================================== */
                  /* Other DAD / NACRS DX codes are  NOT validated here */
		          /* ================================================== */

		     END;

     END;



%MEND validate_dx_codes;






DATA DTA_PRE.diag_valid

     DTA_PRE.diag_plpb_not_icd9

     DTA_PRE.diag_exception ;

  SET temp_diag_with_reg;


LENGTH prov_diag_to_icd9_key $13. 
       prov_diag_to_icd9_lookup $8.

       pop_data_source_class_key    $009. 
       pop_data_source_class_lookup $001.;
       ;


                                             
                                                      /* ======================================= */
                                                      /* Check POP_DATA_SOURCE_CODE              */
                                                      /* ======================================= */

pop_data_source_code_lookup = PUT(pop_data_source_code, $POP_DATA_SOURCE_CODE.); 

pop_data_source_class_key = pop_data_source_code || diag_classification_code ;

pop_data_source_class_lookup = PUT(pop_data_source_class_key, $POP_DATA_SOURCE_CLASSIFICATION.); 




            /* ====================================== */
            /* Default ==> POP_DIAG_RETURN_CODE = 00  */
            /* ====================================== */


IF pop_data_source_code_lookup NE "Y"   
THEN DO;
		/* ========================================================================== */
        /* EXCEPTION - Invalid POP_DATA_SOURCE_CODE                                   */ 
		/* ========================================================================== */
        diag_code = " ";
        pop_diag_return_code = "02";
     END; 
ELSE

IF pop_data_source_class_lookup NE "Y"
THEN DO;
		/* ========================================================================== */
		/* EXCEPTION - Invalid DIAG_CLASSIFICATION_CODE for the POP_DATA_SOURCE_CODE  */
		/* ========================================================================== */
        diag_code = " ";
        pop_diag_return_code = "02";                        
     END;

ELSE 
IF service_date = .
THEN DO;
        diag_code = " ";
        pop_diag_return_code = "08";             /* EXCEPTION - SERVICE DATE is missing */
     END;  
ELSE

IF service_date < REG_dob
THEN DO;
        diag_code = " ";
        pop_diag_return_code = "06";             /* EXCEPTION - SERVICE DATE IS LESS THAN REGISTRY DATE OF BIRTH */
     END;  
ELSE

IF reg_date_of_death NE . & 
   service_date > reg_date_of_death
THEN DO;
        diag_code = " ";
        pop_diag_return_code = "07";             /* EXCEPTION - Service Date is AFTER the DATE OF DEATH */
     END;  
ELSE DO;
        %VALIDATE_DX_CODES;
     END; 
 





	                                                  /* ====================================== */
	                                                  /* Write Dx records to ONE of THREE files */
	                                                  /* ====================================== */

IF pop_diag_return_code = "05"            /* PLPB Invalid ICD-9 diagnosis code */
THEN OUTPUT DTA_PRE.diag_plpb_not_icd9;
ELSE

IF pop_diag_return_code 
IN ("00" 

    "14" /* PLPB Blank diag_code  */

	"15" /* PLPB Code - DX valid but maps to POP HC ZZZZ */

	"18" /* CCRS or OMHRS Ax with no 'real' DX codes */

	)
THEN OUTPUT DTA_PRE.diag_valid;
ELSE OUTPUT DTA_PRE.diag_exception; 


DROP plpb_age_num

     pop_data_source_code_lookup

     pop_data_source_class_key
     pop_data_source_class_lookup

	 pop_health_cond_assign_lookup
     pop_health_cond_assign_key 

     age_min 
     age_max 
     gender_validation_code

	 icd9_validation_lookup
     icd9_validation_key


     prov_diag_to_icd9_key
     prov_diag_to_icd9_lookup 

	 ;
RUN;


                                                                   /* Start / End time stamps    */
DATA _NULL_;
  
   CALL SYMPUTX ("pop_10_pre_03_finish", DATETIME());

RUN;


/*==================================================*/
/* Macro to get record counts from SAS dataset "DS" */
/*==================================================*/
%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;


DATA DTA_PRE.pop_total_pre_process_diagnosis
            (KEEP = use_case_name
                        
                    pop_10_pre_03_sas_code
                    pop_10_pre_03_version_date

                    pop_10_pre_03_start 
                    pop_10_pre_03_finish

                    diag_with_reg_cnt

                    diag_duplicate_cnt
                    diag_exception_cnt
					diag_plpb_not_icd9_cnt
                    diag_valid_cnt
                    );

LENGTH diag_with_reg_cnt
       diag_duplicate_cnt
	   diag_plpb_not_icd9_cnt
       diag_exception_cnt  
       diag_valid_cnt                 008.

       pop_10_pre_03_sas_code                        
       use_case_name      $060.;

use_case_name = "POP Totals from Pre-process Diagnosis";

pop_10_pre_03_sas_code         = "&pop_10_pre_03_sas_code.";
pop_10_pre_03_version_date     = "&pop_10_pre_03_version_date.";

pop_10_pre_03_start  = &pop_10_pre_03_start.;
pop_10_pre_03_finish = &pop_10_pre_03_finish.;

FORMAT pop_10_pre_03_start 
       pop_10_pre_03_finish   DATETIME020.;


%NOBS(DTA_PRE.diag_with_reg);
diag_with_reg_cnt = &NUM;
IF diag_with_reg_cnt = . THEN diag_with_reg_cnt = 0;

%NOBS(DTA_PRE.diag_duplicate);
diag_duplicate_cnt = &NUM;
IF diag_duplicate_cnt = . THEN diag_duplicate_cnt = 0;


%NOBS(DTA_PRE.diag_exception);
diag_exception_cnt = &NUM;
IF diag_exception_cnt = . THEN diag_exception_cnt = 0;

%NOBS(DTA_PRE.diag_plpb_not_icd9);
diag_plpb_not_icd9_cnt = &NUM;
IF diag_plpb_not_icd9_cnt = . THEN diag_plpb_not_icd9_cnt = 0;


%NOBS(DTA_PRE.diag_valid);
diag_valid_cnt = &NUM;
IF diag_valid_cnt = . THEN diag_valid_cnt = 0;

FORMAT diag_with_reg_cnt
	   diag_plpb_not_icd9_cnt
       diag_duplicate_cnt
       diag_exception_cnt
       diag_valid_cnt               COMMA009.; 

RUN;



PROC PRINT DATA = DTA_PRE.pop_total_pre_process_diagnosis NOOBS;
  TITLE3         "DTA_PRE.pop_total_pre_process_diagnosis";
  BY use_case_name;
  VAR pop_10_pre_03_sas_code
      pop_10_pre_03_version_date

      pop_10_pre_03_start 
      pop_10_pre_03_finish;

RUN;



/*====================================*/
/*                                    */
/*====================================*/
