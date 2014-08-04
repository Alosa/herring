# Herring

This is an R package that is currently under development.
It contains code and data useful for doing genetic stock identification of 
herring species on the east coast.  

It is currently under development.  


## Terms 

As a work partially of the United States Government, the R code and the binaries in this
package are in the
public domain within the United States. Additionally, for the source code and binaries we waive
copyright and related rights in the work worldwide through the CC0 1.0
Universal public domain dedication.

The data included in this package are not works of the US Govt and are provided under
a different open source license that is yet to be determined.

See TERMS.md for more information.


## Replicating our results
This repository is designed so that our results can be replicated easily.  Here are the commands that you would use at an R prompt to do that:
```r
library(devtools)  # load this library.  If you don't have it: install.packages("devtools")

# install the R-package that is this library
install_github("herring", username = "eriqande")

# install the R package "gpiper" that is also needed
install_github("gpiper", username = "eriqande", ref = "36be155a")


# then source the analysis file like this:
# pdf()  # If running on a remote system without windowing, uncomment this line so the plots don't fail (Note, it won't make all of them pdf!)
source(system.file("analysis/compile-analysis.R", package = "herring"))

# that will end up running a fairly long time (30 to 60 minutes, maybe)because it does multiple runs of the chains 
# for the mixed fishery analyses.  Read the script to see what is going on in it.
# The script does write out four pdf files that will probably find their way to
# the supplement.  They are:
#
#    "alewife_zhists.pdf"                 :   histograms of the z-scores for fish from mixture vs from baseline for alewife 
#    "blueback_zhists.pdf"                :   histograms of the z-scores for fish from mixture vs from baseline for blueback 
#    "alewife-pi-comp-between-runs.pdf"   :   scatter plots showing posterior mean estimates of mixing proportions for 6 mcmc
#                                         :   runs plotted against first run for alewife
#    "blueback-pi-comp-between-runs.pdf"  :   scatter plots showing posterior mean estimates of mixing proportions for 6 mcmc
#                                         :   runs plotted against first run for blueback

```

