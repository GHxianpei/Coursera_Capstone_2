
%LET pop_10_pre_04_sas_code     = pop_10_preprocess_04_report.sas;
%LET pop_10_pre_04_version_date = 15DEC2016;

/* ======================================================================================= */
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*                                                                                         */
/* ==> Print a summary "report" for Pre-Processing                                         */
/*                                                                                         */
/* ======================================================================================= */


TITLE2;

OPTIONS PS = 200
        LS = 160;

DATA _null_;

 SET DTA_PRE.parameters_pre_processing        (IN = pre_parms)

     DTA_PRE.pop_total_pre_process_registry   (IN = pre_01)

     DTA_PRE.pop_total_add_reg_info_to_dx     (IN = pre_02)

     DTA_PRE.pop_total_pre_process_diagnosis  (IN = pre_03)

     ;

FILE print;


%LET print_a_line = "----------------------------------------------------------"
                    "---------------------------";



                                               /*====================*/
                                               /* Header info        */
                                               /*====================*/
IF _N_ = 1
THEN DO;
        PUT
               @ 001 "CIHI Population Grouping Methodology 1.0 - Pre-Processing Report"

            // @ 001 "SAS code and data folders"
             / @ 001 "----------------------------------------------------"
             / @ 001 "MY_FOLDER:  "
             / @ 010 "&MY_FOLDER."


           // @ 001 "'POP_CODE' folder (SAS code supplied by CIHI)   "
            / @ 010 "&POP_CODE."

           // @ 001 "'METHTAB' folder (Methodology tables supplied by CIHI)"
            / @ 010 "&METHTAB."
           // @ 010 "Methodology tables read by this SAS code: "
                / @ 015 "POP_10_METHTAB_SAS_CODE     : &pop_10_methtab_sas_code. "
                / @ 015 "POP_10_METHTAB_VERSION_DATE : &pop_10_methtab_version_date. "
	
           // @ 001 "'DTA_IN' folder (Files prepared by USER)"
            / @ 010 "&DTA_IN."
           // @ 015 "User supplied RPDB file:      &REGISTRY_INPUT."
            / @ 015 "User supplied Diagnosis file: &DIAGNOSIS_INPUT."

           // @ 001 "'DTA_PRE' folder (pre-processed files)"
            / @ 010 "&DTA_PRE."

           // @ 001 "This report created by this SAS code: "
                / @ 010 "pop_10_pre_04_SAS_CODE    : &pop_10_pre_04_SAS_CODE. "
                / @ 010 "pop_10_pre_04_version_date: &pop_10_pre_04_version_date. "
				  

              ;
     END;


                                               /*====================*/
                                               /* Parameters         */
                                               /*====================*/
IF pre_parms
THEN DO;
        PUT 
            // @ 001 "USER specified parameters"
             / @ 001 "Parameter File: DTA_PRE.parameters_pre_processing)"
             / @ 001 "-----------------------------------------------------------------"
        	 / @ 010 "Methodology year            : " methodology_year
             / @ 010 "Methodology version number  : " methodology_version_num
           /// @ 001 &PRINT_A_LINE.
               ; 
     END;


                                               /*=============================*/
                                               /* Counts for each segment    */
                                               /*=============================*/
%LET col_b = 030;
%LET col_c = 045;

IF pre_01
THEN DO;
         PUT   // @ 001 "POP_TOTAL_PRE_PROCESS_REGISTRY (File with stats and record counts)"
                / @ 001 &PRINT_A_LINE.

               // @ 010 "POP_10_PRE_01_SAS_CODE    : "
                         pop_10_pre_01_sas_code
                / @ 010 "POP_10_PRE_01_VERSION_DATE: "
                         pop_10_pre_01_version_date
                / @ 010 "Start time: "
                  @ 022 pop_10_pre_01_start
                / @ 010 "Finish time: "
                  @ 022 pop_10_pre_01_finish


               // @ 005 "REG_INPUT_CNT: "
                  @ &COL_B. reg_input_cnt  COMMA014.
				  @ &COL_C. "Registry recs (USER provided file)"

               // @ 005 "REG_DUPLICATE_CNT: "
                  @ &COL_B.  REG_DUPLICATE_CNT COMMA014.
				  @ &COL_C. "Rejected recs - PERSON_ID was NOT unique"

                / @ 005 "REG_EXCEPTION_CNT: "
                  @ &COL_B.  REG_EXCEPTION_CNT COMMA014.
				  @ &COL_C. "Rejected recs - DOB or Gender anomaly"

               // @ 005 "REG_VALID_CNT: "
                  @ &COL_B.  REG_VALID_CNT  COMMA014.
				  @ &COL_C. "Usable registry recs"
				  ;
     END;


IF pre_02
THEN DO;

         PUT   // @ 001 "POP_TOTAL_ADD_REG_INFO_TO_DX (File with stats and record counts)"
                / @ 001 &PRINT_A_LINE.

               // @ 010 "POP_10_PRE_02_SAS_CODE    : "
                         pop_10_pre_02_sas_code
                / @ 010 "POP_10_PRE_02_VERSION_DATE: "
                         pop_10_pre_02_version_date
                / @ 010 "Start time: "
                  @ 022 pop_10_pre_02_start
                / @ 010 "Finish time: "
                  @ 022 pop_10_pre_02_finish

               // @ 005 "REG_VALID_CNT: "
                  @ &COL_B.  REG_VALID_CNT  COMMA014.
				  @ &COL_C. "Usable registry recs"

                / @ 005 "REG_NO_DIAG_CNT: "
                  @ &COL_B.  REG_NO_DIAG_CNT COMMA014.
				  @ &COL_C. "FYI - Registry recs with zero Dx recs"

                / @ 005 "REG_WITH_DIAG_CNT: "
                  @ &COL_B.  REG_WITH_DIAG_CNT COMMA014.
				  @ &COL_C. "FYI - Registry recs with 1+ Dx recs"


               // @ 005 "DIAG_INPUT_CNT: "
                  @ &COL_B.  DIAG_INPUT_CNT  COMMA014.
				  @ &COL_C. "Diagnosis recs (USER provided file)"

               // @ 005 "DIAG_WITH_REG_CNT: "
                  @ &COL_B.  DIAG_WITH_REG_CNT COMMA014.
				  @ &COL_C. "DIAG_WITH_REG file - Dx recs with REG info"

               // @ 005 "DIAG_NO_REG_CNT: "
                  @ &COL_B.  DIAG_NO_REG_CNT COMMA014.
				  @ &COL_C. "Review - No Registry for these DIAG recs"

                / @ 005 "DIAG_NO_REG_PERSON_ID_CNT: "
                  @ &COL_B.  diag_no_reg_person_ID_CNT COMMA014.
				  @ &COL_C. "       - Number of PERSON_IDs represented"
				  ;
     END;


IF pre_03
THEN DO;
         PUT   // @ 001 "POP_TOTAL_PRE_PROCESS_DIAGNOSIS (File with stats and record counts)"
                / @ 001 &PRINT_A_LINE.

               // @ 010 "POP_10_PRE_03_SAS_CODE    : "
                         pop_10_pre_03_sas_code
                / @ 010 "POP_10_PRE_03_VERSION_DATE: "
                         pop_10_pre_03_version_date
                / @ 010 "Start time: "
                  @ 022 pop_10_pre_03_start
                / @ 010 "Finish time: "
                  @ 022 pop_10_pre_03_finish

               // @ 005 "DIAG_WITH_REG_CNT: "
                  @ &COL_B.  DIAG_WITH_REG_CNT COMMA014.
				  @ &COL_C. "DIAG_WITH_REG File created by POP 12"

               // @ 005 "DIAG_DUPLICATE_CNT: "
                  @ &COL_B.  DIAG_DUPLICATE_CNT COMMA014.
				  @ &COL_C. "DIAG_DUPLICATE file (OK not a problem)"

               // @ 005 "DIAG_EXCEPTION_CNT: "
                  @ &COL_B.  DIAG_EXCEPTION_CNT COMMA014.
				  @ &COL_C. "Review - DIAG_EXCEPTION file"

               // @ 005 "DIAG_PLPB_NOT_ICD9_CNT: "
                  @ &COL_B.  DIAG_PLPB_NOT_ICD9_CNT COMMA014.
				  @ &COL_C. "Review - DIAG_PLPB_NOT_ICD9 file"

               // @ 005 "DIAG_VALID_CNT: "
                  @ &COL_B.  DIAG_VALID_CNT COMMA014.
				  @ &COL_C. "DIAG_VALID file (Valid Dx codes)"

               // @ 001 "End of report"
                / @ 001 &PRINT_A_LINE.

				  ;

     END;


RUN;



/*================*/
/* End of program */
/*================*/
