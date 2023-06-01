
%LET pop_10_methtab_sas_code     = pop_10_methodology_tables.sas;
%LET pop_10_methtab_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*                                                                                         */
/*=========================================================================================*/


/*=========================================================================================*/
/* SAS FORMATS Created                                                                     */
/*=========================================================================================*/
/* SAS FORMATs created by this program
/*      DOB_YEAR
/*      FISCAL_YEAR
/*      $POP_METHODOLOGY_RETURN
/*  
/* Formats for POP Health Conditions, overrides and additive RIWs
/* =================================================    
/*     $POP_HEALTH_CONDITION
/*     $POP_HC_INTERACTION_RIW 
/*  
/*     
/* Formats for HPG - Health Profile Group
/* =================================================    
/*     $POP_HPG
/*  
/*     
/* Formats for PHC, ED and LTC PREDICTIVE INDICATORS
/* =================================================    
/*     $POP_PHC_BASE_VISIT
/*     $POP_PHC_HC_VISIT
/*     $POP_PHC_INTERACT_VISIT.
/*     
/*     $POP_ED_BASE_VISIT.
/*     $POP_ED_HC_VISIT.
/*     
/*     $POP_LTC_BASE_PROBABILITY
/*     $POP_LTC_HC_PROBABILITY.
/*     $POP_LTC_HC_USER_PROBABILITY.
/*     $POP_LTC_INTERACT_PROBABILITY
/*     
/*                                                                                         */
/*=========================================================================================*/

                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _meth_tab_stats_;

FILE print;

  FORMAT meth_tab_start DATETIME020.;

  meth_tab_start = DATETIME();


PUT // @ 010 "     SAS code     : &pop_10_methtab_sas_code. "
    // @ 010 "     Version date : &pop_10_methtab_version_date."
   /// @ 010 "Methodology Tables  &METHTAB."
       ;

PUT // @ 010 "                                        METH_TAB_START  : " meth_tab_start
       ;

RUN;




/* ===================================================================================== */
/* PREPARE MACRO VARIABLES . . . . the secret weapons CRUCIAL for POP 1.0 processing     */
/*                                                                                       */
/*           &HC_LIST is                     */
/*                                                                                       */
/*           &SYS_HC_COUNT is the number of Health Conditions (EXCLUDING "ZZZZ")         */
/*                                                                                       */
/* ===================================================================================== */

PROC SORT DATA = METHTAB.pop_health_condition 
          OUT =          pop_health_condition;
   WHERE health_condition_code NE "ZZZZ";
   BY health_condition_code;
RUN;


%GLOBAL sys_hc_cnt  HC_LIST  HC_LIST_COMMA  CNT_P_HC   ;

PROC SQL  NOPRINT;
  SELECT COUNT(health_condition_code) AS sys_hc_cnt,
         health_condition_code, 
         health_condition_code, 
         'CNT_P_HC_'||health_condition_code||'' 

  INTO   :sys_hc_cnt,
         :HC_LIST        SEPARATED BY ' ' ,
         :HC_LIST_COMMA  SEPARATED BY ', ' ,
         :CNT_P_HC       SEPARATED BY ' '

  FROM pop_health_condition;

QUIT;


%PUT &SYS_HC_CNT;

%PUT &HC_LIST.;


                                                            /* ========================= */
                                                            /* Set HPG macro variables
                                                            /* ========================= */

PROC SORT DATA = METHTAB.pop_hpg_branch
          OUT  =         pop_hpg_branch_WITH_HC;
     BY branch_id;
     WHERE branch_code NOT IN ("Z00" "Z98");

RUN;


PROC SQL  NOPRINT;
  SELECT COUNT(branch_code) AS SYS_HPG_BRANCH_CNT,
         "HPG_" || branch_code,
         "HPG_COMBO_" || branch_code,
         "HPG_COMORBID_" || branch_code,
         "HPG_BRANCH_RANK_" || branch_code

  INTO   :SYS_HPG_BRANCH_CNT,
         :HPG_BRANCH_CODE_LIST      SEPARATED BY ' ', 
         :HPG_BRANCH_COMBO_LIST     SEPARATED BY ' ', 
         :HPG_BRANCH_COMORBID_LIST  SEPARATED BY ' ' ,
         :HPG_BRANCH_RANK_LIST      SEPARATED BY ' ' 

  FROM pop_hpg_branch_WITH_HC;

QUIT;

%PUT &SYS_HPG_BRANCH_CNT;

%PUT &HPG_BRANCH_CODE_LIST.;

%PUT &HPG_BRANCH_COMBO_LIST.;

%PUT &HPG_BRANCH_COMORBID_LIST.;

%PUT &HPG_BRANCH_RANK_LIST.;


                                                                    /* ====================================== */
                                                                    /* SET  MACRO vars                        */
                                                                    /*   index_s01_palliative_state           */
                                                                    /*   index_s44_newborn                    */
                                                                    /* ====================================== */
DATA _null_;
    SET pop_health_condition;

    IF health_condition_code = "S01"
    THEN DO;
            CALL SYMPUTX("index_s01_palliative_state", hc_seq_id);
         END;
    ELSE 
    IF health_condition_code = "N44"
    THEN DO;
            CALL SYMPUTX("index_n44_healthy_newborn", hc_seq_id);
         END;
RUN;

%PUT &index_n44_healthy_newborn;

%PUT &index_s01_palliative_state;




/*==========================================================================*/
/* FORMAT - $REGION_CODE
/*==========================================================================*/

PROC FORMAT ;
      VALUE $REGION_CODE
                "1011" = "Eastern Regional Integrated Health Authority"
                "1012" = "Central Regional Integrated Health Authority"
                "1013" = "Western Regional Integrated Health Authority"
                "1014" = "Labrador-Grenfell Regional Integrated Health Authority"  
                "1099" = "NL - Unknown"

                "1100" = "Prince Edward Island"  
                "1199" = "PEI - Unknown"   

                "1201" = "Zone 1 - Western"
                "1202" = "Zone 2 - Northern"
                "1203" = "Zone 3 - Eastern"
                "1204" = "Zone 4 - Central"
                "1299" = "NS - Unknown"   

                "1301" = "Region 1 (Moncton area)"
                "1302" = "Region 2 (Saint John area)"
                "1303" = "Region 3 (Fredericton area)"
                "1304" = "Region 4 (Edmundston area)"
                "1305" = "Region 5 (Campbellton area)"
                "1306" = "Region 6 (Bathurst area)"
                "1307" = "Region 7 (Miramichi area)"   
                "1399" = "NB - Unknown"   


                "2401" = "Bas-Saint-Laurent" 
                "2402" = "Saguenay—Lac-Saint-Jean"
                "2403" = "Capitale nationale"
                "2404" = "Mauricie et du Centre-du-Québec"
                "2405" = "Estrie"
                "2406" = "Montréal"
                "2407" = "Outaouais"
                "2408" = "Abitibi-Témiscamingue"
                "2409" = "Côte-Nord"
                "2410" = "Nord du Québec"
                "2411" = "Gaspésie-Îles-de-la-Madeleine"
                "2412" = "Chaudière Appalaches"
                "2413" = "Laval"
                "2414" = "Lanaudière"
                "2415" = "Laurentides"
                "2416" = "Montérégie"
                "2417" = "Nunavik"
                "2418" = "Terre-Cries-de-la-Baie-James"      
                "2499" = "QC " 

                "3501" = "Erie St. Clair"
                "3502" = "South West"
                "3503" = "Waterloo Wellington"
                "3504" = "Hamilton Niagara Haldimand Brant"
                "3505" = "Central West"
                "3506" = "Mississauga Halton"
                "3507" = "Toronto Central"
                "3508" = "Central"
                "3509" = "Central East"
                "3510" = "South East"
                "3511" = "Champlain"
                "3512" = "North Simcoe Muskoka"
                "3513" = "North East"
                "3514" = "North West" 
                "3599" = "ON = Unknown"

				"4601" = "Winnipeg RHA "
				"4602" = "Prairie Mountain RHA"
				"4603" = "Interlake-Eastern RHA"
				"4604" = "Northern RHA"
				"4605" = "Southern RHA"
                "4699" = "MB - Unknown"


                "4701" = "Sun Country Regional Health Authority"
                "4702" = "Five Hills Regional Health Authority"
                "4703" = "Cypress Regional Health Authority"
                "4704" = "Regina Qu'Appelle Regional Health Authority"
                "4705" = "Sunrise Regional Health Authority"
                "4706" = "Saskatoon Regional Health Authority"
                "4707" = "Heartland Regional Health Authority"
                "4708" = "Kelsey Trail Regional Health Authority"
                "4709" = "Prince Albert Parkland Regional Health Authority"
                "4710" = "Prairie North Regional Health Authority"
                "4711" = "Mamawetan Churchill River Regional Health Authority"
                "4712" = "Keewatin Yatthé Regional Health Authority"
                "4713" = "Athabasca Health Authority"  
                "4799" = "SK - Unknown"   

                "4831" = "South Zone"
                "4832" = "Calgary Zone"
                "4833" = "Central Zone"
                "4834" = "Edmonton Zone"
                "4835" = "North Zone"
                "4899" = "AB - Unknown"   

                "5911" = "East Kootenay"
                "5912" = "Kootenay/Boundary"
                "5913" = "Okanagan"
                "5914" = "Thompson/Cariboo"
                "5921" = "Fraser East"
                "5922" = "Fraser North"
                "5923" = "Fraser South"
                "5931" = "Richmond"
                "5932" = "Vancouver"
                "5933" = "North Shore/Coast Garibaldi" 
                "5941" = "South Vancouver Island"
                "5942" = "Central Vancouver Island"
                "5943" = "North Vancouver Island"
                "5951" = "Northwest"
                "5952" = "Northern Interior"
                "5953" = "Northeast" 
                "5999" = "BC - Unknown" 

                "6001" = "Yukon Territory"
                "6099" = "YT - Unknown"

                "6101" = "Northwest Territories"
                "6199" = "Northwest Territories - Unknown"

                "6201" = "Nunavut"   
                "6299" = "Nunavut - Unknown"   ;
RUN;





%MACRO review;

PROC FORMAT;
   SELECT $REGION_CODE;
RUN;

%MEND review;

/*==========================================================================*/
/* FORMAT - DOB_YEAR
/*==========================================================================*/

PROC FORMAT;
     VALUE dob_year
    '01JAN1800'd - '31DEC1800'd = "1800 "
    '01JAN1801'd - '31DEC1889'd = "1801 - 1889"
    '01JAN1890'd - '31DEC1919'd = "1890 - 1919"
    '01JAN1920'd - '31DEC1959'd = "1920 - 1959"
    '01JAN1960'd - '31DEC1989'd = "1960 - 1999"
    '01JAN1990'd - '31DEC2006'd = "1990 - 2006"
    '01JAN2007'd - '31DEC2007'd = "2007"
    '01JAN2008'd - '31DEC2008'd = "2008"
    '01JAN2009'd - '31DEC2009'd = "2009"
    '01JAN2010'd - '31DEC2010'd = "2010"
    '01JAN2011'd - '31DEC2011'd = "2011"
    '01JAN2012'd - '31DEC2012'd = "2012"
    '01JAN2013'd - '31DEC2013'd = "2013"
    '01JAN2014'd - '31DEC2014'd = "2014"
    '01JAN2015'd - '31DEC2015'd = "2015"
    '01JAN9999'd - '31DEC9999'd = "9999"
	     ;
RUN; 


/*==========================================================================*/
/* FORMAT - FISCAL_YEAR
/*==========================================================================*/
PROC FORMAT;
     VALUE fiscal_year
    '01APR1980'd - '31MAR1990'd = "FY 80s "
    '01APR1990'd - '31MAR2000'd = "FY 90s "
    '01APR2000'd - '31MAR2001'd = "FY 2000"
    '01APR2001'd - '31MAR2002'd = "FY 2001"
    '01APR2002'd - '31MAR2003'd = "FY 2002"
    '01APR2003'd - '31MAR2004'd = "FY 2003"
    '01APR2004'd - '31MAR2005'd = "FY 2004"
    '01APR2005'd - '31MAR2006'd = "FY 2005"
    '01APR2006'd - '31MAR2007'd = "FY 2006"
    '01APR2007'd - '31MAR2008'd = "FY 2007"
    '01APR2008'd - '31MAR2009'd = "FY 2008"
    '01APR2009'd - '31MAR2010'd = "FY 2009"
    '01APR2010'd - '31MAR2011'd = "FY 2010"
    '01APR2011'd - '31MAR2012'd = "FY 2011"
    '01APR2012'd - '31MAR2013'd = "FY 2012"
    '01APR2013'd - '31MAR2014'd = "FY 2013"
    '01APR2014'd - '31MAR2015'd = "FY 2014"
    '01APR2015'd - '31MAR2016'd = "FY 2015"
	     ;
RUN; 




/*===========================================================================*/
/* FORMAT $POP_METHODOLOGY_RETURN
/*============================================================================*/

DATA pop_return_code;
   SET METHTAB.pop_methodology_return
       END = last;

  LENGTH start  $002.
         label  $080.;

  start = pop_return_code;

  label = pop_return_code || " - " || pop_return_code_e_desc;

  fmtname='$POP_RETURN_CODE';

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = pop_return_code;
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_RETURN_CODE;
RUN;

%MEND review;




/*===========================================================================*/
/* $POP_PHC_BASE_VISIT                                                 1 of 3
/*           
/* POP_PHC_BASE_KEY 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06                                 
/*    pop_age_group_code             07 to 08    
/*    gender_code                    09 to 09
/*
/* POP_PHC_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*    pop_age_group_code             07 to 08
/*    gender_code                    09 to 09
/*
/*    phc_base_prospective_coef      10 to 17
/*           
/*           
/*============================================================================*/


DATA pop_phc_base_visit;
   SET METHTAB.pop_phc_base_visit
       END = last;

fmtname='$POP_PHC_BASE_VISIT';


LENGTH start  $009.
       label  $017.;


  start = PUT (methodology_year, 004.0) || 
          pop_user_code ||
          pop_age_group_code ||
          gender_code;

  label = PUT (methodology_year, 004.0) || 
          pop_user_code ||
          pop_age_group_code ||
          gender_code ||

          PUT (phc_base_prospective_coef, 008.05);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_PHC_BASE_VISIT;
RUN;



%MACRO POP_PHC_BASE;

LENGTH pop_phc_base_key       $009. 
       pop_phc_base_lookup    $017.;

pop_phc_base_key = PUT (methodology_year, 004.0) || 
                        pop_user_code ||
                        pop_age_group_code ||
                        reg_gender_code;

pop_phc_base_lookup = PUT(pop_phc_base_key, $POP_PHC_BASE_VISIT.); 

%MEND POP_PHC_BASE;



%MACRO review;

PROC FORMAT;
   SELECT $POP_PHC_BASE_VISIT;
RUN;


PROC CONTENTS DATA = METHTAB.pop_phc_base_visit;
RUN;


PROC PRINT DATA = METHTAB.pop_phc_base_visit   NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_phc_base_visit";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   WHERE phc_base_prospective_coef < 0.00001;
   VAR pop_user_code
       pop_age_group_code
	   gender_code
	   phc_base_prospective_coef;
   FORMAT phc_base_prospective_coef 08.05;
RUN;

%MEND review;




/*===========================================================================*/
/* $POP_PHC_HC_VISIT                                                    2 of 3
/*           
/* POP_PHC_BASE_KEY 
/*    methodology_year               01 to 04
/*    health_condition_code          04 to 08
/*
/* POP_PHC_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    health_condition_code          04 to 08
/*
/*    phc_hc_prospective_coef        09 to 16
/*           
/*           
/*============================================================================*/

DATA pop_phc_hc_visit;
   SET METHTAB.pop_phc_hc_visit
       END = last;

fmtname = '$POP_PHC_HC_VISIT';


LENGTH start  $008.
       label  $016.;


  start = PUT (methodology_year, 004.0) || 
          health_condition_code;

  label = PUT (methodology_year, 004.0) || 
          health_condition_code  ||

          PUT (phc_hc_prospective_coef, 08.05);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_PHC_HC_VISIT;
RUN;


%MACRO POP_PHC_HC;

LENGTH pop_phc_hc_key       $008. 
       pop_phc_hc_lookup    $016.;

pop_phc_hc_key = PUT (methodology_year, 004.) || 
                      health_condition_code;

pop_phc_hc_lookup = PUT(pop_phc_hc_key, $POP_PHC_HC_VISIT.); 


%MEND POP_PHC_HC;



%MACRO review;

PROC FORMAT;
   SELECT $POP_PHC_HC_VISIT;
RUN;

PROC CONTENTS DATA = METHTAB.pop_phc_hc_visit;
RUN;

PROC PRINT DATA = METHTAB.pop_phc_hc_visit   NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_phc_hc_visit";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   WHERE health_condition_code IN("F42" "J08");
   VAR health_condition_code
       phc_hc_prospective_coef;
RUN;

%MEND review;




/*===========================================================================*/
/* $POP_PHC_INTERACT_VISIT                                             3 of 3
/*           
/* POP_PHC_BASE_KEY 
/*    methodology_year               01 to 04
/*    health_condition_1_code        04 to 08
/*    health_condition_2_code        09 to 12
/*
/* POP_PHC_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    health_condition_1_code        04 to 08
/*    health_condition_2_code        09 to 12
/*
/*    phc_interact_prospective_coef  13 to 21
/*           
/*           
/*============================================================================*/


DATA pop_phc_interact_visit;
   SET METHTAB.pop_phc_interact_visit
       END = last;

fmtname = '$POP_PHC_INTERACT_VISIT';


LENGTH start  $012.
       label  $020.;


  start = PUT (methodology_year, 004.) || 
          health_condition_1_code ||
          health_condition_2_code;

  label = PUT (methodology_year, 004.) || 
          health_condition_1_code ||
          health_condition_2_code ||

          PUT (phc_interact_prospective_coef, 08.05);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_PHC_INTERACT_VISIT;
RUN;



%MACRO POP_PHC_INTERACT;

LENGTH pop_phc_interact_key       $012. 
       pop_phc_interact_lookup    $020.;

pop_phc_interact_key = PUT (methodology_year, 004.) || 
                       health_condition_1_code ||
                       health_condition_2_code;


pop_phc_interact_lookup = PUT(pop_phc_interact_key, $POP_PHC_INTERACT_VISIT.); 


%MEND POP_PHC_INTERACT;




%MACRO review;


PROC FORMAT;
   SELECT $POP_PHC_INTERACT_VISIT;
RUN;

PROC CONTENTS DATA = METHTAB.pop_phc_interact_visit;
RUN;

PROC PRINT DATA = METHTAB.pop_phc_interact_visit   NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_phc_interact_visit";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   WHERE phc_inter_prospective_coef < -1;
      WHERE health_condition_1_code IN("F42" "J08");

   VAR health_condition_1_code
       health_condition_2_code
       phc_inter_prospective_coef;
RUN;


%MEND review;




/*===========================================================================*/
/* $POP_ED_BASE_VISIT                                                     1 of 2
/*           
/* POP_ED_BASE_KEY 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*    pop_age_group_code             07 to 08
/*    gender_code                    09 to 09
/*
/* POP_ED_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*    pop_age_group_code             07 to 08
/*    gender_code                    09 to 09
/*
/*    ed_base_concurrent_lin_coef    10 to 17
/*    ed_base_concurrent_exp_coef    18 to 25
/*           
/*    ed_base_prospective_lin_coef   26 to 33
/*    ed_base_prospective_exp_coef   34 to 41
/*           
/*============================================================================*/



DATA pop_ed_base_visit;
   SET METHTAB.pop_ed_base_visit
       END = last;

fmtname = '$POP_ED_BASE_VISIT';

LENGTH start  $009.
       label  $041.;



start = PUT (methodology_year, 004.0) || 
        pop_user_code ||
        pop_age_group_code ||
        gender_code;


label = PUT (methodology_year, 004.0) || 
        pop_user_code ||
        pop_age_group_code ||
        gender_code ||

        PUT (ed_base_concurrent_lin_coef,  08.05) ||
        PUT (ed_base_concurrent_exp_coef,  08.05) ||
        PUT (ed_base_prospective_lin_coef, 08.05) ||
        PUT (ed_base_prospective_exp_coef, 08.05);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_ED_BASE_VISIT;
RUN;



%MACRO review;


PROC FORMAT;
   SELECT $POP_ED_BASE_VISIT;
RUN;


PROC CONTENTS DATA = METHTAB.pop_ed_base_visit;
RUN;

PROC PRINT DATA = METHTAB.pop_ed_base_visit   NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ed_base_visit";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   VAR pop_user_code
       pop_age_group_code
       gender_code
	   ed_base_concurrent_lin_coef
	   ed_base_concurrent_exp_coef
	   ed_base_prospective_lin_coef
	   ed_base_prospective_exp_coef
       ;
RUN;

%MEND review;


%MACRO POP_ED_BASE;

LENGTH pop_ed_base_key       $009. 
       pop_ed_base_lookup    $041.;

pop_ed_base_key = PUT (methodology_year, 004.0) || 
                  pop_user_code ||
                  pop_age_group_code ||
                  reg_gender_code;

pop_ed_base_lookup = PUT(pop_ed_base_key, $POP_ED_BASE_VISIT.); 

%MEND POP_ED_BASE;




/*===========================================================================*/
/* $POP_ED_HC_VISIT                                                     2 of 2
/*           
/* POP_ED_BASE_KEY 
/*    methodology_year               01 to 04
/*    health_condition_code          04 to 08
/*
/* POP_ED_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    health_condition_code          04 to 08
/*
/*    ed_hc_concurrent_lin_coef      09 to 16
/*    ed_hc_concurrent_exp_coef      17 to 24
/*    ed_hc_prospective_lin_coef     25 to 32
/*    ed_hc_proepective_exp_coef     33 to 40
/*           
/*============================================================================*/



DATA pop_ed_hc_visit;
   SET METHTAB.pop_ed_hc_visit
       END = last;

fmtname = '$POP_ED_HC_VISIT';


LENGTH start  $008.
       label  $040.;


  start = PUT (methodology_year, 004.0) || 
          health_condition_code;

  label = PUT (methodology_year, 004.0) || 
          health_condition_code ||

          PUT (ed_hc_concurrent_lin_coef,  08.05) ||
          PUT (ed_hc_concurrent_exp_coef,  08.05) ||
          PUT (ed_hc_prospective_lin_coef, 08.05) ||
          PUT (ed_hc_prospective_exp_coef, 08.05);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_ED_HC_VISIT;
RUN;


%MACRO review;

PROC CONTENTS DATA = METHTAB.pop_ed_hc_visit;
RUN;

PROC PRINT DATA = METHTAB.pop_ed_hc_visit   NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ed_hc_visit";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   VAR health_condition_code
	   ed_hc_concurrent_lin_coef
	   ed_hc_concurrent_exp_coef
	   ed_hc_prospective_lin_coef
	   ed_hc_prospective_exp_coef
       ;
RUN;

PROC FORMAT;
   SELECT $POP_ED_HC_VISIT;
RUN;


%MEND review;



%MACRO POP_ED_HC;

LENGTH pop_ed_hc_key       $008. 
       pop_ed_hc_lookup    $040.;

pop_ed_hc_key = PUT (methodology_year, 004.) || 
                health_condition_code;

pop_ed_hc_lookup = PUT(pop_ed_hc_key, $POP_ED_HC_VISIT.); 


%MEND POP_ED_HC;


/*===========================================================================*/
/* $POP_LTC_BASE_PROBABILITY                                             1 of 4
/*           
/* POP_LTC_BASE_KEY 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*    pop_age_group_code             07 to 08
/*    gender_code                    09 to 09
/*
/* POP_LTC_BASE_LOOKUP 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*    pop_age_group_code             07 to 08
/*    gender_code                    09 to 09
/*
/*    ltc_base_prospective_exp_coef  10 to 20  11.05
/*           
/*           
/*============================================================================*/

DATA pop_ltc_base_probability;
   SET METHTAB.pop_ltc_base_probability
       END = last;

fmtname='$POP_LTC_BASE_PROBABILITY';


LENGTH start  $009.
       label  $020.;


start = PUT (methodology_year, 004.0) || 
        pop_user_code ||
        pop_age_group_code ||
        gender_code;

label = PUT (methodology_year, 004.0) || 
        pop_user_code ||
        pop_age_group_code ||
        gender_code ||

        PUT (ltc_base_prospective_exp_coef, 11.08);


OUTPUT;

IF last
THEN DO;
        hlo='O';
        label='  ';
        OUTPUT;
     END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_LTC_BASE_PROBABILITY;
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_LTC_BASE_PROBABILITY;
RUN;


PROC PRINT DATA = METHTAB.pop_ltc_base_probability    NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ltc_base_probability";
   BY methodology_year;
   TITLE5 "&METHTAB.";

   VAR pop_user_code
       pop_age_group_code
	   gender_code
       ltc_base_prospective_exp_coef;
  FORMAT   ltc_base_prospective_exp_coef 08.05;
RUN;

%MEND review;


%MACRO POP_LTC_BASE_PROBABILITY;

LENGTH pop_ltc_base_prob_key       $009. 
       pop_ltc_base_prob_lookup    $020.;

pop_ltc_base_prob_key = PUT (methodology_year, 004.0) || 
                        pop_user_code ||
                        pop_age_group_code ||
                        reg_gender_code;

pop_ltc_base_prob_lookup = PUT(pop_ltc_base_prob_key, $POP_LTC_BASE_PROBABILITY.); 

%MEND POP_LTC_BASE_PROBABILITY;






/*===========================================================================*/
/* $POP_LTC_HC_PROBABILITY                                             2 of 4   
/*           
/* POP_LTC_HC_KEY 
/*    methodology_year               01 to 04
/*    health_condition_code          05 to 08
/*
/* POP_LTC_HC_LOOKUP 
/*    methodology_year               01 to 04
/*    health_condition_code          05 to 08
/*
/*    ltc_hc_prospective_exp_coef    09 to 19
/*           
/*           
/*============================================================================*/


DATA pop_ltc_hc_probability;
   SET METHTAB.pop_ltc_hc_probability
       END = last;

fmtname='$POP_LTC_HC_PROBABILITY';


LENGTH start  $009.
       label  $019.;


  start = PUT (methodology_year, 004.0) || 
          health_condition_code;

  label = PUT (methodology_year, 004.0) || 
          health_condition_code  ||

          PUT (ltc_hc_prospective_exp_coef, 11.08);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_LTC_HC_PROBABILITY;
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_LTC_HC_PROBABILITY;
RUN;

PROC CONTENTS DATA =  METHTAB.pop_ltc_hc_probability ;
RUN;


PROC PRINT DATA = METHTAB.pop_ltc_hc_probability    NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ltc_hc_probability";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   VAR health_condition_code
       ltc_hc_prospective_exp_coef;
RUN;

%MEND review;



%MACRO POP_LTC_HC_PROBABILITY;


LENGTH pop_ltc_hc_prob_key       $008. 
       pop_ltc_hc_prob_lookup    $019.;

pop_ltc_hc_prob_key = PUT (methodology_year, 004.) || 
                      health_condition_code;

pop_ltc_hc_prob_lookup = PUT(pop_ltc_hc_prob_key, $POP_LTC_HC_PROBABILITY.); 


%MEND POP_LTC_HC_PROBABILITY;



/*===========================================================================*/
/* $POP_LTC_HC_USER_PROBABILITY                                        3 of 4    
/*           
/* POP_LTC_HC_KEY 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*
/* POP_LTC_HC_LOOKUP 
/*    methodology_year               01 to 04
/*    pop_user_code                  05 to 06
/*
/*    ltc_hc_user_prosp_exp_coef     07 to 17
/*           
/*            
/*============================================================================*/


DATA pop_ltc_hc_user_probability;
   SET METHTAB.pop_ltc_hc_user_probability
       END = last;

fmtname = '$POP_LTC_HC_USER_PROBABILITY';


LENGTH start  $006.
       label  $017.;


  start = PUT (methodology_year, 004.0) || 
          pop_user_code;

  label = PUT (methodology_year, 004.0) || 
          pop_user_code  ||

          PUT (ltc_hc_user_prosp_exp_coef, 11.08);

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_LTC_HC_USER_PROBABILITY;
RUN;


%MACRO review;


PROC FORMAT;
   SELECT $POP_LTC_HC_USER_PROBABILITY;
RUN;

PROC CONTENTS DATA = METHTAB.pop_ltc_hc_user_probability;
RUN;

PROC PRINT DATA = METHTAB.pop_ltc_hc_user_probability    NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ltc_hc_user_probability";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   VAR pop_user_code
       ltc_hc_user_prosp_exp_coef;
RUN;


%MEND review;



%MACRO POP_LTC_HC_USER_PROBABILITY;

LENGTH pop_ltc_hc_user_prob_key       $006. 
       pop_ltc_hc_user_prob_lookup    $017.;

pop_ltc_hc_user_prob_key = PUT (methodology_year, 004.) || 
                           pop_user_code;

pop_ltc_hc_user_prob_lookup = PUT(pop_ltc_hc_user_prob_key, $POP_LTC_HC_USER_PROBABILITY.); 


%MEND POP_LTC_HC_USER_PROBABILITY;



/*===========================================================================*/
/* $POP_LTC_INTERACT_PROBABILITY                                        4 of 4
/*           
/* POP_LTC_INTERACT_KEY 
/*    methodology_year               01 to 04
/*    health_condition_1_code        05 to 08
/*    health_condition_2_code        09 to 12
/*
/* POP_LTC_INTERACT_LOOKUP 
/*    methodology_year               01 to 04
/*    health_condition_1_code        05 to 08
/*    health_condition_2_code        09 to 12
/*
/*    ltc_inter_prospective_exp_coef 13 to 23
/*
/*============================================================================*/

DATA           pop_ltc_interact_probability;
   SET METHTAB.pop_ltc_interact_probability
       END = last;

fmtname = '$POP_LTC_INTERACT_PROBABILITY';


LENGTH start  $012.
       label  $020.;

start = PUT (methodology_year, 004.0) ||
        health_condition_1_code ||
        health_condition_2_code;

label = PUT (methodology_year, 004.0) || 
        health_condition_1_code ||
        health_condition_2_code ||

        PUT (ltc_inter_prospective_exp_coef, 11.08);

OUTPUT;

IF last
THEN DO;
        hlo='O';
        label='  ';
        OUTPUT;
     END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_LTC_INTERACT_PROBABILITY;
RUN;




%MACRO POP_LTC_INTERACT_PROBABILITY;

LENGTH pop_ltc_interact_key       $012. 
       pop_ltc_interact_lookup    $023.;

pop_ltc_interact_key = PUT (methodology_year, 004.) || 
                       health_condition_1_code ||
                       health_condition_2_code;

pop_ltc_interact_lookup = PUT(pop_ltc_interact_key, $POP_LTC_INTERACT_PROBABILITY.); 


%MEND POP_LTC_INTERACT_PROBABILITY;



%MACRO review;

PROC FORMAT;
   SELECT $POP_LTC_INTERACT_PROBABILITY;
RUN;


PROC CONTENTS DATA = METHTAB.pop_ltc_interact_probability;
RUN;

PROC PRINT DATA = METHTAB.pop_ltc_interact_probability    NOOBS UNIFORM;
   TITLE3        "METHTAB.pop_ltc_interact_probability";
   BY methodology_year;
   TITLE5 "&METHTAB.";
   VAR health_condition_1_code
       health_condition_2_code
	   ltc_inter_prospective_exp_coef;
RUN;


%MEND review;






/*===========================================================================*/
/* POP_AGE_GROUP_CODE format
/*============================================================================*/

DATA pop_age_group_code;
   SET METHTAB.pop_age_group
       END = last;

  LENGTH start  $002.
         label  $060.;

  start = pop_age_group_code;

  label = pop_age_group_code || " - " || pop_age_group_e_desc;

  fmtname = '$POP_AGE_GROUP_CODE';

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_AGE_GROUP_CODE;
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_AGE_GROUP_CODE;
RUN;

%MEND review;


                                                                             /* ====================================== */
                                                                             /* MACRO DEFINE_AGE (added for 1.0)       */
                                                                             /* ====================================== */
%MACRO define_age (dob, date, age);

&AGE = FLOOR(INTCK("MONTH", &DOB, &DATE) / 12);

IF MONTH(&DOB) = MONTH(&DATE) 
THEN &AGE = &AGE  - ( DAY(&DOB) > DAY(&DATE) );

%MEND define_age;


                                       /* ====================================== */
                                       /* CREATE_METHODOLOGY_TABLE_FORMATS       */
                                       /* ====================================== */

%MACRO CREATE_METHODOLOGY_TABLE_FORMATS;


 %LET PART2 = %STR( OUTPUT;
                    IF LAST THEN DO;
                        HLO = "O";
                        LABEL = " ";
                        OUTPUT; 
                    END;
                    KEEP start LABEL HLO FMTNAME  )  ;



                                                               /* POP_AGE_GROUP_ASSIGN */

DATA pop_age_group_assign;
  SET METHTAB.pop_age_group_assign 
      END = last;

  LENGTH start $7. 
         label $002.;

  start = PUT(methodology_year, 004.) || PUT(pop_age_num, Z3.);

  LABEL = pop_age_group_code;

  RETAIN FMTNAME "$POP_AGE_GROUP_ASSIGN";

  &PART2 ;

RUN;

PROC FORMAT CNTLIN = POP_AGE_GROUP_ASSIGN  
            LIBRARY = WORK ; 
RUN;



                                                               /* =================================== */
                                                               /* POP_DATA_SOURCE_CLASSIFICATION      */
                                                               /* =================================== */
DATA pop_data_source_classification;
	SET METHTAB.pop_data_source_classification 
        END = last;

	LENGTH start $009.  
           label $00001. ;

	start = pop_data_source_code || diag_classification_code;
	LABEL = "Y";

	RETAIN FMTNAME "$POP_DATA_SOURCE_CLASSIFICATION";

	&PART2;
RUN;

PROC FORMAT CNTLIN  = POP_DATA_SOURCE_CLASSIFICATION
            LIBRARY = WORK ;  
RUN;


                                                               /* =================================== */
                                                               /* POP_DATA_SOURCE_CODE   ****        */
                                                               /* =================================== */
PROC SORT DATA = METHTAB.pop_data_source_classification
          OUT  = pop_data_source_code;
   BY pop_data_source_code;
RUN;

DATA pop_data_source_code;
   SET pop_data_source_code
       END = last;

   BY pop_data_source_code;

IF FIRST.pop_data_source_code;

	LENGTH start $008.  
           label $00001. ;

	start = pop_data_source_code;

	LABEL = "Y";

	RETAIN FMTNAME "$POP_DATA_SOURCE_CODE";

	&PART2;
RUN;

PROC FORMAT CNTLIN  = POP_DATA_SOURCE_CODE
            LIBRARY = WORK ;  
RUN;

%MACRO review;

PROC FORMAT; 
   SELECT $POP_DATA_SOURCE_CODE;
RUN;

%MEND review;



                                                               /* =================================== */
                                                               /* POP_HC_INTERACTION_RIW              */
                                                               /* =================================== */
 DATA pop_hc_interaction_riw ;
  SET METHTAB.pop_hc_interaction_riw   
      END = last;

  LENGTH start $12. 
         label $0020. ;

  start = PUT(methodology_year, 004.) || health_condition_code_1 || health_condition_code_2 ;

  LABEL = PUT(hc_concur_interaction_factor, Z10.5) || PUT(hc_prosp_interaction_factor, Z10.5);

  RETAIN FMTNAME "$POP_HC_INTERACTION_RIW";
  &PART2 ;

 RUN;

PROC FORMAT CNTLIN  = POP_HC_INTERACTION_RIW  
            LIBRARY = WORK ;  
RUN;

                                                               /* =================================== */
                                                               /* POP_HEALTH_CONDITION                */
                                                               /* =================================== */

DATA pop_health_condition;
    SET METHTAB.pop_health_condition
	    END = last;

LENGTH start $004.
       label $00080.;  

start = health_condition_code  ;         

LABEL = health_condition_code || " - " || health_condition_long_e_desc;

RETAIN FMTNAME "$POP_HEALTH_CONDITION";

OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
     END;

KEEP start LABEL HLO FMTNAME;

RUN;

PROC FORMAT CNTLIN = POP_HEALTH_CONDITION
            LIBRARY = WORK ;  
RUN; 

                                                               /* =================================== */
                                                               /* POP_HEALTH_CONDITION_SEQ_ID         */
                                                               /* =================================== */

DATA pop_health_condition_seq_id;
    SET METHTAB.pop_health_condition
	    END = last;
    WHERE health_condition_code NE "ZZZZ";

  LENGTH start $04. 
         label $0003.;  

  start = health_condition_code ;
 
  LABEL = PUT(hc_seq_id, Z003.);

  RETAIN FMTNAME "$POP_HEALTH_CONDITION_SEQ_ID";

OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
     END;

KEEP start LABEL HLO FMTNAME;

RUN;

PROC FORMAT CNTLIN  = POP_HEALTH_CONDITION_SEQ_ID
            LIBRARY = WORK ;  
RUN; 

%MACRO review;


PROC FORMAT;
   SELECT $POP_HEALTH_CONDITION_SEQ_ID;
RUN;

%MEND review;

                                                               /* =================================== */
                                                               /* POP_HEALTH_CONDITION_ASSIGN         */
                                                               /* =================================== */
DATA pop_health_condition_assign;
    SET METHTAB.pop_health_condition_assign
	    END = last;
  LENGTH start $12. label $008.;  

  start = PUT(methodology_year, 004.) || diag_classification_code || diag_code ; 
 
  LABEL = health_condition_code || PUT(hc_seq_id, Z003.) || plpb_tag_rule;

  RETAIN FMTNAME "$POP_HEALTH_CONDITION_ASSIGN";

  &PART2 ;

RUN;

PROC FORMAT CNTLIN  = POP_HEALTH_CONDITION_ASSIGN
            LIBRARY = WORK ;  
RUN; 

%MACRO review;

PROC FORMAT;
    SELECT $POP_HEALTH_CONDITION_ASSIGN;
RUN; 

%MEND review;



                                                               /* =================================== */
                                                               /* POP_HEALTH_CONDITION_OVERRIDE       */
                                                               /* =================================== */
DATA pop_health_condition_override;
    SET METHTAB.pop_health_condition_override
        END = last;

    LENGTH start $8. 
           label $001.;

    start = health_condition_code || hc_override_code;

    LABEL = "Y";

    RETAIN FMTNAME "$POP_HEALTH_CONDITION_OVERRIDE";

    OUTPUT;
    IF LAST THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
    END;
    KEEP start LABEL HLO FMTNAME ;
RUN;

PROC FORMAT CNTLIN = POP_HEALTH_CONDITION_OVERRIDE
            LIBRARY = WORK ;  
RUN;




                                                               /* =================================== */
                                                               /* POP_HEALTH_CONDITION_RIW            */
                                                               /* =================================== */
DATA pop_health_condition_riw ;
  SET METHTAB.pop_health_condition_riw   
      END = last;

  LENGTH start $8. label $0020. ;

  start = PUT(methodology_year, Z004.) || health_condition_code ;

  LABEL = PUT(hc_prospective_factor, Z10.5) || PUT(hc_concurrent_factor, Z10.5);

  RETAIN FMTNAME "$POP_HEALTH_CONDITION_RIW";

  &PART2 ;

 RUN;

PROC FORMAT CNTLIN = POP_HEALTH_CONDITION_RIW
            LIBRARY = WORK ; 
RUN;



                                                               /* =================================== */
                                                               /* POP_ICD9_VALIDATION                 */
                                                               /* =================================== */

DATA pop_icd9_validation;
	SET METHTAB.pop_icd9_validation
        END = last;
	LENGTH start $12. 
           label $007.;

	start = PUT(methodology_year, Z004.) || diag_classification_code || diag_code;

	LABEL = gender_validation_code || PUT(age_min, Z003.) || PUT(age_max, Z003.);

	RETAIN FMTNAME "$POP_ICD9_VALIDATION";
	&PART2;
RUN;

PROC FORMAT CNTLIN = POP_ICD9_VALIDATION
			LIBRARY = WORK;
RUN;



                                                               /* =================================== */
                                                               /* POP_NO_HC_RIW                       */
                                                               /* =================================== */
 DATA pop_no_hc_riw;
  SET METHTAB.pop_no_hc_riw   
      END = last;

  LENGTH start $9. 
         label $0020. ;

  start = PUT(methodology_year, 004.) || pop_user_code || pop_age_group_code || gender_code;

  LABEL = PUT(NO_HC_PROSPECTIVE_RIW, Z10.5) || PUT(NO_HC_CONCURRENT_RIW, Z10.5);

  RETAIN FMTNAME "$POP_NO_HC_RIW";

  &PART2 ;

 RUN;

PROC FORMAT CNTLIN = POP_NO_HC_RIW  
            LIBRARY = WORK ;  
RUN;
 

                                                               /* =================================== */
                                                               /* PROVINCE_DIAG_TO_ICD9_LOOKUP        */
                                                               /* =================================== */

DATA PROVINCE_DIAG_TO_ICD;
	SET METHTAB.PROVINCE_DIAG_TO_ICD9 
        END = last;

	LENGTH start $13. 
           label $008.;

	start = PUT(methodology_year, Z004.) || province_code || diag_orig_code;

	LABEL = diag_classification_code || diag_code;

	RETAIN FMTNAME "$PROVINCE_DIAG_TO_ICD";

	&PART2;
RUN;

PROC FORMAT CNTLIN = PROVINCE_DIAG_TO_ICD
			LIBRARY = WORK;
RUN;




                                                     /* =================================== */
                                                     /* POP_PCCF                            */
                                                     /* ==> Region Code added for 1.0       */
                                                     /* =================================== */

%MACRO review_pop_pccf;

PROC FREQ DATA = METHTAB.pop_pccf;
   TITLE3       "METHTAB.pop_pccf";
   TABLES region_code
          qaippe06 * qaippe11 
          /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA008.;
RUN;

%MEND review_pop_pccf;

DATA pop_pccf;
    SET METHTAB.pop_pccf
	         (RENAME = (da11uid  = da11uid_char
                        da06uid  = da06uid_char
                        qaippe11 = qaippe11_char
                        qaippe06 = qaippe06_char))
        END = last;

LENGTH start $010. 
       label $026.;


start = PUT (methodology_year, Z004.) ||
        postal_code;

                                  	/* ============================== */
                                  	/* Make these fields NUMERIC      */
                                  	/* ============================== */
da11uid  = da11uid_char  * 1.0;
da06uid  = da06uid_char  * 1.0;
qaippe11 = qaippe11_char * 1.0;
qaippe06 = qaippe06_char * 1.0; 
	
LABEL = PUT(da11uid, 008.) || 
        PUT(da06uid, 008.) || 
        PUT(qaippe11, 003.) || 
        PUT(qaippe06, 003.) || 
        region_code;                 /* 023 - 026 - REGION_CODE */


RETAIN FMTNAME "$POP_PCCF";


OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
    END;

KEEP start
     LABEL
     HLO 
     FMTNAME ;

RUN;

PROC FORMAT CNTLIN = POP_PCCF  
            LIBRARY = WORK ;  
RUN;


%MACRO review_format;

PROC FORMAT;
   SELECT $POP_PCCF;
RUN; 

%MEND review_format;


%MEND CREATE_METHODOLOGY_TABLE_FORMATS;


%CREATE_METHODOLOGY_TABLE_FORMATS;



                                                               /* =================================== */
                                                               /* CAN_MARG_DA                         */
                                                               /* =================================== */
%MACRO review_can_marg;

PROC CONTENTS DATA = METHTAB.pop_can_marg_da_2006;
RUN;



PROC FREQ DATA = METHTAB.can_marg_da_2006;
  TITLE3        "METHTAB.can_marg_da_2006 ";
  TABLES dependency_da06  * dependency_q_da06
         deprivation_da06 * deprivation_q_da06
         ethniccon_da06   * ethniccon_q_da06 
         instability_da06 * instability_q_da06 
         /MISSING NOROW NOCOL NOPERCENT FORMAT = COMMA009.;
  FORMAT dependency_da06 
         deprivation_da06
         ethniccon_da06
         instability_da06   3.1;
RUN;

PROC PRINT DATA = METHTAB.can_marg_da_2006 NOOBS;
  TITLE3         "METHTAB.can_marg_da_2006 ";
  WHERE instability_q_da06 = ".";
  VAR dauid
	  dapop_2006 

      dependency_q_da06
      deprivation_q_da06
      ethniccon_q_da06
      instability_q_da06

	  dependency_da06
	  deprivation_da06
	  ethniccon_da06
	  instability_da06
	  ;
RUN;

%MEND review_can_marg;


DATA can_marg_da;
    SET METHTAB.pop_can_marg_da_2006
        END = last;

RETAIN FMTNAME "$CAN_MARG_DA";

LENGTH start $012. 
       label $004.;


start = PUT (methodology_year, Z004.) ||
        dauid;


LABEL = dependency_q_da06  ||      /* 001 to 001 */
        deprivation_q_da06 ||      /* 002 to 002 */
        ethniccon_q_da06   ||      /* 003 to 003 */
        instability_q_da06;        /* 004 to 004 */

OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
END;

KEEP start LABEL HLO FMTNAME ;

RUN;

PROC FORMAT CNTLIN = CAN_MARG_DA  
            LIBRARY = WORK ;  
RUN;

%MACRO review;

PROC FORMAT;
     SELECT $CAN_MARG_DA;
RUN;

%MEND review;



                                                               /* =================================== */
                                                               /* INSPQ_EQUIVALENT_2011               */
                                                               /* =================================== */

%MACRO review_inspq_equivalent_2011;

PROC CONTENTS DATA = METHTAB.pop_inspq_equivalent_2011;
RUN;


%MEND review_inspq_equivalent_2011;


DATA inspq_equivalent;
    SET METHTAB.pop_inspq_equivalent_2011 
        END = last;

RETAIN FMTNAME "$INSPQ_EQUIVALENT";

LENGTH start $012. 
       label $029.;
   

start = PUT (methodology_year, Z004.) ||
        dauid;


LABEL = quintmat       ||        /* 001 to 001 */
        quintsoc       ||        /* 002 to 002 */
        quintmatcr     ||        /* 003 to 003 */
        quintsoccr     ||        /* 004 to 004 */
        quintmatzone   ||        /* 005 to 005 */
        quintsoczone   ||        /* 006 to 006 */
        quintmatcma    ||        /* 007 to 007 */
        quintsoccma    ||        /* 008 to 008 */
        region         ||        /* 009 to 028 */
        zone  ;                  /* 029 to 029 */

OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
     END;

KEEP start LABEL HLO FMTNAME ;

RUN;

PROC FORMAT CNTLIN = INSPQ_EQUIVALENT  
            LIBRARY = WORK ;  
RUN;

%MACRO review;

PROC FORMAT;
     SELECT $INSPQ_EQUIVALENT;
RUN;

%MEND review;



/* ============================================================================== */
/*  MACROS used to "call tables"                                                  */
/* ============================================================================== */


%MACRO POP_AGE_GROUP_ASSIGN;

  LENGTH pop_age_group_assign_key    $7. 
         pop_age_group_assign_lookup $2.;

  pop_age_group_assign_key    = PUT(methodology_year, 004.) || PUT(pop_age_num, Z003.);
  pop_age_group_assign_lookup = PUT(pop_age_group_assign_key, $POP_AGE_GROUP_ASSIGN.); 

%MEND POP_AGE_GROUP_ASSIGN;



%MACRO POP_NO_HC_RIW ;

  LENGTH pop_no_hc_riw_key $9. 
         pop_no_hc_riw_lookup $20.;

  pop_no_hc_riw_key    = PUT(methodology_year, 004.) || pop_user_code || pop_age_group_code || reg_gender_code;
  pop_no_hc_riw_lookup = PUT(pop_no_hc_riw_key, $POP_NO_HC_RIW.);   

%MEND POP_NO_HC_RIW ;


%MACRO pop_hc_interaction_riw;

  LENGTH pop_hc_interaction_riw_key    $12. 
         pop_hc_interaction_riw_lookup $20.;

  pop_hc_interaction_riw_key    = PUT(methodology_year, 004.) || health_condition_code_1 || health_condition_code_2 ;
  pop_hc_interaction_riw_lookup = PUT(pop_hc_interaction_riw_KEY, $pop_hc_interaction_riw.);   

%MEND pop_hc_interaction_riw;



%MACRO POP_HEALTH_CONDITION_ASSIGN;

  LENGTH pop_health_cond_assign_key    $12. 
         pop_health_cond_assign_lookup $8.;

  pop_health_cond_assign_key    = PUT(methodology_year, 004.) || diag_classification_code || diag_code;
  pop_health_cond_assign_lookup = PUT(pop_health_cond_assign_key, $POP_HEALTH_CONDITION_ASSIGN.); 


%MEND POP_HEALTH_CONDITION_ASSIGN;



%MACRO POP_HEALTH_CONDITION_RIW;

  LENGTH pop_hc_riw_key    $8.
         pop_hc_riw_lookup $20.;

  pop_hc_riw_key    = PUT(methodology_year, 004.) 
                      || health_condition_code ;
  pop_hc_riw_lookup = PUT(pop_hc_riw_key, $POP_HEALTH_CONDITION_RIW.);  

%MEND POP_HEALTH_CONDITION_RIW;



%MACRO POP_HEALTH_CONDITION_OVERRIDE;

  LENGTH pop_hc_override_key    $008. 
         pop_hc_override_lookup $001.;

  pop_hc_override_key    = health_condition_code_1 || health_condition_code_2;
  pop_hc_override_lookup = PUT(pop_hc_override_key, $POP_HEALTH_CONDITION_OVERRIDE.); 

%MEND POP_HEALTH_CONDITION_OVERRIDE;



%MACRO POP_PCCF;

    LENGTH pop_pccf_key    $010. 
           pop_pccf_lookup $026.;

    pop_pccf_key = PUT(methodology_year, 004.) ||
                   reg_postal_code;

    pop_pccf_lookup = PUT(pop_pccf_key, $POP_PCCF.);

%MEND POP_PCCF;



%MACRO CAN_MARG_DA;

	LENGTH can_marg_da_2006_key    $012. 
           can_marg_da_2006_lookup $004.;
	
	can_marg_da_2006_key = PUT(methodology_year, 004.) ||
                           da06uid;

	can_marg_da_2006_lookup = PUT(can_marg_da_2006_key, $CAN_MARG_DA.); 

%MEND CAN_MARG_DA;


%MACRO INSPQ_EQUIVALENT;

    LENGTH inspq_equivalent_key    $012. 
           INSPQ_EQUIVALENT_LOOKUP $029.;

    inspq_equivalent_key = PUT(methodology_year, 004.) ||
                           da11uid;

    inspq_equivalent_lookup = PUT(inspq_equivalent_key, $INSPQ_EQUIVALENT.);


%MEND INSPQ_EQUIVALENT;



/*===========================================================================*/
/* $POP_HPG format
/*           
/*  ==> Do NOT use Methodolgy Year as part of the key!!!!           
/*           
/* POP_HPG_KEY 
/*    hpg_code                       01 to 05
/*           
/* POP_HPG_LOOKUP 
/*           
/*    hpg_desc                       01 to 80
/*           
/*           
/*============================================================================*/

DATA pop_hpg;
   SET METHTAB.pop_hpg
       END = last;

  LENGTH start  $005.
         label  $100.;


  start = hpg_code;

  label = hpg_code || " - " || hpg_e_desc;

  fmtname='$POP_HPG';

  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start hlo label fmtname;

RUN;

PROC FORMAT cntlin = POP_HPG;
RUN;

%MACRO review;

PROC FORMAT;
   SELECT $POP_HPG;
RUN;

%MEND review;


/*===========================================================================*/
/* $POP_HPG_BRANCH_ASSIGN 
/*
/* POP_HPG_BRANCH_KEY 
/*    METHODOLOGY_YEAR        01 - 04  2016
/*    HEALTH_CONDITION_CODE   05 - 08  POP Health Condition code
/*
/*
/* POP_HPG_BRANCH_LOOKUP 
/*    METHODOLOGY_YEAR        01 - 04  2016
/*    HEALTH_CONDITION_CODE   05 - 08  POP Health Condition code
/*
/*    BRANCH_ID               09 - 11  Branch ID for the "combo"
/*    BRANCH_COMBO_FLAG       12 - 12  Y - This branch COULD be part of a COMBO
/*                                     N - Otherwise
/*
/*============================================================================*/


DATA           pop_hpg_branch_assign;
   SET METHTAB.pop_hpg_branch_assign
       END = last;

  fmtname = '$POP_HPG_BRANCH_ASSIGN';

  LENGTH start  $008.
         label  $012.;

  start = PUT (methodology_year, 004.0) || 
          health_condition_code;

  label = PUT (methodology_year, 004.0) || 
          health_condition_code ||

		  PUT (branch_ID, Z003.) ||              /* 009 - 011 */
		  branch_combo_flag;


  OUTPUT;

  IF last
  THEN DO;
          hlo='O';
          label='  ';
          OUTPUT;
       END;

KEEP start 
     hlo 
     label 
     fmtname; 

RUN;

PROC FORMAT cntlin = POP_HPG_BRANCH_ASSIGN;
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_HPG_BRANCH_ASSIGN;
RUN;

%MEND review;



/*===========================================================================*/
/* $POP_HPG_COMBO_ASSIGN
/*
/* Assumed: BRANCH_1_ID < BRANCH_2_ID
/*
/* POP_HPG_COMBO_ID_KEY 
/*    METHODOLOGY_YEAR        01 - 04  2016
/*    BRANCH_1_ID             05 - 07  Lowest ID (for the pair)
/*    BRANCH_2_ID             08 - 10  Highest ID (for the pair)
/*
/*
/* POP_HPG_COMBO_ID_LOOKUP 
/*    METHODOLOGY_YEAR        01 - 04  2016
/*    BRANCH_1_ID             05 - 07  Lowest ID (for the pair)
/*    BRANCH_2_ID             08 - 10  Highest ID (for the pair)
/*
/*    BRANCH_COMBO_ID         11 - 13  Branch ID for the "combo"
/*
/*============================================================================*/


DATA          pop_hpg_combo_assign;
  SET METHTAB.pop_hpg_combo_assign   
      END = last;

RETAIN FMTNAME "$POP_HPG_COMBO_ASSIGN";

LENGTH start $010. 
       label $013. ;

start = PUT(methodology_year, 004.) || 
        PUT (branch_1_ID, 003.)    || 
        PUT (branch_2_ID, 003.);

label = PUT (methodology_year, 004.) || 
        PUT (branch_1_ID, 3.) ||
        PUT (branch_2_ID, 3.) ||
 
        PUT (branch_combo_ID, 3.);

OUTPUT;

IF last
THEN DO;
        hlo='O';
        label='  ';
        OUTPUT;
     END;

KEEP start 
     hlo 
     label 
     fmtname; 

RUN;


PROC FORMAT CNTLIN  = pop_hpg_combo_assign
            LIBRARY = WORK ;  
RUN;


%MACRO review;

PROC FORMAT;
   SELECT $POP_HPG_COMBO_ASSIGN;
RUN;

%MEND review;


/*===========================================================================*/
/* $POP_HPG_BRANCH
/*
/* POP_HPG_BRANCH_KEY 
/*    METHODOLOGY_YEAR           01 - 04  2016
/*    BRANCH_ID                  05 - 07 
/*           
/* POP_HPG_BRANCH_LOOKUP 
/*    METHODOLOGY_YEAR           01 - 04  2016
/*    BRANCH_ID                  05 - 07 
/*           
/*           
/*    BRANCH_RANK                08 - 10 
/*
/*    COMORBIDITY_CATEGORY_CODE  11 - 12  C1 - Major
/*                                        C2 - Moderate
/*                                        C3 – Minor
/*
/*    HPG_SPLIT_CODE             13 - 14  00 - This branch is NOT split 
/*                                        01 - This branch has a split
/*    BRANCH_CODE                15 - 18 
/*
/*    BRANCH_E_DESC              19 - 98 
/*
/*
/*============================================================================*/

DATA           pop_hpg_branch;
    SET METHTAB.pop_hpg_branch
	    END = last;

RETAIN FMTNAME "$POP_HPG_BRANCH";

LENGTH start  $007.
       label  $098.;

  start = PUT (methodology_year, 004.0) || 
          PUT (branch_ID, Z003.);

  label = PUT (methodology_year, 004.0) || 
          PUT (branch_ID, Z003.)       ||

		  PUT (branch_rank, 003.)      || 
		  comorbidity_category_code    ||
		  hpg_split_code               ||

		  branch_code                  ||
		  branch_e_desc;
  

OUTPUT;

IF LAST 
THEN DO;
        HLO = "O";
        LABEL = " ";
        OUTPUT; 
     END;

KEEP start 
     LABEL HLO FMTNAME;

RUN;

PROC FORMAT CNTLIN  = POP_HPG_BRANCH
            LIBRARY = WORK ;  
RUN; 


%MACRO review;

PROC FORMAT;
   SELECT $POP_HPG_BRANCH;
RUN;

%MEND review;




/*===========================================================================*/
/* $POP_HPG_LOGIC  
/*
/* POP_HPG_ID_LOGIC_KEY 
/*     METHODOLOGY_YEAR       01 - 04  2016
/*     HIGH_BRANCH_ID         05 - 07  1 to number of MEG branches 
/*     HPG_SPLIT_CODE         08 - 09  00 - This branch is NOT split 
/*                                     01 - This branch has a split
/*
/* POP_HPG_ID_LOGIC_LOOKUP 
/*     METHODOLTY_YEAR        01 - 04  2016
/*     HIGH_BRANCH_ID         05 - 07  1 to number of MEG branches 
/*     HPG_SPLIT_CODE         08 - 09  00 - This branch is NOT split 
/*                                     01 - This branch has a split
/*     HPG_CATEGORY_CODE      10 - 11 
/*     HPG_CODE               12 - 16  
/*     HPG_CONCURRENT_RIW     17 - 25  Concurrent RIW
/*     HPG_PROSPECTIVE_RIW    26 - 34  Prospective RIW
/*
/*===========================================================================*/

DATA          pop_hpg_logic;
  SET METHTAB.pop_hpg_logic   
      END = last;

  LENGTH start $009. 
         label $034. ;

  RETAIN FMTNAME "$POP_HPG_LOGIC";

start = PUT(methodology_year, 004.) || 
        PUT (branch_ID,  003.) ||
        hpg_split_code ;

label = PUT (methodology_year, 004.) || 
        PUT (branch_ID, 003.) ||
        hpg_split_code  ||

        hpg_category_code ||
        hpg_code ||
		PUT (hpg_concurrent_riw , 09.04) ||
		PUT (hpg_prospective_riw, 09.04);                     /* TESTING - Dollar values */

OUTPUT;

IF last
THEN DO;
        hlo='O';
        label='  ';
        OUTPUT;
     END;

KEEP start 
     hlo 
     label 
     fmtname; 

RUN;

PROC FORMAT CNTLIN  = pop_hpg_logic
            LIBRARY = WORK ;  
RUN;

%MACRO review;

PROC FORMAT;
   SELECT $POP_HPG_LOGIC;
RUN;

%MEND review;





                                                                              /* ================================= */
                                                                              /* Start / End time stamps           */
                                                                              /* ================================= */
DATA _NULL_;
   SET _meth_tab_stats_;

FILE print;

  FORMAT meth_tab_finish DATETIME020.;

  meth_tab_finish = DATETIME();

PUT // @ 010 "     SAS code     : &pop_10_methtab_sas_code. "
    // @ 010 "     Version date : &pop_10_methtab_version_date."
   /// @ 010 "Methodology Tables  &METHTAB."
       ;
       ;

PUT /// @ 010 " Finished setting up Methodology Tables and FORMATS"
     // @ 010 "                                        METH_TAB_START  : " meth_tab_start
     // @ 010 "                                        METH_TAB_FINISH : " meth_tab_finish
       ;

RUN;



/*===========================================*/
/* End of program marker                     */
/*===========================================*/
