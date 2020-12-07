*set filepaths
global projectdir `c(pwd)'
di "$projectdir"
global outdir "$projectdir/output" 
di "$outdir"
global logdir "$projectdir/output/logs"
di "$logdir"
global tabfigdir "$projectdir/output/tabfig" 
di "$tabfigdir"

* Create directories required 
capture mkdir "$logdir"
capture mkdir "$tabfigdir"

global indexdate "2020-02-01"
di "$indexdate"
global last_data_date "2020-10-01"
di "$last_data_date"

adopath + "$projectdir/analysis/ado"
