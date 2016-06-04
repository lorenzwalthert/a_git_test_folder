/*
This file deals with missing values and the like. It does the following:
	
	1. It handels missing values, conversion issues of certain characters, 
	dates and the like.
	2. It reduces the dataset to a given number of observations. This is
	necessary since after the import of the raw data, there are spare rows that
	later on add complications, especially when the value labels are created
	with the merge command in the labelling.do.

*/

******************* PRELIMINARIES *******************
version 12
clear
set more off


di in red "get_Data started" 
// globals
// setting some global variables
setgbl

// setting the working directory
cd "$wd"

******************* STEP 1: VARIABLE LABELS *******************
local path = $xlsxpathData
local insheet = "Raw Data/" + "`path'" + ".csv"
di "`insheet'"
insheet using "`insheet'", clear delimiter(";") case

******************* STEP 2: MISSING VALUES, CONVERSION ISSUES ******************
// generate a stata id that preserves the order of the rows

gen A_01STATA_ID = _n // add variable to keep order and 

****** drop rows that are essentially missing values only. *******
gen temp_number = _n
if $nobsvalidtot != 0 {
	keep if temp_number <= $nobsvalidtot
} // otherwise, keep all 
drop temp_number

****** drop columns that are essentially missing values only. *******
foreach v of var * {
	quietly count if !missing(`v')
	local nvalidobs `r(N)'
	if `nvalidobs' == 0 {
		drop `v'
		di as text "`v' was dropped since totally empty"
		local ninvalidvars = `ninvalidvars' + 1
	}
}
// error message at the end of the do file so it is more visible to the user.


// all variables
foreach v of var * {
	capture confirm string variable `v' 
	if _rc == 0 {
	
		// remove leading and trailing blanks
		replace `v' = strtrim(`v')
		// remove "years" or "year"
		replace `v' = regexr(`v', "years$", "")
		replace `v' = regexr(`v', "year$", "")
		
		// handling missing values
		replace `v' = "." if `v' == "n/a"
		replace `v' = "." if `v' == ""
		
		// conversion issues
		replace `v' = regexr(`v', "Ð", "-")
		replace `v' = regexr(`v', "-", "-")
		
		replace `v' = regexr(`v', "Õ", "'")

	}
}


************** specific variables  ************** 
// C08ID has some letters o wich should actually be 0's
replace C08ID = subinstr(C08, "O", "0", .)


// A08RespondentContact should be 10 digit or NA otherwise
replace A08RespondentContact = . if A08RespondentContact < 99999999 // zero 
// (the first digit) could not be captured since it is a numeric variable.


// Name Variables need to have every word starting with uppercase
local toproper A02Capturer A06RespondentName A07RespondentSurname ///
B09SpecifyOtherUse B20CfacOtherSpecify C06PersonName C07PersonSurname 

foreach v in `toproper' {
	replace `v' = proper(`v')
}

replace B20CfacOtherSpecify = "." if B20CfacOtherSpecify == "No" | ///
B20CfacOtherSpecify == "0"



// speific variables that have to do with money
unab exp: *Exp* // get all variables with _EXP_ in the maro
unab inc_all: *Inc* // get all variables with _INC_ in the maro
unab inc_excl: C16*
unab spnd: *Spend*
local structImpr P_STRC_IMP

local inc: list inc_all - inc_excl
local money: list exp | inc
local money: list money | spnd
local money: list money | structImpr
di "`money'"
foreach v in `money' {
	capture confirm string variable `v' 
	// if the variable is in the string format
	if _rc == 0 {
		replace `v' = subinstr(`v', " ", "", .) // remove blankets
		replace `v' = regexr(`v', "^R", "") 
		destring `v', replace
		
	}
}

// convert dates
ds
local orderit `r(varlist)'
unab dat_general: *Date*
local dat_add C09DoB
local dat: list dat_general | dat_add
foreach v in `dat' {
	// not quite sure what to do with these datevalid columns.
	split `v', parse(" ") 
	gen datevalid_`v' = regexm(`v', "[0-9]?[0-9]\.[0-9]?[0-9]\.[0-9]?[0-9]")
	drop `v'
	gen `v' = date(`v'1, "DMY", 2017)
	drop `v'2 `v'1
	drop datevalid_`v'
	format `v' %td
	
}
order `orderit'

// avoid scientific notation for some variables
local notscient C08
destring C08IDnumber, replace
foreach v in `notscient' {
	format `v' %50.0g
}



cd "Final Data"
save Data, replace
cd ..

// how many observations were kept? 
quietly describe
local nobs `r(N)'
di "`nobs'"
di in red "get_Data completed." _newline ///
"Inputpath for Index: $xlsxpathIndex" _newline ///
"Inputpath for Data:  $xlsxpathData" _newline(2) ///
"Only `nobs' observations were kept"
if `ninvalidvars' > 0 {
	di in red "`ninvalidvars' variables dropped since totally empty. " ///
		"Redo the do file and see text messages (hidden when file is " ///
		"executed via run) that indicate the variables affected."
		  
}	
