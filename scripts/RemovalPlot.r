args <- commandArgs(TRUE)

## args[1] : .gene.rate.info file
## args[2] : output plot, in pdf format

data <- read.table(args[1],header=T,row.names=1)

pdf(args[2])
par(mfrow=c(5,1))

for(m in ((ncol(data)-3)/2+4):ncol(data)){
	to.plot <- data[which(data[,m]==0),1:2]
	each.out <- apply(to.plot,1,function(invec){seq(invec[1],invec[2],by=1)})
	my <- c(unlist(each.out))
	plot(my,rep(1,length(my)),type="h",col="grey",xlim=c(1,data[nrow(data),2]),ylim=c(0,1),xlab="",ylab="",yaxt='n',main=colnames(data)[m-(ncol(data)-3)/2])
}

dev.off()
