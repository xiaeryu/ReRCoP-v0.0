args <- commandArgs(TRUE)

# args[1] input matrix file. (gene.rate file)
# args[2] output matrix file. (gene.rate.info file)

## Packaged needed
library(MASS)	# for robust linear regression, rlm
library(car)	# for outlierTest

## Read in data
data <- read.table(args[1],header=T,row.names=1)
ent.rank <- rank(data[,3])

## Initialize output matrix
out.mat <- matrix(data=1,nrow=nrow(data),ncol=ncol(data)-3)
colnames(out.mat) <- paste(colnames(data)[4:ncol(data)],".preserve",sep="")

## Conduct outlier test
for(i in 4:ncol(data)){
	gene.rank <- rank(data[,i])
	out <- outlierTest(rlm(ent.rank~gene.rank),n.max=10000)
	out.name <- names(out$p)
	out.mat[as.numeric(out.name),i-4] <- 0
}
final.out <- cbind(data,out.mat)

## Output result
write.table(final.out, file=args[2],quote=F)
