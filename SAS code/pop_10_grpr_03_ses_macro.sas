
%LET pop_10_grpr_03_sas_code     = pop_10_grpr_03_ses_macro.sas;
%LET pop_10_grpr_03_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP SAS GROUPER                                                                    */
/*=========================================================================================*/
/*                                                                                         */
/*  MACRO: create_pop_grouper_ses                                                          */
/*         ======================                                                          */
/*                                                                                         */
/*  Create a Socio-Economic Status (SES) file using 2006 and 2011 DA info                  */
/*  ==> 2006 and 2011 info was assigned in the Define POP section                          */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/* Input File(s):                                                                          */
/*               METHTAB.can_marg_da_2006                                                  */
/*                                                                                         */
/*               METHTAB.inspq_equivalent_2011                                             */
/*                                                                                         */
/*               temp_pop_grouper_assign (Registry psotacl code and GEO info(              */
/*                                                                                         */
/*                                                                                         */
/* Output File(s):                                                                         */
/*                                                                                         */
/*               DTA_OUT.pop_grouper_ses                                                   */
/*                                                                                         */
/*                       POP_SES_CANMARG_RETURN_CODE                                       */
/*                       00 – Successful match to PCCF and CAN_MARG file                   */
/*                       53  - 2006 Dissemination Area cannot be assigned                  */
/*                       54  - No match in CAN_MARG_DA_2006 table                          */
/*                       55  - CAN-Marg Index cannot be assigned                           */
/*                       56  - Registry Postal Code is blank or missing                    */
/*                       57  - No match found in POP_PCCF table                            */
/*                                                                                         */
/*                       POP_SES_INSPQ_RETURN_CODE                                         */
/*                       00 – Successful match to PCCF and INSPQ files                     */
/*                       50  - 2011 Dissemination Area cannot be assigned                  */
/*                       51  - No match in INSPQ_EQUIVALENT_2011 table                     */
/*                       56  - Registry Postal Code is blank or missing                    */
/*                       57  - No match found in POP_PCCF table                            */
/*                                                                                         */
/*                                                                                         */
/*=========================================================================================*/



/* ======================================================================================================= */
/* CREATE_POP_TOTAL_SES                                                                                    */
/*                                                                                                         */
/* ======================================================================================================= */

                                                           /*==================================================*/
                                                           /* Create a file with record counts                   */
                                                           /*==================================================*/
%MACRO create_pop_total_ses;


%MACRO NOBS(DS);
    %GLOBAL NUM;
    %LET DSID = %SYSFUNC(OPEN(&DS.,IN));
    %LET NUM = %SYSFUNC(ATTRN(&DSID,NOBS));
    %LET RC = %SYSFUNC(CLOSE(&DSID));
%MEND;

                                                          /*==================================================*/
                                                           /* Create a file with record counts                 */
                                                           /*==================================================*/

DATA DTA_OUT.pop_total_ses
            (KEEP = use_case_name
                    pop_10_grpr_03_sas_code
                    pop_10_grpr_03_version_date
                    pop_10_grpr_03_start
                    pop_10_grpr_03_finish

					grouper_pop_cnt
                    pop_grouper_ses_cnt

                    );


LENGTH grouper_pop_cnt
       pop_grouper_ses_cnt        008.

       pop_10_grpr_03_sas_code 
       use_case_name             $060.;

use_case_name = "POP 1.0 - Totals from SES assignment";

pop_10_grpr_03_sas_code         = "&pop_10_grpr_03_sas_code.";
pop_10_grpr_03_version_date     = "&pop_10_grpr_03_version_date.";

pop_10_grpr_03_start  = &pop_10_grpr_03_start.;
pop_10_grpr_03_finish = &pop_10_grpr_03_finish.;

FORMAT pop_10_grpr_03_start
       pop_10_grpr_03_finish   DATETIME020.;


                                                                         /* ================  */
                                                                         /* Grouper           */
                                                                         /* ================  */
%NOBS(temp_pop_grouper_assign);

grouper_pop_cnt = &NUM;
IF grouper_pop_cnt = . THEN grouper_pop_cnt = 0;


                                                                         /* ================  */
                                                                         /* POP Grouper SES   */
                                                                         /* ================  */
%NOBS(DTA_OUT.pop_grouper_ses);
   pop_grouper_ses_cnt = &NUM;
IF pop_grouper_ses_cnt = . THEN pop_grouper_ses_cnt = 0;


FORMAT grouper_pop_cnt
       pop_grouper_ses_cnt                     COMMA014.; 


RUN;

PROC PRINT DATA = DTA_OUT.pop_total_ses NOOBS;
  TITLE3         "DTA_OUT.pop_total_ses";
  BY 
     pop_10_grpr_03_start
     pop_10_grpr_03_finish;

  VAR pop_10_grpr_03_sas_code 
      grouper_pop_cnt
      pop_grouper_ses_cnt
      ;
RUN;

%MEND create_pop_total_ses;


/* ======================================================================================================= */
/* UC170426: ASSIGN ses                                                                                    */
/*                                                                                                         */
/* ======================================================================================================= */

%MACRO create_pop_grouper_ses;

                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _NULL_;

CALL SYMPUTX ("pop_10_grpr_03_start", DATETIME() );

RUN;


/* =============================================================== */
/* use 2011 DA to get INSPQ info                                   */
/* =============================================================== */
%MACRO PROCESS_da11uid_inspq;  

IF da11uid NE "-7" 
THEN DO; 

         %inspq_equivalent;

         IF NOT MISSING(inspq_equivalent_lookup)
         THEN DO;
                 inspq_quintmat11     = SUBSTR(inspq_equivalent_lookup, 1, 1);
                 inspq_quintsoc11     = SUBSTR(inspq_equivalent_lookup, 2, 1);
                 inspq_quintmatcr11   = SUBSTR(inspq_equivalent_lookup, 3, 1);
                 inspq_quintsoccr11   = SUBSTR(inspq_equivalent_lookup, 4, 1);
                 inspq_quintmatzone11 = SUBSTR(inspq_equivalent_lookup, 5, 1);
                 inspq_quintsoczone11 = SUBSTR(inspq_equivalent_lookup, 6, 1);
                 inspq_quintmatcma11  = SUBSTR(inspq_equivalent_lookup, 7, 1);
                 inspq_quintsoccma11  = SUBSTR(inspq_equivalent_lookup, 8, 1);

                 inspq_region11       = SUBSTR(inspq_equivalent_lookup, 9, 20);
                 inspq_zone11         = SUBSTR(inspq_equivalent_lookup, 29, 1);

                 IF inspq_quintmat11 = " "     THEN inspq_quintmat11 = "9";
                 IF inspq_quintsoc11 = " "     THEN inspq_quintsoc11 = "9";
                 IF inspq_quintmatcr11 = " "   THEN inspq_quintmatcr11 = "9";
                 IF inspq_quintsoccr11 = " "   THEN inspq_quintsoccr11 = "9";
                 IF inspq_quintmatzone11 = " " THEN inspq_quintmatzone11 = "9";
                 IF inspq_quintsoczone11 = " " THEN inspq_quintsoczone11 = "9";
                 IF inspq_quintmatcma11 = " "  THEN inspq_quintmatcma11 = "9";
                 IF inspq_quintsoccma11 = " "  THEN inspq_quintsoccma11 = "9";

                pop_ses_inspq_return_code = "00";
              END;
         ELSE DO;
                 /* ========================================================= */
                 /*  No Match in the INSPQ_EQUIVALENT_2011 table              */
                 /* ========================================================= */
                pop_ses_inspq_return_code = "51";
             END;

     END; 

ELSE DO;  /* da11uid = "-7" */
        pop_ses_inspq_return_code = "50";
     END;

%MEND  PROCESS_da11uid_inspq; 



/* =============================================================== */
/* use 2006 DA to get CANMARG info                                 */
/* =============================================================== */
%MACRO PROCESS_da06uid_canmarg; 

IF da06uid NE "-7" 
THEN DO;  /*  da06uid NE "-7" */

        %CAN_MARG_DA;

        IF NOT MISSING(can_marg_da_2006_lookup) 
        THEN DO; 
                 canmarg_dependency_q_da06  = SUBSTR(can_marg_da_2006_lookup, 1, 1);
                 canmarg_deprivation_q_da06 = SUBSTR(can_marg_da_2006_lookup, 2, 1);
                 canmarg_ethniccon_q_da06   = SUBSTR(can_marg_da_2006_lookup, 3, 1);
                 canmarg_instability_q_da06 = SUBSTR(can_marg_da_2006_lookup, 4, 1);
                 pop_ses_canmarg_return_code = "00";

                 IF canmarg_instability_q_da06 = "."
                 THEN DO;
                         canmarg_dependency_q_da06 = "9"; 
                         canmarg_deprivation_q_da06 = "9"; 
                         canmarg_ethniccon_q_da06 = "9"; 
                         canmarg_instability_q_da06 = "9"; 

                         pop_ses_canmarg_return_code = "55";  /* Can Marge index is null */
                    END;

             END;
        ELSE DO;
                 /* =========================================================== */
                 /* No match found in CANMARG_DA_2006 table                     */
                 /* =========================================================== */
                pop_ses_canmarg_return_code = "54";
            END;

     END;   
ELSE DO; 
        pop_ses_canmarg_return_code = "53";
     END; 

%MEND  PROCESS_da06uid_canmarg;    


/* ======================================================================== */
/* ======================================================================== */

DATA DTA_OUT.pop_grouper_ses;

LENGTH 
	   pop_ses_inspq_return_code   $002.
       inspq_region11              $020.
       inspq_zone11                $001.
       inspq_quintmat11            $001.
       inspq_quintsoc11            $001.
       inspq_quintmatcr11          $001.
       inspq_quintsoccr11          $001.
       inspq_quintmatzone11        $001.
       inspq_quintsoczone11        $001.
       inspq_quintmatcma11         $001.
       inspq_quintsoccma11         $001.

	   pop_ses_canmarg_return_code $002.
       canmarg_dependency_q_da06   $001.
       canmarg_deprivation_q_da06  $001.
       canmarg_ethniccon_q_da06    $001.
       canmarg_instability_q_da06  $001.;

    SET temp_pop_grouper_assign 
            (KEEP = methodology_year
                    methodology_version_num
                    pop_start_date
                    pop_reference_date
                    province_code
                    person_id
                    reg_postal_code

                    region_code

                    da06uid
                    qaippe06

                    da11uid
                    qaippe11);


LENGTH methodology_year 4.   
       methodology_version_num 4 ;


pop_ses_canmarg_return_code = "--";
pop_ses_inspq_return_code = "--";


IF reg_postal_code = " "               
THEN DO;
                                      		/* Exception - Postal code is blank  */
		pop_ses_canmarg_return_code = "56";
		pop_ses_inspq_return_code = "56";
     END;
ELSE DO;

        IF da06uid = "-7"
        THEN DO;
                 pop_ses_canmarg_return_code = "57";   /* Postal code BUT not on PCCF */
             END;
        ELSE DO;
				 %process_da06uid_canmarg;
             END;


        IF da11uid = "-7"
        THEN DO;
                 pop_ses_inspq_return_code = "57";   /* Postal code BUT not on PCCF */
             END;
        ELSE DO;
				 %process_da11uid_inspq;
             END;


     END;


KEEP methodology_year
     methodology_version_num

     pop_start_date
     pop_reference_date

     province_code
     person_id
     reg_postal_code

	 region_code

     pop_ses_canmarg_return_code
     da06uid                     
     qaippe06  

     canmarg_dependency_q_da06   
     canmarg_deprivation_q_da06 
     canmarg_ethniccon_q_da06    
     canmarg_instability_q_da06                  

     pop_ses_inspq_return_code
     da11uid                     
     qaippe11                    

     inspq_region11
     inspq_zone11        
     inspq_quintmat11
     inspq_quintsoc11            
     inspq_quintmatcr11          
     inspq_quintsoccr11         
     inspq_quintmatzone11        
     inspq_quintsoczone11        
     inspq_quintmatcma11         
     inspq_quintsoccma11   
     ;

RUN;

                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _NULL_;

CALL SYMPUTX ("pop_10_grpr_03_finish", DATETIME() );

RUN;

%create_pop_total_ses;



%MEND create_pop_grouper_ses;



%MACRO review;

PROC FREQ DATA = DTA_OUT.pop_grouper_ses;
  TITLE3        "DTA_OUT.pop_grouper_ses ";
  TITLE5 "&DTA_OUT.";
  BY methodology_year
     methodology_version_num
    province_code;
  TABLES pop_ses_canmarg_return_code  * pop_ses_inspq_return_code

		 region_code * da06uid
         region_code * da11uid

		 qaippe06 * qaippe11

		  
         inspq_region11 * canmarg_dependency_q_da06
 
		  pop_start_date
                    pop_reference_date
         /MISSING NOROW NOCOL NOPERCENT NOCUM FORMAT = COMMA011.;
  FORMAT da06uid
         da11uid $002.;
RUN;   
 
%MEND review;




/*================*/
/* End of program */
/*================*/

