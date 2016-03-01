/*----------------------------------------*
 |file:    master_check.do                | 
 |project: high frequency checks          |
 |author:  christopher boyer              |
 |         matthew bombyk                 |
 |         innovations for poverty action |
 |date:    2016-02-13                     |
 *----------------------------------------*/

// this line adds standard boilerplate headings
ipadoheader, version(13.0)
use "data/Mongolia SHPS Tracking_with TA_PII removed_Raw.dta", clear
 
/*
 overview:
   this file contains the following data quality checks...
     1. Check that all interviews were completed
     2. Check that there are no duplicate observations
     3. Check that all surveys have consent
     4. Check that certain critical variables have no missing values
     5. Check that follow up record ids match original
     6. Check that no variable has only one distinct value
     7. Check that no variable has all missing values
     8. Check hard/soft constraints
     9. Check specify other vars for items that can be included
     10. Check that date values fall within survey range
     11. Check that there are no outliers for unconstrained vars
     12. Check that survey and section durations fall within limits
*/

// dtanotes

// local definitions (EDIT THESE)
local infile  "matt_input.xlsx"
local outfile "hfc_outputs.xlsx"
local repfile "hfc_replacements.xlsx"
local master "master_tracking_list.dta"
local id "surveyid"
local enum "enumeratorid"


/* =============================================================== 
   ================== Pre-process Import Data  =================== 
   =============================================================== */
qui {
	// generate start and end dates from SCTO values
	g startdate = dofc(starttime)
	g enddate = dofc(endtime)
	format %td startdate enddate

	// recode don't know/refusal values
	ds, has(type numeric)
	local numeric `r(varlist)'
	recode `numeric' (8888 = .d)
	recode `numeric' (9999 = .r)
	recode `numeric' (7777 = .n)
	
	// get the current date
	local today = date(c(current_date), "DMY")
	local today_f : di %tdnn/dd/YY `today'
	
	// get total number of interviews
	local n = _N
}

/* =============================================================== 
   ================== Import locals from Excel  ================== 
   =============================================================== */

ipacheckimport using "`infile'"

/* =============================================================== 
   ================= Replacements and Corrections ================ 
   =============================================================== */

*readreplace using "hfc_replacements.xlsx", id("id") variable("variable") value("newvalue") excel


/* =============================================================== 
   ==================== High Frequency Checks ==================== 
   =============================================================== */

putexcel A1=("HFC Summary Report") ///
         A2=("Report Date") B2=("`today_f'") ///
		 A3=("Total Interviews") B3=("`n'") ///
		 using `outfile', sheet("0. summary") replace

/* <=========== HFC 1. Check that all interviews were completed ===========> */
/*ipacheckcomplete ${variable1}, ivalue(${incomplete_value1}) ///
    id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace*/
	
*putexcel A4=("HFC 1") A5=("number of incompletes") B5=("`r(nincomplete)'") using `outfile', ///
*    sheet("0. summary") modify

/* <======== HFC 2. Check that there are no duplicate observations ========> */
ipacheckdups ${variable2}, enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel A6=("HFC 2") A7=("number of duplicates") B7=("`r(ndups1)'") using `outfile', ///
    sheet("0. summary") modify
	
/* <============== HFC 3. Check that all surveys have consent =============> */
ipacheckconsent ${variable3}, consentvalue(${consent_value3}) ///
    id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel A8=("HFC 3") A9=("number without consent") B9 =("`r(noconsent)'") using `outfile', ///
    sheet("0. summary") modify

/* <===== HFC 4. Check that critical variables have no missing values =====> */
ipachecknomiss ${variable4}, id(`id') /// 
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace
		
putexcel A10=("HFC 4") ///
         A11=("number of variables with a miss.") ///
		 A12=("number of missing values") ///
		 B11=("`r(missvar)'") ///
		 B12=("`r(nmiss)'") ///
		 using `outfile', sheet("0. summary") modify
	
/* <======== HFC 5. Check that follow up record ids match original ========> */
/*ipacheckfollowup using `master', id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace*/

/* <====== HFC 6. Check that no variable has only one distinct value ======> */
*ipacheckskip var, saving(`outfile') enumerator(`enum')

/* <======== HFC 7. Check that no variable has all missing values =========> */
ipacheckallmiss, id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetmodify

putexcel A17=("HFC 7") A18=("number of all missing variables") B18 =("`r(nallmiss)'") using `outfile', ///
    sheet("0. summary") modify

/* <=============== HFC 8. Check for hard/soft constraints ================> */
ipacheckconstraints ${variable8}, smin(${soft_min8}) ///
    smax(${soft_max8}) ///
    id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel A19=("HFC 8") ///
         A20=("number of soft constraint violations.") ///
		 A21=("number of hard constraint violations.") ///
		 B20=("`r(nsoft)'") ///
		 B21=("`r(nhard)'") ///
		 using `outfile', sheet("0. summary") modify

/* <================== HFC 9. Check specify other values ==================> */
ipacheckspecify ${specify_variable9}, id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel A22=("HFC 9") A23=("number of times other specified") B23 =("`r(nspecify)'") using `outfile', ///
    sheet("0. summary") modify
	
/* <========== HFC 10. Check that dates fall within survey range ==========> */
ipacheckdates ${startdate10} ${enddate10}, surveystart(${surveystart10}) ///
    id(`id') ///
    enumerator(`enum') ///
    saving(`outfile') ///
    sheetreplace

putexcel A24=("HFC 10") ///
         A25=("number of missing start or end dates.") ///
         A26=("number with unequal start/end dates.") ///
		 A27=("number of dates before survey start.") ///
		 A28=("number with start after current date.") ///
		 B25=("`r(missing)'") ///
		 B26=("`r(diff_end)'") ///
		 B27=("`r(diff_start)'") ///
		 B28=("`r(diff_today)'") ///
		 using `outfile', sheet("0. summary") modify

/* <============= HFC 11. Check for outliers in unconstrained =============> */
ipacheckoutliers ${variable11}, id(`id') ///
                                enumerator(`enum') ///
								iqrmulti(${iqr_multiplier11}) ///
								saving(`outfile') ///
								sheetreplace

putexcel A29=("HFC 11") A30=("number of potential outliers") B30 =("`r(noutliers)'") using `outfile', ///
    sheet("0. summary") modify
	
/* <============= HFC 12. Check survey and section durations ==============> */
*ipacheckduration var, saving(`outfile') enumerator(`enum')


/* ===============================================================
   =============== User Checks Programming Template ==============
   =============================================================== */


/* ===============================================================
   ================= Create Enumerator Dashboard =================
   =============================================================== */
keep if q1_4_result == 1
*drop ta_*
#delimit ;
ipacheckfo enumeratorid using "hfc_enumerators.xlsx", 
   dkrfvars(q3_1
            q3_1_1
q3_2_1
q3_6_phone
q3_8
q3_8_1_1
q3_8_2_1
q3_8_3
q3_10
q3_10_1_1
q3_10_2_1
q3_11
q3_13
q3_17
q3_19_1
q3_20
q3_24
q3_26_1
q4_2_2
q4_2_2_1
q4_2_2_2
q4_2_2_3
q4_2_2_4
q4_2_4
q4_2_5
q4_2_5_1_1
q4_2_5_1_2
q4_2_7
q4_2_8
q4_2_10
q4_2_11
q4_2_12_1
q4_2_14
q4_3
q4_3_1
q4_4_1
q4_4_2
q4_4_5
q4_4_5_1
q4_4_5_2
q4_4_5_3
q4_4_5_4
q4_4_7
q4_4_8
q4_4_11
q4_4_13
q4_4_14
q4_4_17
q4_5
q4_6_1
q4_6_4
q4_6_5
q4_6_7
q4_6_8
q4_6_9
q4_6_10
q4_6_11
q4_6_12
q4_8
q4_10_1
q4_10_2
q4_10_3
q4_10_4
q5_1
q5_3_1
q6_1
q6_3_1
q6_3_3
q6_3_4
q6_3_5
q6_4_4
q6_4_5
q6_5_5
q6_6
q6_6_1
q6_6_2_1
q7_2_1
q7_3_1
q7_3_1_1
q8_1_1
q8_3_1
q8_5_1
q8_5_2
q8_5_3
q8_6_1
q8_7_2
q9
q9_3)
   missvars(c1_1_consent 
            c1_1_consent_sign
			treatment) 
   durvars(ta_*) 
   exclude(SubmissionDate 
           starttime 
		   endtime 
		   deviceid 
		   subscriberid 
		   simid 
		   devicephonenum 
		   comments 
		   text_audit 
		   metainstanceID 
		   KEY 
		   comfield1 
		   comfield2 
		   audio_audit 
		   comfield3 
		   comfield4 
		   startdate 
		   enddate 
		   sdate
		   ta_*)
   subdate(sdate);
#delimit cr

/* ===============================================================
   ================== Create Research Dashboard ==================
   =============================================================== */
