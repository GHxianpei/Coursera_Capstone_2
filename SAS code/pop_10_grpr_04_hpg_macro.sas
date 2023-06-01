
%LET pop_10_grpr_04_sas_code     = pop_10_grpr_04_hpg_macro.sas;
%LET pop_10_grpr_04_version_date = 15DEC2016;


/*=========================================================================================*/
/* CIHI POP SAS GROUPER  Version 1.0                                                       */
/*=========================================================================================*/
/*  Assign the Health Profile Group (HPG) to each person                                   */
/*                                                                                         */
/*                                                                                         */
/*                                                                                         */
/*=========================================================================================*/
/*
/* Efficiency notes: 
/*   seq_id_lowest_hc
/*   seq_id_highest_hc
/*
/*
/*=========================================================================================*/
             


                                       /* ======================================= */
                                       /* Macro:  HPG_0_SET_VARIABLES_TO_ZERO     */
                                       /* - Run this for each case                */
                                       /* ======================================= */
%MACRO HPG_0_SET_VARIABLES_TO_ZERO;

pop_hpg_return_code = "00";

n_hcs_added = 0;

n_branches_with_combo = 0;

hpg_combined_pair_cnt = 0;

t_branch_id_low = 999;
t_branch_id_high = 0;

n_multi_branch = 0;

n_branches_with_combo = 0;

hpg_comorbidity_cnt = 0;

DO i = 1 TO &SYS_HPG_BRANCH_CNT.;

    hpg_branch      { i } = 0;

    hpg_combo       { i } = "-";

    hpg_comorbid    { i } = "--";

    hpg_branch_rank { i } = .;

END;

                                      /* Set in HPG 3 */
branch_cnt = 0;

high_branch_id = 999;
high_branch_rank = 999;
high_branch_code = "----";
high_branch_split_code = "rr";


                                      /* Set in HPG 4 */
hpg_comorbidity_cnt = .;


                                      /* Set in HPG 5 */
hpg_category_code = "??";
hpg_code = "-99 not set";

hpg_concurrent_riw = -999;

hpg_prospective_riw = -999;

FORMAT hpg_concurrent_riw 
       hpg_prospective_riw   9.4;
	   

%MEND HPG_0_SET_VARIABLES_TO_ZERO;



                                                      /* =================================== */
                                                      /* REMOVE this HPG Branch              */
                                                      /* ==> It's part of a COMBO            */
                                                      /* =================================== */
%MACRO REMOVE_BRANCH_ID (remove_id);


   hpg_branch   { &REMOVE_ID. } = -3;

   hpg_combo    { &REMOVE_ID. } = "x";


%MEND REMOVE_BRANCH_ID;


                                                      /* =================================== */
                                                      /* ADD this HPG Branch                 */
                                                      /* =================================== */
%MACRO ADD_BRANCH_ID;


n_hcs_added = n_hcs_added + 1;

                                                /* Set the HPG BRANCH */

IF  hpg_branch {branch_id} = 1
THEN DO;
         /* =============================*/ 
         /* The Branch was already set   */
         /* =============================*/ 
        n_multi_branch = n_multi_branch + 1;
     END;
ELSE hpg_branch {branch_id} = 1;  

                                                /* Set the BRANCH_COMBO_FLAG */

hpg_combo    {branch_id} = branch_combo_flag;  

IF branch_combo_flag = "Y"
THEN n_branches_with_combo = n_branches_with_combo + 1;


IF branch_id < t_branch_id_low
THEN t_branch_id_low = branch_id;

IF branch_id > t_branch_id_high
THEN t_branch_id_high = branch_id;


%MEND ADD_BRANCH_ID;


                                                      /* =================================== */
                                                      /* ASSIGN_HPG_LOGIC_FIELDS
                                                      /* =================================== */



/*===========================================================================*/
/* $POP_HPG_LOGIC  
/*
/* POP_HPG_ID_LOGIC_KEY 
/*     METHODOLOGY_YEAR       01 - 04  2016
/*     HIGH_BRANCH_ID         05 - 07  1 to number of HPG branches 
/*     HPG_SPLIT_CODE         08 - 09  00 - This branch is NOT split 
/*                                     01 - This branch has a split
/*
/* POP_HPG_ID_LOGIC_LOOKUP 
/*     METHODOLTY_YEAR        01 - 04  2016
/*     HIGH_BRANCH_ID         05 - 07  1 to number of HPG branches 
/*     HPG_SPLIT_CODE         08 - 09  00 - This branch is NOT split 
/*                                     01 - This branch has a split
/*     HPG_CATEGORY_CODE      10 - 11 
/*     HPG_CODE               12 - 16  
/*     HPG_CONCURRENT_RIW     17 - 25  Concurrent RIW
/*     HPG_PROSPECTIVE_RIW    26 - 34  Prospective RIW
/*
/*===========================================================================*/
%MACRO ASSIGN_HPG_LOGIC_FIELDS;

pop_hpg_logic_key  = PUT (methodology_year, 004.) || 
                     PUT (high_branch_ID,  003.) ||
                     t_split_code;

pop_hpg_logic_lookup   = PUT(pop_hpg_logic_key, $POP_HPG_LOGIC.); 

hpg_category_code      = SUBSTR (pop_hpg_logic_lookup, 010, 002);

hpg_code               = SUBSTR (pop_hpg_logic_lookup, 012, 005);

hpg_concurrent_riw  = SUBSTR (pop_hpg_logic_lookup, 017, 009) + 0.0;

hpg_prospective_riw = SUBSTR (pop_hpg_logic_lookup, 026, 009) + 0.0;

                                      /* ============================== */
                                      /* Set PROSPECTIVE RIW to zero    */
                                      /* ============================== */
IF hcn_valid_on_ref_date_flag = "N"
THEN hpg_prospective_riw = 0;


DROP pop_hpg_logic_key
     pop_hpg_logic_lookup;

%MEND ASSIGN_HPG_LOGIC_FIELDS;


%MACRO hpg_assignment;


/* ============================================================== */
/* HPG Step 1 - Loop through POP Health Conditions ($004)         */
/*    ==> Set up HPG BRANCH array                                 */
/*                                                                */
/*                                                                */
/*  FYI - seq_id_LOWEST_HC and seq_id_HIGHEST_HC are assigned       */
/*                                                                */
/* ============================================================== */
f_marker = "HPG 1     ";

LENGTH branch_combo_flag $001.;

DO loop_hc_cnt = seq_id_lowest_hc TO seq_id_highest_hc;

    IF health_condition_ { loop_hc_cnt } = 1 
    THEN DO;

            health_condition_code = COMPRESS(VNAME(health_condition_ {loop_hc_cnt}));

            hpg_branch_key    = PUT(methodology_year, Z4.) || health_condition_code ;

            hpg_branch_lookup = PUT(hpg_branch_key, $POP_HPG_BRANCH_ASSIGN.);

			branch_ID                 = SUBSTR (hpg_branch_lookup, 009, 003) + 0;
	        branch_combo_flag         = SUBSTR (hpg_branch_lookup, 012, 001);

           %ADD_BRANCH_ID;  

/* OUTPUT pop_grouper_assign_HPG_trace; */

        END;

END;


health_condition_code = "done";

branch_ID = .;
branch_combo_flag = "-";
health_condition_code = " ";

/* OUTPUT pop_grouper_assign_HPG_trace; */

DROP hpg_branch_key
     hpg_branch_lookup;

/*===========================================================================*/
/* HPG Step 2 - Check for BRANCH COMBINATIONS  
/*  
/*      ==> Only do this if N_BRANCHES_WITH_COMBO > 1
/*                              
/* hpg_combined_pair_cnt = Number of PAIRS that were combined                             
/*                              
/*===========================================================================*/
/* $POP_HPG_COMBO_ASSIGN
/*        
/*          methodology_year               01 to 04
/*          branch_1_ID                    05 to 07
/*          branch_2_ID                    08 to 10
/*           
/*          branch_combo_ID                11 to 13
/*        
/*============================================================================*/
f_marker = "HPG 2";


LENGTH pop_hpg_combo_key    $010. 
       pop_hpg_combo_lookup $013.;


IF n_branches_with_combo > 1
THEN DO i = t_branch_id_low TO t_branch_id_high ;


            IF  hpg_combo { i } = "Y" 
            THEN DO j = (i + 1) TO t_branch_id_high;

                    IF  hpg_combo { j } = "Y" 
                    THEN DO;

                            /* ================================================ */
					        /* Only check when ** BOTH ** BRANCH_COMBO_FLAG = Y */
                            /* ================================================ */

                            pop_hpg_combo_key  = PUT(methodology_year, Z4.) || 
                                                 PUT (i, 3.) ||
                                                 PUT (j, 3.);

                            pop_hpg_combo_lookup = PUT(pop_hpg_combo_key, $POP_HPG_COMBO_ASSIGN.); 


                            IF pop_hpg_combo_lookup NE " " 
                            THEN DO;
 						           /* ============================================ */
 						           /* Set the COMBO Branch ID                      */
                                   /* Remove / Re-set the source BRANCH IDs        */
						           /* ============================================ */
                                    hpg_combined_pair_cnt = hpg_combined_pair_cnt + 1; 

                                    branch_id          = SUBSTR (pop_hpg_combo_lookup, 011, 003) + 0;

                                    branch_combo_flag = "Z";  /* This BRANCH is the combo */
  
                                    %ADD_BRANCH_ID;

                                    %REMOVE_BRANCH_ID (i);

                                    %REMOVE_BRANCH_ID (j);

/* OUTPUT pop_grouper_assign_HPG_trace; */

                                END;

                         END; /* j loop */

                  END;  /* i Loop */


     END;  /* More than one BRANCH */

ELSE DO;
            /* No combos */
     END;


DROP pop_hpg_combo_key
     pop_hpg_combo_lookup;

/* ============================================================== */
/* HPG Step 3 - Find the HIGH RANKING Branch                      */
/*                                                                */
/*      - LOOP through the HPG BRANCHES                           */
/*                                                                */
/*      - For each branch that is set / flagged                   */
/*           - Add 1 to BRANCH_CNT                                */
/*                                                                */
/*          - lookup information in the POP_HPG_BRANCH table      */
/*               - Assign HPG_BRANCH_RANK                         */
/*               - Assign HPG_BRANCH_CODE                         */
/*               - Assign COMORBIDITY_CATEGORY_CODE               */
/*                                                                */
/*           - IF the RANK is lower than the HIGH_RANK            */
/*                      Set HIGH_BRANCH_ID                        */
/*                      Set HIGH_BRANCH_RANK                      */
/*                      Set HIGH_BRANCH_SPLIT_CODE ***            */
/*                      Set HIGH_BRANCH_CODE                      */
/*                                                                */
/*                                                                */
/*   Counters and LOWEST / HIGHEST                                */
/*     BRANCH_CNT = Number of branches                            */
/*     BRANCH_ID_LOWEST = ID of lowest                            */
/*     BRANCH_ID_HIGHEST = ID of highest                          */
/*                                                                */
/*                                                                */
/* ============================================================== */

f_marker = "HPG 3";

LENGTH branch_comorbid $002.;
 
branch_id_lowest = 999;
branch_id_highest = -999;

DO i = 1 TO &SYS_HPG_BRANCH_CNT.;

    IF hpg_branch { i } = 1       /* The COMBO SOURCE BRANCHS  are -3 */
    THEN DO;
            IF i < branch_id_lowest
			THEN branch_id_lowest = i;

            IF i > branch_id_highest
			THEN branch_id_highest = i;


	        branch_cnt = branch_cnt + 1;
            pop_hpg_branch_key = PUT(methodology_year, Z4.) || 
                                 PUT (i, Z003.);

            pop_hpg_branch_lookup = PUT(pop_hpg_branch_key, $POP_HPG_BRANCH.); 

            IF pop_hpg_branch_lookup NE " " 
            THEN DO;
                     branch_rank   = SUBSTR (pop_hpg_branch_lookup, 008, 003) + 0;

                     hpg_branch_rank { i } = branch_rank;

                     branch_comorbid  = SUBSTR (pop_hpg_branch_lookup, 011, 002);
                     hpg_comorbid    { i } = branch_comorbid;

					 IF branch_rank < high_branch_rank
					 THEN DO;
					         high_branch_id = i;
                             high_branch_rank       = branch_rank;
                             high_branch_split_code = SUBSTR (pop_hpg_branch_lookup, 013, 002); 

                             high_branch_code       = SUBSTR (pop_hpg_branch_lookup, 015, 004); 
					      END;

               END;
     END;

END;

/* OUTPUT pop_grouper_assign_HPG_trace; */


DROP pop_hpg_branch_key
     pop_hpg_branch_lookup;


/* ============================================================== */
/* HPG Step 4 - Get comorbidity_cnt                               */
/*              ==> Only ** IF ** HIGH_SPLIT_CODE "01"            */
/*                                                                */
/* ============================================================== */
f_marker = "HPG 4";
	
IF high_branch_split_code = "00"
THEN DO;
         hpg_comorbidity_cnt = -1;    /* Don't count comorbidities if there is no split */
     END;

ELSE DO;
         hpg_comorbidity_cnt = 0;

		 IF branch_cnt = 1
		 THEN hpg_comorbidity_cnt = -4;               /* Can't be comorbidities for ONLY one branch */
		 ELSE
		 DO i = branch_id_lowest TO branch_id_highest;

            IF hpg_branch { i } = 1   & 
			   hpg_branch_rank { i } > high_branch_rank &
               hpg_comorbid { i } IN ("C1" "C2")
            THEN hpg_comorbidity_cnt = hpg_comorbidity_cnt + 1;

         END;

     END;

/* OUTPUT pop_grouper_assign_HPG_trace; */



/*===========================================================================*/
/* HPG 5 - Assign the HPG code                                               */
/*                                                                           */
/*     If the HIGH_BRANCH_SPLIT_CODE is "01" (A split is allowed)            */ 
/*     ==> Set the T_SPLIT_CODE based on COMORBID_CNT                        */
/*                                                                           */
/*     If the HIGH_BRANCH_SPLIT_CODE is "01"                                 */
/*     then set T_SPLIT_CODE = "00" (No split for this branch)               */
/*                                                                           */
/*===========================================================================*/

f_marker = "HPG 5";


IF high_branch_split_code = "01"   /* There is a Comorbid SPLIT for the branch */
THEN DO;
        IF hpg_comorbidity_cnt > 0
        THEN t_split_code = "01";
        ELSE t_split_code = "00";

     END;

ELSE DO;
        t_split_code = "00";   /* There is NO Comorbid split for this branch */

     END;

%ASSIGN_HPG_LOGIC_FIELDS; 



/* OUTPUT pop_grouper_assign_HPG_trace; */


%MEND hpg_assignment;




%MACRO POP_10_ASSIGN_HPG;

LENGTH  pop_hpg_return_code 
        hpg_category_code  $002.
        hpg_code           $005.;


LENGTH f_marker  $012.;                              /* Testing - TRACING */


                                                                    /* ======================== */
                                                                    /* HPG array                */
                                                                    /* ======================== */
ARRAY hpg_branch      {&SYS_HPG_BRANCH_CNT.}    3.  &HPG_BRANCH_CODE_LIST. ;

ARRAY hpg_combo       {&SYS_HPG_BRANCH_CNT.} $001.  &HPG_BRANCH_COMBO_LIST. ;

ARRAY hpg_comorbid    {&SYS_HPG_BRANCH_CNT.} $002.  &HPG_BRANCH_COMORBID_LIST. ;

ARRAY hpg_branch_rank {&SYS_HPG_BRANCH_CNT.}    3.  &HPG_BRANCH_RANK_LIST. ;


                                                                    /* ======================== */
                                                                    /* LABELS                   */
                                                                    /* ======================== */
LABEL hpg_concurrent_riw     = "HPG*Concurrent*RIW"
      hpg_prospective_riw    = "HPG*Prospective*RIW"
      hpg_category_code      = "HPG*Category*Code"
      high_branch_split_code = "High*Branch*Split*Code"
      pop_user_code          = "POP*User*Code";

/* ========================================================================== */
/* Check POP_USER_CODE                                                        */
/*     ==> Run the HPG assignment ONLY when there are POP health conditions   */
/* ========================================================================== */


%HPG_0_SET_VARIABLES_TO_ZERO;


IF pop_user_code = "01"
THEN DO;
        %HPG_ASSIGNMENT;
     END;
ELSE

IF pop_user_code = "98"          
THEN DO;
                                  /* =================================== */ 
                                  /* POP Non-User                        */
                                  /* =================================== */ 
        hpg_comorbidity_cnt = -2;
        
		high_branch_id = 998;
		t_split_code = "00";
							   
       %ASSIGN_HPG_LOGIC_FIELDS; 

     END;
ELSE


IF pop_user_code = "00" 
THEN DO;
                                  /* =================================== */ 
                                  /* POP User with no health conditions  */
                                  /* =================================== */ 
        hpg_comorbidity_cnt = -3;

        high_branch_id = 997;
		t_split_code = "00";

        %ASSIGN_HPG_LOGIC_FIELDS; 

     END;

ELSE DO;
        hpg_code = "!! Error !!";
     END;


%MEND POP_10_ASSIGN_HPG;


/*================*/
/* End of program */
/*================*/
