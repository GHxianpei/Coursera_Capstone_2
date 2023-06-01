
%LET pop_10_grpr_05_sas_code     = pop_10_grpr_05_report.sas;
%LET pop_10_grpr_05_version_date = 15DEC2016;

/* ======================================================================================= */
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*                                                                                         */
/* ==> Print a summary "report" for Define Pop & Group                                     */
/*                                                                                         */
/* ======================================================================================= */


OPTIONS PS = 200
        LS = 160;

DATA parameters_and_counts;

  SET DTA_OUT.parameters_define_pop_and_group;

  SET DTA_OUT.pop_total_define_population;

  SET DTA_OUT.pop_total_grouper;

  SET DTA_OUT.pop_total_ses;

RUN;



DATA _null_;
  SET  parameters_and_counts;


FILE print;


FORMAT pop_start_date 
       pop_reference_date       DATE009.;

%LET print_a_line = "----------------------------------------------------------"
                    "---------------------------";

                         /*====================*/
                         /* Header info        */
                         /*====================*/

        PUT    @ 001 "CIHI Population Grouping Methodology 1.0 - Define Population and Grouper report"
             
            // @ 001 "SAS code and data folders"
             / @ 001 "----------------------------------------------------"
             / @ 001 "MY_FOLDER:  "
             / @ 010 "&MY_FOLDER."


           // @ 001 "'POP_CODE' folder (SAS code supplied by CIHI)   "
            / @ 010 "&POP_CODE."

           // @ 001 "'METHTAB' folder (Methodology tables supplied by CIHI)"
            / @ 010 "&METHTAB."
           // @ 010 "Methodology tables read by this SAS code: "
                / @ 015 "POP_10_methtab_sas_code    : &pop_10_methtab_sas_code. "
                / @ 015 "POP_10_methtab_version_date: &pop_10_methtab_version_date. "
				
       
           // @ 001 "'CCRS_FS' folder (Files prepared by USER)"
            / @ 010 "&CCRS_FS."
            / @ 010 "User supplied Functional Status file: &FUNCTIONAL_STATUS_INPUT."

           // @ 001 "'DTA_PRE' folder (pre-processed files)"
            / @ 010 "&DTA_PRE."
       				
           // @ 001 "'DTA_OUT' folder (Define pop and grouper files)"
            / @ 010 "&DTA_OUT."

           // @ 001 "This report created by this: "
                / @ 010 "SAS code    : &pop_10_grpr_05_sas_code. "
                / @ 010 "Version date: &pop_10_grpr_05_version_date. "
       
           // @ 001 &PRINT_A_LINE.
              ;

                         /*====================*/
                         /* Parameters         */
                         /*====================*/
PUT 
       / @ 001 "USER specified parameters"
       / @ 001 "Parameter File: DTA_PRE.parameters_define_pop_and_groups"
       / @ 001 "-----------------------------------------------------------------"
       / @ 010 "Methodology year             : " methodology_year
       / @ 010 "Methodology version number   : " methodology_version_num

      // @ 010 "POP Start date               : " pop_start_date
       / @ 010 "POP Reference date           : " pop_reference_date
       / @ 010 "POP concurrent period  years : " pop_concurrent_period_years

      // @ 010 "FUNCTIONAL_STATUS_INPUT_FLAG : " functional_status_input_flag 

      // @ 001 &PRINT_A_LINE.
         ; 


%LET col_a = 025;
%LET col_b = 035;
%LET col_c = 052;


                         /*=============================*/
                         /* Define Population           */
                         /*=============================*/

PUT   // @ 001 "POP_TOTAL_DEFINE_POPULATION (File with stats and record counts)"
       / @ 001 &PRINT_A_LINE.

      // @ 010 "Define population SAS code  : " pop_10_grpr_01_sas_code
       / @ 010 "                Version date: " pop_10_grpr_01_version_date
       / @ 010 "Start time: " 
         @ 022 pop_10_grpr_01_start
       / @ 010 "Finish time: "
         @ 022 pop_10_grpr_01_finish

     /// @ 005 "REG_VALID_CNT: "
         @ &COL_B.  REG_VALID_CNT  COMMA014.
         @ &COL_C. "Pre-processed registry file"


      // @ 005 "REG_AGE_EXCEPTION_CNT: "
         @ &COL_B.  REG_AGE_EXCEPTION_CNT COMMA014.
         @ &COL_C. "Age on pop_REFERENCE_DATE > 131"

       / @ 005 "REG_OUT_OF_SCOPE_CNT: "
         @ &COL_B.  REG_OUT_OF_SCOPE_CNT COMMA014.
         @ &COL_C. "Registry records Out-Of-Scope"


       / @ 005 "REG_INPUT_TO_POP_CNT: "
         @ &COL_B.  reg_input_to_pop_cnt COMMA014.
         @ &COL_C. "Registry file for grouping"


     /// @ 005 "DIAG_VALID_CNT: "
         @ &COL_B.  DIAG_VALID_CNT COMMA014.
         @ &COL_C. "Pre-processed Diagnosis file"

      // @ 005 "DIAG_BEFORE_START_DATE_CNT: "
         @ &COL_B.  DIAG_BEFORE_START_DATE_CNT COMMA014.
         @ &COL_C. "FYI - Dx BEFORE POP conc period"

       / @ 005 "DIAG_AFTER_REF_DATE_CNT: "
         @ &COL_B.  DIAG_AFTER_REF_DATE_CNT COMMA014.
         @ &COL_C. "FYI - Dx AFTER POP conc period"

       / @ 005 "DIAG_INPUT_TO_pop_CNT: "
         @ &COL_B.  DIAG_INPUT_TO_pop_CNT COMMA014.
         @ &COL_C. "Diagnosis file for grouping"

      // @ 005 "FUNC_STATUS_INPUT_CNT: "
         @ &COL_B.  FUNC_STATUS_INPUT_CNT COMMA014.
         @ &COL_C. "Functional Status input file"

      // @ 005 "FUNC_BEFORE_START_DATE_CNT: "
         @ &COL_B.  FUNC_BEFORE_START_DATE_CNT COMMA014.
         @ &COL_C. "Before concurrent period"

       / @ 005 "FUNC_AFTER_REF_DATE_CNT: "
         @ &COL_B.  FUNC_AFTER_REF_DATE_CNT COMMA014.
         @ &COL_C. "After concurrent period"

       / @ 005 "FUNC_NOT_LAST_CNT: "
         @ &COL_B.  FUNC_NOT_LAST_CNT COMMA014.
         @ &COL_C. "Not the most recent in-scope assessments"
 
       / @ 005 "FUNC_STATUS_INPUT_TO_pop_CNT: "
         @ &COL_B.  FUNC_STATUS_INPUT_TO_pop_CNT COMMA014.
         @ &COL_C. "Functional Status records used for POP"

         ;         


                         /*=============================*/
                         /* Grouper          */
                         /*=============================*/


PUT   // @ 001 "POP_TOTAL_GROUPER (File with stats and record counts)"
       / @ 001 &PRINT_A_LINE.

      // @ 010 "POP Grouper SAS code     : " pop_10_grpr_02_sas_code
       / @ 010 "            Version date : " pop_10_grpr_02_version_date
       / @ 010 "Start time: " 
         @ 022 pop_10_grpr_02_start
       / @ 010 "Finish time: "
         @ 022 pop_10_grpr_02_finish

                         /*=============================*/
                         /* SES assignment macro         */
                         /*=============================*/
     // @ 010 "SES assignment macro (used during this step)"
      / @ 010 "-------------------------------------------"

     / @ 010 "SES SAS code    : " pop_10_grpr_03_sas_code
     / @ 010 "SES version date: " pop_10_grpr_03_version_date

                         /*=============================*/
                         /* HPG assignment macro        */
                         /*=============================*/
     // @ 010 "HPG assignment macro (used during this step)"
      / @ 010 "-------------------------------------------"
      / @ 010 "HPG SAS code    : " pop_10_grpr_04_sas_code
      / @ 010 "    version date: " pop_10_grpr_04_version_date

               
     // @ 001 &PRINT_A_LINE.

     // @ 005 "SYS_DIAG_INPUT_TO_POP_CNT: "
        @ &COL_B.  SYS_DIAG_INPUT_TO_pop_CNT COMMA014.
        @ &COL_C. "DIAGNOSIS records (for grouping)"

       / @ 005 "SYS_DIAG_BLANK_CNT: "
         @ &COL_B.  SYS_DIAG_BLANK_CNT COMMA014.
         @ &COL_C. "FYI - Blank Dx records"

       / @ 005 "SYS_DIAG_EXCEPTION_CNT: "
         @ &COL_B.  SYS_DIAG_EXCEPTION_CNT COMMA014.
         @ &COL_C. "Review - Invalid Dx codes"

      // @ 005 "SYS_DIAG_PROCESSED_CNT: "
         @ &COL_B.  sys_diag_processed_cnt COMMA014.
         @ &COL_C. "DX records to assign HCs"

       / @ 005 "SYS_DIAG_PERSON_ID_CNT: "
         @ &COL_B.  sys_diag_person_id_cnt COMMA014.
         @ &COL_C. "==> No. of HCNs covered by Dx data"

      // @ 005 "POP_DIAG_HCN_NOT_IN_SCOPE_CNT: "
         @ &COL_B.  pop_DIAG_HCN_NOT_IN_SCOPE_CNT COMMA014.
         @ &COL_C. "Review - Dx but Reg OOS for conc period"

     // @ 005 "POPULATION_CNT: "
        @ &COL_B.  POPULATION_CNT COMMA014.
        @ &COL_C. "Population count"

      / @ 008 "NON_USER_CNT:" 
        @ &COL_B. NON_USER_CNT COMMA014.
        @ &COL_C. "POP_USER_CODE = 98"

     // @ 008 "USER_CNT:"
        @ &COL_B. USER_CNT     COMMA014.  
        @ &COL_C. "1+ Health System contacts "

      / @ 008 "USER_ZERO_HC_CNT:"
        @ &COL_B. USER_ZERO_HC_CNT COMMA014.
        @ &COL_C. "POP_USER_CODE = 00"

      / @ 008 "USER_WITH_HC_CNT:"
        @ &COL_B. USER_WITH_HC_CNT COMMA014.
        @ &COL_C. "POP_USER_CODE = 01"
        ;



PUT // @ 005 "CCRS Long Term Care Functional Status info"
     / @ 005 "------------------------------------------"

     / @ 005 "FUNC_STATUS_INPUT_TO_POP_CNT: "
       @ &COL_B.  FUNC_STATUS_INPUT_TO_pop_CNT  COMMA014.
       @ &COL_C. "Func Status records (for grouping)"

     / @ 005 "POP_FUNC_HCN_NOT_IN_SCOPE_CNT: "
       @ &COL_B.  pop_FUNC_HCN_NOT_IN_SCOPE_CNT COMMA014.
       @ &COL_C. "Review - FS but no Registry"
       ;

PUT   // @ 001 "End of report"
       / @ 001 &PRINT_A_LINE.
         ;


RUN;



/*================*/
/* End of program */
/*================*/
