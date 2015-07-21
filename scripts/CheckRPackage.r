## This script aims at chacking the availability of R packages used in the pipeline

is.installed <- function(mypkg) is.element(mypkg, installed.packages()[,1])

one <- is.installed('ape')
two <- is.installed('vegan')
three <- is.installed('MASS')
four <- is.installed('car')

as.numeric(one && two && three && four)
