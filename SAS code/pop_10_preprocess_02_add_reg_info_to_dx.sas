
%LET pop_10_pre_02_sas_code     = pop_10_preprocess_02_add_reg_info_to_dx.sas;
%LET pop_10_pre_02_version_date = 15DEC2016;

/*=========================================================================================*/
/* CIHI POP 1.0 SAS GROUPER                                                                */
/*=========================================================================================*/
/* Use Case:                                                                               */
/*                                                                                         */
/* Input File(s):                                                                          */
/*               DTA_PRE.registry_valid                                                    */
/*                                                                                         */
/*               DTA_IN.&DIAGNOSIS_INPUT                                                   */
/*                                                                                         */
/* Output File(s):                                                                         */
/*               DTA_PRE.diag_with_reg                                                     */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       00 - OK                                                           */
/*                                                                                         */
/*               DTA_PRE.diag_no_reg                                                       */
/*                       POP_DIAG_RETURN_CODE values                                       */
/*                       03 - Person in Dx file not in Registry                            */
/*                                                                                         */
/*               _temp_reg_no_dx_                                                          */
/*                                                                                         */
/*                                                                                         */
/*               DTA_PRE.pop_total_add_reg_info_to_dx                                      */
/*                                                                                         */
/*=========================================================================================*/

DATA _NULL_;

   CALL SYMPUTX ("pop_10_pre_02_start", DATETIME());

RUN;



PROC SORT DATA = DTA_PRE.reg_valid;
    BY province_code
       person_id;
RUN;


PROC SORT 
    DATA = DTA_IN.&DIAGNOSIS_INPUT
                 (KEEP = province_code
                         person_id
                         service_date
                         pop_data_source_code
                         physician_id
                         data_source_id
                         diag_classification_code
                         diag_code);
    BY province_code
       person_id;
RUN;



DATA DTA_PRE.diag_with_reg

     DTA_PRE.diag_no_reg
                 (KEEP = province_code
                         person_id
                         service_date
                         pop_data_source_code
                         physician_id
                         data_source_id
                         diag_classification_code
                         diag_code
                         pop_diag_return_code )

     temp_reg_with_diag
                 (KEEP = person_id)

     temp_reg_no_diag
                 (KEEP = person_id)

     temp_diag_no_reg_person_id
                 (KEEP = person_id);

    MERGE DTA_IN.&DIAGNOSIS_INPUT
               (IN = diag_file)

          DTA_PRE.reg_valid
               (IN = reg_file 
                KEEP = province_code
                       person_id
                       reg_dob
                       reg_gender_code
                       reg_date_of_death);
    BY province_code
       person_id;


IF reg_file & 
   diag_file
THEN DO;
                                           /* ======================================= */
                                           /* PERSON_ID is on both REG and DIAG files */
                                           /* ======================================= */
        IF FIRST.person_id
        THEN OUTPUT temp_reg_with_diag ;               /* Count number of REG records with 1+ Dx recrods */

        pop_diag_return_code = "00" ;
        OUTPUT DTA_PRE.diag_with_reg;
     END;
ELSE

IF diag_file 
THEN DO;
                                           /* ===================================== */
                                           /* PERSON_ID is on the DIAG file only !! */
                                           /* ===================================== */
        IF FIRST.person_id
        THEN OUTPUT temp_diag_no_reg_person_id;     /* Number of person_ids */

        pop_diag_return_code = "03" ;
        OUTPUT DTA_PRE.diag_no_reg;
     END;
ELSE DO;
                                           /* REG file only */
        OUTPUT temp_reg_no_diag;
     END;

RUN;



DATA _NULL_;

   CALL SYMPUTX ("pop_10_pre_02_finish", DATETIME());

RUN;


                                         /* ================================================ */
                                         /* Macro to get record counts from SAS dataset "DS" */
                                         /* ================================================ */
%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;


DATA DTA_PRE.pop_total_add_reg_info_to_dx
            (KEEP = use_case_name

                    pop_10_pre_02_sas_code
                    pop_10_pre_02_version_date

                    pop_10_pre_02_start
                    pop_10_pre_02_finish

                    reg_valid_cnt
                    reg_with_diag_cnt
                    reg_no_diag_cnt

                    diag_input_cnt
                    diag_with_reg_cnt         
                    diag_no_reg_cnt
                    diag_no_reg_person_id_cnt

                   );

LENGTH reg_valid_cnt
       reg_with_diag_cnt
       reg_no_diag_cnt

       diag_input_cnt
       diag_with_reg_cnt
       diag_no_reg_cnt
       diag_no_reg_person_id_cnt   8.

       pop_10_pre_02_sas_code                        
       use_case_name            $060.;

use_case_name                  = "POP Totals from Merge DOB & Gender";

pop_10_pre_02_sas_code         = "&pop_10_pre_02_sas_code.";
pop_10_pre_02_version_date     = "&pop_10_pre_02_version_date.";


pop_10_pre_02_start = &pop_10_pre_02_start.;
pop_10_pre_02_finish = &pop_10_pre_02_finish.;


    %NOBS(DTA_IN.&DIAGNOSIS_INPUT);
    diag_input_cnt = &NUM;
    IF diag_input_cnt = . THEN diag_input_cnt = 0;


    %NOBS(DTA_PRE.reg_valid);
    reg_valid_cnt = &NUM;
    IF reg_valid_cnt = . THEN reg_valid_cnt = 0;


    %NOBS(temp_reg_no_diag);
    reg_no_diag_cnt = &NUM;
    IF reg_no_diag_cnt = . THEN reg_no_diag_cnt = 0;

    %NOBS(temp_reg_with_diag);
    reg_with_diag_cnt = &NUM;
    IF reg_with_diag_cnt = . THEN reg_with_diag_cnt = 0;


    %NOBS(DTA_PRE.diag_with_reg);
    diag_with_reg_cnt = &NUM;
    IF diag_with_reg_cnt = . THEN diag_with_reg_cnt = 0;

    %NOBS(DTA_PRE.diag_no_reg);
    diag_no_reg_cnt = &NUM;
    IF diag_no_reg_cnt = . THEN DIAG_no_reg_cnt = 0;


    %NOBS(temp_diag_no_reg_person_id);
    diag_no_reg_person_id_cnt = &NUM;
    IF diag_no_reg_person_id_cnt = . THEN diag_no_reg_person_id_cnt = 0;


FORMAT pop_10_pre_02_start 
       pop_10_pre_02_finish   DATETIME020.

       reg_valid_cnt
       reg_no_diag_cnt
       reg_with_diag_cnt

       diag_input_cnt
       diag_no_reg_cnt
       diag_no_reg_person_id_cnt
       diag_with_reg_cnt            COMMA014.; 
RUN;


PROC PRINT DATA = DTA_PRE.pop_total_add_reg_info_to_dx NOOBS;
  TITLE3         "DTA_PRE.pop_total_add_reg_info_to_dx";
  BY use_case_name;
  VAR 
      reg_valid_cnt
      reg_no_diag_cnt
      reg_with_diag_cnt

      diag_input_cnt
      diag_with_reg_cnt 
      diag_no_reg_cnt
      diag_no_reg_person_id_cnt
       ;

RUN;
        
PROC PRINT DATA = DTA_PRE.pop_total_add_reg_info_to_dx NOOBS;
  TITLE3         "DTA_PRE.pop_total_add_reg_info_to_dx";
  BY use_case_name;
  VAR pop_10_pre_02_sas_code
      pop_10_pre_02_version_date

      pop_10_pre_02_start 
      pop_10_pre_02_finish

       ;

RUN;


PROC DATASETS NOLIST;
   DELETE temp_reg_no_diag
          temp_reg_w_diag
          temp_diag_no_reg_person_id; 
RUN;



/*=========================*/
/* End of SAS program      */
/*=========================*/
