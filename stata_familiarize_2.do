// to execute a do file quietly (=run), use shift+cmd+r
// to execute a do file and show output (=do), use shift+cmd+d

// if you select a code junk and use do/run, only the selected junk will be executed
// there is a thing called review window. It's the history of commands and is selectable.
// However, it looks as output is invisible.
"hewnew2

clear
cd "/Users/lorenz/Documents/CORC/Stata" // set working derectory
insheet using "/Users/lorenz/Documents/CORC/Stata/mtcarsForStata.csv" // read csv
edit // opens editor
browse /* opens browser. If no variables are indicated after the command, stata 
assumes that you mean all variables */
browse cyl 
browse cyl if hp == 110
browse cyl in 4/6 // open observation 4 to 6.

sum cyl // create summary statistic. same as
summarize cyl

sum cyl hp gear // creates multiple summaries
sum * // summarizes all

// generating new vars with a loop
// (not that meanginful in this context though since they are all the same).

local newvars var1 var2 var3 var4
foreach var in `newvars'{
gen `var' = cond(wt == 1, 0, 9)
}

gen v2 = cond(cyl > 6, 1, 0) // create a new variable without a loop

drop var1-var3 // select multiple variables a time




// EXPLORATORY DATA ANALYSIS 

// tables 
// group summary of carb by cyl
sort cyl
by cyl: summarize carb
inspect hp // get overview of hp
codebook mpg // summarieze in another way
tab am gear // two way table
describe

/// sumary for a subgroup

summarize mpg if cyl > 5



// aggregate data
/// when aggreagting data, we lose some information. Hence, we use preserve
/// and restore to get the data back. 
preserve // cache the data
contract cyl gear // aggregate the data and show all combinations of cyl and gear along with their frequency

restore // restore the cached data


// visuals
/// histogram
hist gear
hist gear, by(cyl)

// scatter
scatter mpg hp, by(cly)


// scatter 
scatter gear hp cyl // multiple variables on y-axis


// bar
graph bar (mean) mpg, over(hp)

// in combination with contract 
/// show how many 
preserve
contract cyl
label variable _freq "Frequency" // apparently does not help
graph bar _freq, over(cyl) ytitle("Mean of Frequency")
restore 


// line
/// combining two line graphs
use http://www.stata-press.com/data/r12/uslifeexp.dta, clear
twoway line le_wm year || line le_bm year

gen dif = le_wm - le_bm
label var dif "Difference"
twoway (line le_wm year, yaxis(1 2) xaxis(1 2)) (line le_bm year) ///
(line dif year) (lfit dif year),  ytitle("", axis(2))
// quite too many axis labels. So let's reduce things
twoway (line le_wm year, yaxis(1 2) xaxis(1)) (line le_bm year) ///
(line dif year) (lfit dif year),  ///
ytitle("", axis(2)) ///
ytitle("Life Expectancy", axis(1)) ///
ylabel(0(10)20, axis(2) angle(horizontal)) /// specify axis distances and turn the angel of the label
legend( label(1 "White males") label(2 "Black males") ) // also, change the legend.


// markers in scatter

use http://www.stata-press.com/data/r12/lifeexp, clear

scatter lexp gnppc if popgrowth > 0, note("Includes only countries with positive population growth")
/// add colour option of the marker
scatter lexp gnppc if popgrowth > 0, mcolor(green) note("Includes only countries with positive population growth")

/// colour by group of growth
separate lexp, by(positive_growth) // first create new variable
twoway scatter lexp0 lexp1 gnppc

// more flexible, including different symbols
twoway scatter lexp gnppc if popgrowth < 0, mcolor(orange) msymbol(Oh) || ///
scatter lexp gnppc if popgrowth > 0, mcolor(green) msymbol(S) || ///
, note("Includes only countries with positive population growth")

/// adding marker_labels



gen positive_growth = cond(popgrowth >0, 1, 0)
scatter lexp positive_growth  gnppc

// variables
// simple example of saving a graph
graph box gear
graph export anothergraph.png, as(png)

// now do graphs for three objects
local temp_things cyl hp gear // 3_temp_things only stroed until do file is executed
global perm_things cyl hp gear // 3_perm_things stroed until stata is closed. 
// HOWEVER GLOBALS DON'T SEEMS TO WORK HERE

foreach var in `temp_things'{ 
graph box `var', saving(`var', replace)
}

foreach var in `temp_things'{ 
graph box `var'
graph export `var'.png, as(png) replace
}
di `temp_things'



// label data 
/// label the variable name
gen var6 = cyl
label variable var6 "the cylinder variable"

/// label the values
label define cyllabel2 4 "four cylinders" 6 "six cylinders" 8 "eight cylinders"
label values var6 cyllabel2

