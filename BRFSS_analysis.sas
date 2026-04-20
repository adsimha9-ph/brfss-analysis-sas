/*------------------------------------------------------------*/
/* Project: BRFSS Analysis: Income, Race, and Health Status  */
/* Author: Aditya Simha                                        */
/* Description:                                               */
/* This project analyzes BRFSS survey data using SAS to       */
/* examine associations between socioeconomic factors and     */
/* self reported health status using survey weighted methods. */
/*------------------------------------------------------------*/

/*------------------------------------------------------------*/
/* Import BRFSS CSV data into SAS work library               */
/*------------------------------------------------------------*/
proc import datafile="/home/u64219640/Projects/brfss_use.csv"
    out=work.brfss
    dbms=csv
    replace;
    getnames=yes;
run;

/* GENHLTH = General health status */
/* INCOME3 = Income category */
/* _RACE   = Race category */
/* _LLCPWT = Survey weight */

/*------------------------------------------------------------*/
/* Data cleaning and recoding step                           */
/*------------------------------------------------------------*/
data brfss;
    set brfss;

    /* Create binary outcome: 1 = poor/fair health, 0 = good or better */
    POOR_HEALTH = .;

    /*
       Recode GENHLTH (general health status):
       1 = Excellent, 2 = Very good, 3 = Good  → 0 (not poor health)
       4 = Fair, 5 = Poor                      → 1 (poor health)
       Others/missing → .
    */
    select (GENHLTH);
        when (1, 2, 3) POOR_HEALTH = 0;
        when (4, 5)    POOR_HEALTH = 1;
        otherwise      POOR_HEALTH = .;
    end;

    /*--------------------------------------------------------*/
    /* Handle missing / invalid values                       */
    /*--------------------------------------------------------*/

    /* Income: 77 = Don't know, 99 = Refused → set to missing */
    if INCOME3 in (77, 99) then INCOME3 = .;

    /* Race: 9 = missing/refused → set to missing */
    if _RACE = 9 then _RACE = .;

run;


/*------------------------------------------------------------*/
/* Survey-weighted frequency: Income vs Poor Health          */
/*------------------------------------------------------------*/
proc surveyfreq data=brfss;

    /* Cross-tab income categories by poor health */
    tables income3*poor_health / row;

    /* Apply BRFSS sampling weights */
    weight _llcpwt;
run;


/*------------------------------------------------------------*/
/* Survey-weighted frequency: Race vs Poor Health            */
/*------------------------------------------------------------*/
proc surveyfreq data=brfss;

    /* Cross-tab race by poor health */
    tables _race*poor_health / row;

    /* Apply sampling weights */
    weight _llcpwt;
run;


/*------------------------------------------------------------*/
/* Survey-weighted logistic regression model                 */
/*------------------------------------------------------------*/
proc surveylogistic data=brfss;
	where POOR_HEALTH in (0, 1);
    /* Specify categorical predictors and reference groups */
    class income3(ref='11') _race(ref='1') / param=ref;

    /*
       Model probability of poor health (POOR_HEALTH = 1)
       as a function of income and race
    */
    model poor_health(event='1') = income3 _race;

    /* Apply survey weights */
    weight _llcpwt;
run;