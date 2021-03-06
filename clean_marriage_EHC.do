* marriage history 
* created on 02/07/2019
* updated on 02/25/2019 
* updated on 02/26 2019 : after meeting with cc, decided using information on both marital status AND year of marriage 
* updated on 03/11/2019 : update yearly marital status

clear all 
clear matrix 
set more off 
capture log close 


global date "02072019"   // mmddyy
*global dir "C:\Users\donghuiw\Desktop\Marriage"  // office 
*global dir "W:\Marriage"                         // pri 
global dir "C:\Users\wdhec\Desktop\Marriage"     // home  

cfps  // load cfps 

/* overall coding rules 
1.Status based on year & month of marriage > 
2.Retrospective  updated  individual  survey  response  at  T+1  >
3.Individual  survey  response  at  T  > 
4. Household  roster  response  at  T1
*/


*======== marriage timing based on EHC==============
use $w10a, clear

*First, correct 2010 marriage dates (yr & month)  based on 2012 re-interview
 
***********EC section in 2012 adult survey: [2010 年婚姻确认]*************
*qec104 qec105y qec105m : current spouse       ==> correct E210
*qec303 qec304y qec304m : previous spouse      ==> correct E405
*qec403 qec404y qec404m : passwed-away soupse  ==> correct E501 

*EC5 上一任配偶（2010 的同伴或配偶）确认
*qec501 qec502y qec502m : previous spouse     ==> correct E210 (only 3 case need to correct)
*qec601 qec602y qec602m : passed-away spouse  ==> correct E210 (only 9 case need to correct) 
*qec701 qec702y qec702m: first marriage       ==> correct _E605y_best


local ec "qec104 qec105y qec105m qec303 qec304y qec304m qec403 qec404y qec404m qec501 qec502y qec502m qec601 qec602y qec602m qec701 qec702y qec702m"
merge 1:1 pid using $w12a, keepusing (`ec') keep(match master) nogen 

rename (qe605y_best qe605m)  (qe605by qe605bm)  // for looping covenience 	

local ym "y m"
foreach x of local ym{
replace qe210`x'=qec105`x' if qec104==5 &  qec105`x'>0 & qec105`x' !=.   // mar date with current spouse, if correct
replace qe210`x'=qec502`x' if qec501==5 &  qec502`x'>0 & qec502`x' !=.   // continue correct current spouse
replace qe210`x'=qec602`x' if qec601==5 &  qec602`x'>0 & qec602`x' !=.   // continue correct current spouse

replace qe405`x'=qec304`x' if qec303==5 &  qec304`x'>0 & qec304`x' !=.   // divorced spouse (previous spouse), if correct 
replace qe501`x'=qec404`x' if qec403==5 &  qec404`x'>0 & qec404`x' !=.   // mar date with passed-away spouse, if correct 

replace qe605b`x'=qec702`x' if qec701==5  &  qec702`x'>0 & qec702`x' !=.  // first marriage 
}


*Second, identify date of earliest marriage 
local date "qe210 qe405 qe501 qe605b"
foreach x of local date {

*If has valid month given marital yr yr is valid 
*tab `x'm if `x'y>0 & `x'y<.,m   // a few refused to answer and don't know  
*tab `x'y if `x'm <0,m           // for month refuse or don't knows, all but 4 mar yr happened propr to 2010, can safely ignore
*tab `x'y if `x'm==.,m

replace `x'm=1 if `x'm<0 & `x'y>0 & `x'y<2010   // assign month as 1 if month unkonwn but yr knwon 
replace `x'y=. if `x'y<0
replace `x'm=. if `x'm<0

*convert to stata date
g ym`x'=ym(`x'y, `x'm)
}
egen mar_min=rowmin(ym*)
g yminterv=ym(cyear, cmonth)

format mar_min yminterv %tm


local date "qe210y qe405y qe501y qe605by"  // keep yr as well just incase
keep pid ym* mar_min `date'
foreach x of varlist ym* mar_min `date'{
rename `x' `x'_10a 
}
g in_10a=1
tempfile w10a
save `w10a.dta', replace 


use $w12a, clear
*EA 2012 年婚姻状况 
merge 1:1 pid using $w14a, keepusing(qea1 qea205y qea205m) keep(match master) nogen 

*correct 2012 marital timing based on 2014 re-inteview records
local date "qe208 qe413  qe514"
foreach x of local date {

egen dif`x'_y=diff(`x'y qea205y)   // compare differences between 14 re-interview recode and 12 recode
egen dif`x'_m=diff(`x'm qea205m)

replace `x'y=qea205y if qea1==0 & dif`x'_y==1 &  qea205y>0 & qea205y<.  
replace `x'm=qea205m if qea1==0 & dif`x'_m==1 &  qea205m>0 & qea205m<.
}

 
*convert yr month into stata date 
local date "qe208 qe413  qe514 qe604"
foreach x of local date {

*If has valid month given valid yr
*tab `x'm if `x'y>0 & `x'y<.,m   // a few refused to answer and don't know  
*tab `x'y if `x'm <0,m  
replace `x'm=1 if `x'm<0 & `x'y>0 & `x'y<. & `x'y<2010   // assign month as 1 if month unkonwn but yr knwon for yr prior to 2010

replace `x'y=. if `x'y<0
replace `x'm=. if `x'm<0

g ym`x'=ym(`x'y, `x'm)
}

egen mar_min=rowmin(ym*)
g    yminterv=ym(cyear, cmonth)

format mar_min yminterv %tm


local date "qe208y qe413y  qe514y qe604y"
keep pid ym* mar_min `date'
foreach x of varlist ym*  mar_min `date'{
rename `x' `x'_12a 
}

g in_12a=1
tempfile w12a
save `w12a.dta', replace 



use $w14a, clear
rename(qea205y qea205m)(qea205_cy qea205_cm)   // rename to avoid confusion 
rename eeb401y_a_*  eeb401_a_*y
rename eeb401m_a_*  eeb401_a_*m  			 // for looping conveneince 

*Correct 2014 marital timing based on 2016 re-inteview records

merge 1:1 pid using $w16a, keepusing(qea1 qea205y qea205m) keep(match master) nogen 

local date "eeb201 eeb401_a_1"
foreach x of local date {
egen di1416_`x'y=diff(`x'y qea205y)
egen di1416_`x'm=diff(`x'm qea205m)

replace `x'y=qea205y if qea1==5 & di1416_`x'y==1 &  qea205y>0 & qea205y<.   // no change made 
replace `x'm=qea205m if qea1==5 & di1416_`x'm==1 &  qea205m>0 & qea205m<.   // no change made 
}
*eeb401_a_2-5 are all NAs or missing, no need to include


* assgin value to seasons : N=18 changes made
tab eeb401_a_1y if eeb401_a_1m>12,m

replace eeb401_a_1m=3 if eeb401_a_1m==13    // spring : 3
replace eeb401_a_1m=6 if eeb401_a_1m==14   // summer : 6
replace eeb401_a_1m=9 if eeb401_a_1m==15   // fall : 9
replace eeb401_a_1m=12 if eeb401_a_1m==16  // winter : 12


*local date "eeb201 eeb401_a_1"
*Note : qea205_cy is still necessary to include incase someone was skipped in 2012 but was originally interviewed in 2010  

local date "qea205_c eeb201 eeb401_a_1"
foreach x of local date {

*If has valid month given marital yr yr is valid 
*tab `x'm if `x'y>0 & `x'y<.,m   // a few don't knows or refuse to answer

tab `x'y if `x'm <0,m  // for month refuse or don't knows, most mar yr happened prior to 2010, but also a few get married after 2010 

replace `x'm=1 if `x'm<0 & `x'y>0 & `x'y<.  & `x'y<2010   // assign month as 1 if month unkonwn but yr knwon for marriage occured prior to 2010, leave month as missing if married after 2010 

replace `x'y=. if `x'y<0
replace `x'm=. if `x'm<0
g ym`x'=ym(`x'y, `x'm)
}

egen mar_min=rowmin(ym*)
g yminterv=ym(cyear, cmonth)

local date "qea205_cy eeb201y eeb401_a_1y"

keep pid ym*  mar_min `date'

foreach x of varlist ym*  mar_min `date' {
rename `x' `x'_14a 
}
g in_14a=1
tempfile w14a 
save `w14a.dta', replace 



*2016
use $w16a, clear
rename eeb401y_a_*  eeb401_a_*y
rename eeb401m_a_*  eeb401_a_*m   // for looping conveneince 

local date "qea205 eeb201 eeb401_a_1"
*local date "eeb201 eeb401_a_1"

foreach x of local date {

*If has valid month given marital yr yr is valid 
*tab `x'm if `x'y>0 & `x'y<.,m  							 // a few don't knows or refuse to answer 

tab `x'y if `x'm <0,m                                      // for month refuse or don't knows, most mar yr happened prior to 2010, but also a few get married after 2010 

replace `x'm=1 if `x'm<0 & `x'y>0 & `x'y<.  & `x'y<2010   // assign month as 1 if month unkonwn but yr knwon for marriage occured prior to 2010  

replace `x'y=. if `x'y<0
replace `x'm=. if `x'm<0
g ym`x'=ym(`x'y, `x'm)
}

egen mar_min=rowmin(ym*)
g yminterv=ym(cyear, cmonth)

local date "qea205y eeb201y eeb401_a_1y"

keep pid ym*  mar_min `date'

foreach x of varlist ym*  mar_min `date'{
rename `x' `x'_16a 
}

g in_16a=1

tempfile w16a 
save `w16a.dta', replace 

use `w10a.dta', clear
merge 1:1 pid using `w12a.dta', keep(master match) nogen
merge 1:1 pid using `w14a.dta', keep(master match) nogen
merge 1:1 pid using `w16a.dta', keep(master match) nogen
*merge 1:1 pid using `mar.dta',  keep(master match) nogen

rename yminterv* interv*
egen   mar_min=rowmin(ym*)  //4647  missing : leave for now 
format mar_min %tm

save "${datadir}\mar_temp.dta" ,replace 
 
*============marital status at the time of the survey=============== 
use $w10a, clear
keep pid qe1_best
rename qe1_best qe1_best_10a

merge 1:1 pid using $w12a, keepusing(cfps2010_marriage qe104) nogen
rename (cfps2010_marriage qe104) (cfps2010_marriage_12a  qe104_12a)

merge 1:1 pid using $w14a, keepusing (cfps2012_marriage_update qea0) nogen 
rename (cfps2012_marriage_update qea0) (cfps2012_marriage_update_14a qea0_14a) 

merge 1:1 pid using $w16a, keepusing (cfps2014_marriage_update qea0) nogen
rename (cfps2014_marriage_update qea0) (cfps2014_marriage_update_16a qea0_16a)

merge 1:m pid using $w10hh, keepusing(tb3_a_p co_p) nogen
duplicates tag pid, gen(dup) 
drop if dup !=0 & co_p ==0  //drop duplicated ppl 
rename  tb3_a_p mar10_10hh
drop dup

merge 1:m pid using $w12hh, keepusing(tb3_a12_p co_a12_p) nogen 
duplicates tag pid, gen(dup) 
drop if dup !=0 & co_a12_p  ==0  //drop duplicated ppl 
rename  tb3_a12_p  mar12_12hh
drop dup

merge 1:m pid using $w14hh, keepusing(tb3_a14_p co_a14_p) nogen 
duplicates tag pid, gen(dup) 
drop if dup !=0 & co_a14_p  ==0  //drop duplicated ppl 
rename  tb3_a14_p  mar14_14hh
drop dup

merge 1:m pid using $w16hh, keepusing(tb3_a16_p co_a16_p) nogen 
duplicates tag pid, gen(dup) 
drop if dup !=0 & co_a16_p  ==0  //drop duplicated ppl 
rename  tb3_a16_p  mar16_16hh


*marriage status: 1.single 2.married;3 cohabitation; 4 divorced 5.widowed  
g       mar10=cfps2010_marriage_12a if  cfps2010_marriage_12a>0   & cfps2010_marriage_12a <.
replace mar10=qe1_best_10a           if  mar10==. & qe1_best_10a>0 & qe1_best_10a<.
replace mar10=mar10_10hh 			 if  mar10==. & mar10_10hh>0 & mar10_10hh<.

g       mar12=cfps2012_marriage_update_14a  if  cfps2012_marriage_update_14a>0 & cfps2012_marriage_update_14a<.
replace mar12= qe104_12a                    if  mar12==. & qe104_12a>0 & qe104_12a<. 
replace mar12=mar12_12hh                    if  mar12==. & mar12_12hh>0 & mar12_12hh<.

g       mar14=cfps2014_marriage_update_16a if cfps2014_marriage_update_16a>0 & cfps2014_marriage_update_16a<.
replace mar14=qea0_14a                     if mar14==. & qea0_14a>0 & qea0_14a<.
replace mar14=mar14_14hh                   if mar14==. & mar14_14hh>0 & mar14_14hh<. 

g       mar16=qea0_16a         if qea0_16a>0 & qea0_16a<.
replace mar16=mar16_16hh       if mar16==.  & mar16_16hh>0 & mar16_16hh<.

*======Apply correction rules: marital status based on marriage timing, then marital status at the time of the survey 
merge 1:1 pid using  "${datadir}\mar_temp.dta" , nogen 

* impute missing of mar_min
* if single  in 16, remain single in 10-16 : assign missing as 2018 01
* if married in 10, remain married in 10-16, assign missing as 2009 01 
replace mar_min=ym(2018,1) if inlist(mar16,1,3) & mar_min==.
replace mar_min=ym(2009,1) if inlist(mar10,2,4,5) & mar_min==.
*tab mar_min if in_10a==1,m  // still 1404 missing, leave as it is 


*Create marital status at the time of the survey based on mar_min 
*new var:  mar_c10, 12, 14, 16 
*drop mar_c* 

*use begining of survey year if not interviewed 
replace interv_10a=ym(2010,1) if interv_10a==.
replace interv_12a=ym(2012,1) if interv_12a==.
replace interv_14a=ym(2014,1) if interv_14a==.
replace interv_16a=ym(2016,1) if interv_16a==.
format  interv_1*a %tm
 

forval i=10(2)16 {
*married at t if marriage date is prior or on the interview date  
g 		mar_c`i'=1 if mar_min<=interv_`i'a & !missing(mar_min)

*single at t if marriage date is after interview date 
replace mar_c`i'=0 if mar_min>interv_`i'a & !missing(mar_min)
}


*Create marital status based at the time of the survey 
forval i=10(2)16 {
g       mar_t`i'=1 if inlist(mar`i',2,4,5)   //married, divorced, widowed :  married
replace mar_t`i'=0 if inlist(mar`i',1)    //single: single 
}
* leave cohabitation alone bx cohabitation could be cohabit prior to marrige or cohabit after divorced/widowed 

*trust mar_c, if missing, replace with mar_t
forval i=10(2)16 {
g        marstat`i'= mar_c`i'  		
replace  marstat`i'= mar_t`i' if mar_c`i'==.
}

// forval i=10(2)14{
// local j=`i'+2
// assert marstat`i'<=marstat`j' if !missing(marstat`i', marstat`j') & in_10a==1    // 3contraditions : leave as it is 
// }

*single in t , single in t-1
 replace  marstat10=0 if (marstat12==0 | marstat14==0 |marstat16==0 )& marstat10==.
 replace  marstat12=0 if (marstat14==0 |marstat16==0) & marstat12==.
 replace  marstat14=0 if marstat16==0 & marstat14==.

 *married in t, married in t+1
 replace  marstat12=1 if marstat10==1 & marstat12==.
 replace  marstat14=1 if (marstat10==1 |  marstat12==1) & marstat14==.
 replace  marstat16=1 if (marstat10==1 |  marstat12==1 | marstat14==1 ) & marstat16==.

keep if  in_10a==1 

*check descriptives 
*check : marrital status is irreversiable 
forval i=10(2)14 {
local j=`i'+2
*assert marstat`i'<=marstat`j' if !missing(marstat`i',marstat`j')    // 1 contradictions , leave as it is 
list pid marstat`i' marstat`j' mar10 mar12 mar14 mar16 mar_min if marstat`i'>marstat`j' & !missing(marstat`i',marstat`j') , sepby(pid)
}

*correct by hand for 2, leave one as it is 
*replace  marstat14=1 if pid==210085103 | pid== 450165107  

forval i=10(2)16 {
*tab marstat`i', m
list mar`i' mar_t`i' mar_c`i' mar_min if marstat`i'==.
}

forval i=10(2)16 {
tab marstat`i', m
}

misschk marstat10 marstat12 marstat14 marstat16, gen(m)
encode(mpattern), gen(m) 

*inter-mediate missing: last value carryfoward : N=33 would affected 

local yr "qe210y_10a qe405y_10a qe501y_10a qe605by_10a qe208y_12a qe413y_12a qe514y_12a qe604y_12a qea205_cy_14a eeb401_a_1y_14a eeb201y_14a qea205y_16a eeb201y_16a eeb401_a_1y_16a" 
keep  pid marstat* mar_min `yr' interv_*a
save "${datadir}\mar2wave_temp.dta", replace 


*=============apply restrictions==== 

/*
use "${datadir}\mar2wave_temp.dta", replace 
merge 1:1 pid using "${datadir}\panel_1016.dta", keep(matched)

*alive in 10-16
g 		alivep= alivep_16hh 
replace alivep=0 if alivep_12hh==0 & alivep==.
replace alivep=0 if alivep_14hh==0 & alivep==. 
drop if alivep==0    //==> 32387


*live with at least one parent 
keep if alivefm10==1 & alivefm12==1 &  alivefm14==1 & alivefm16==1 
keep if livepa10==1 //==>5721

tab marstat10,m

keep if marstat10==0
 
* check : marital status is in-reversable 
forval i=10(2)14 {
local j=`i'+2
*assert marstat`i' <=  marstat`j'  if  marstat`j'<.   // 2 contradictions . there are still some valid yr of first marriage. What happend ?

list mar`i'  marstat`i' mar`j'  marstat`j' mar_min if marstat`i'> marstat`j' & marstat`i'<.

*all contradictions are t+2 miscoded 
replace marstat`j'=marstat`i' if marstat`i'> marstat`j' & marstat`i'<.
}


forval i=10(2)16 {
tab marstat`i' if marstat10==0,m
}
*/

*=============================================
*Alternative: create yearly marital status regardless the timing of interview 
use "${datadir}\mar2wave_temp.dta", replace 

* if missing mar_min, but has valid information on marital status at the time of interview
g mardate=dofm(mar_min)   
format mardate %d
g mar_ymin=year(mardate)

*create year boundaries 
g interv_11a=ym(2011,1)
g interv_13a=ym(2013,1)
g interv_15a=ym(2015,1)

g int10d=dofm(interv_10a)
g int16d=dofm(interv_16a)
format int10d int16d %d
g int10=year(int10d)
g int16=year(int16d)

* new var : married2010-2016
* begining/ending time : date of the 2010/2016 interview
local t=int10  
local f=int16

forval k=`t'/`f' {
g	    married`k'=1 if `k'>=mar_ymin 
replace married`k'=0 if `k'<mar_ymin & mar_ymin !=. & married`k'==.
}

*still missing, impute with current status 
forval i=10(2)16 {
replace married20`i'=1  if marstat`i'==1  &  married20`i'==.
replace married20`i'=0  if marstat`i'==0  &  married20`i'==.
}

forval i=2010/2016 {
tab married`i',m
}

* check : marital status is in-reversable 
forval k=2010/2015 {
local j=`k'+1
assert married`k'<=married`j' if  married`k'<.   
}

*impute : single in t, single in t-1
*2011
forval i=2012/2016 {
replace married2011=0 if married`i'==0 & married2011==.
}

*2012
forval i=2013/2016 {
replace married2012=0 if married`i'==0 & married2012==.
}

*2013
 forval i=2014/2016 {
replace married2013=0 if married`i'==0 & married2013==.
}

*2014
forval i=2015/2016 {
replace married2014=0 if married`i'==0 & married2014==.
}

*2015
replace married2015=0 if married2015==0 & married2015==.


*married in t, married in t+1
*2016
forval i=2010/2015 {
replace married2016=1 if married`i'==1 & married2016==.
}

*2015 
forval i=2010/2014 {
replace married2015=1 if married`i'==1 & married2015==.
}

*2014 
forval i=2010/2013 {
replace married2014=1 if married`i'==1 & married2014==.
}

*2013 
forval i=2010/2012 {
replace married2013=1 if married`i'==1 & married2013==.
}

*2012: not change made


* compare marstat and married : N=99 inconsisencies what happend? 
// tab marstat10 married2010,m
// egen mard=diff(married2010 marstat10)
// list married2010 marstat10 interv_10a  mar_min if mard==1
* not sure what is going on, but use married2010 as criterior instead of marstat for now 

* interval missing for marriage: simplist remedy : last value carry forward 
misschk married201* if married2010==0, gen(marm)    // only work on those who are single in 2010 
encode(marmpattern), gen(m)
tab m, nolab

/*
------------------------------				
_2345	67	289	6.88	6.88
_2345	6_	10	0.24	7.12
_234_	__	14	0.33	7.45
_2___	__	82	1.95	9.41
___45	67	188	4.48	13.88
___45	6_	9	0.21	14.10
___4_	__	119	2.83	16.93
_____	67	563	13.41	30.34
_____	6_	126	3.00	33.34
_____	__	2,799	66.66	100.00
------------------------------------				
*/

*2:  _2345 6_	
forval i=2011/2015 {
replace married`i'=married2010 if m==2 & married`i'==. &  married2010==0
}

*3:_234_ __; 4: _2___ __
forval i=2011/2013 {
replace married`i'=married2010 if inlist(m,3,4) & married`i'==. &  married2010==0
}

*6: ___45 6_ ; 7:___4_ __
forval i=2013/2015 {
replace married`i'=married2012 if inlist(m,6,7) & married`i'==. &  married2010==0
}

*9:_____ 6_ 
replace married2015=married2014 if inlist(m,9) & married2015==.  &  married2010==0

misschk married* if married2010==0


keep pid married* marstat* mar_ymin mardate mar_min interv_10a interv_12a interv_14a interv_16a
save "${datadir}\marr_EHC.dta", replace 




*calculate sample median age
use "${datadir}\marr_EHC.dta", clear
merge 1:1 pid using "${datadir}\panel_1016.dta", nogen 
*married ppl at the same study cohort 
keep if marstat10==1  
keep if age>=20 & age<=45  // N=1565

*calculate age at marriage 
format mar_min %tm

g birth=ym(birthy_best,birthm_cross) if birthm_cross>0  // N=3 missing 
drop if birth==.
format birth %tm

g mar_age=int((mar_min-birth)/12)

bysort male: sum  mar_age  if  mar_age>10 & mar_age<=45,detail



*some fragmented codes  about calculating median year of married : keep for now 
//
// *breakdown by hukou/gender
// g urbanhukou10=(hukou10_10a==3)
//
// egen gr=group(urbanhukou10 male)
// la def gr 1"non-urban hukou, female" 2"non-urban hukou, male" 3"urban hukou, female" 4"urban hukou male", modify 
// la val gr gr 	
//
// histogram mar_age if mar_age>10 & mar_age<=45, by (gr) 
//
// sum mar_ageyr if mar_age>10 & mar_age<=45
//
// bysort male: sum mar_ageyr,detail
// bysort urbanhukou10 male : egen marage_median1=median(mar_ageyr) // 22:rural female, 23:rural male , 24: urban male, 25:urban female
// bysort urbanhukou10 male : egen marage_q75=pctile(mar_ageyr)  ,p(75)
//
// bysort male: sum mar_ageyr, detail
//
//
// tab gr marage_median1 
// tab gr marage_q75 

*conclusion : interval missing are due to those imputed later using marital status at the time of the survey
erase "${datadir}\mar_temp.dta"
erase "${datadir}\mar2wave_temp.dta"
