
# install gpiper package (we do this every time because the package is currently evolving...)
install.packages("gpiper_0.1.zip", repos=NULL)

# then load the package
library(gpiper)



# get the blueback
a <- read.csv("Blueback in river - Palkovacs ONLY with nulls and 2012 SJR removed.csv", as.is=T)
a <- data.frame(ID=gsub("_", "", a$Drainage.code), a, stringsAsFactors=F)  # get the column that we want for the IDs in there, remove the underscores.

# drop populations that have fewer than 9 individuals
tmp <- table(gsub("[0-9]", "", a$ID))
a1 <- a[ gsub("[0-9]", "", a$ID) %in% names(tmp[tmp>=9]), ]  # this eliminates 1 fish from MIR


# now retain just the columns we want
a2 <- a1[,c(1,15:40)] # this was for the nulls removed no McBride only loci
names(a2)[2:ncol(a2)][c(F,T)] <- names(a2)[2:ncol(a2)][c(T,F)] # get the locus names on each column
names(a2)[1] <- ""  # remove the "ID" name


## Here we put it into gpipe format
# turn missing data to 0
a2[is.na(a2)] <- 0

# make the ID the rownames and then toss that column
rownames(a2) <- a2[,1]
a2 <- a2[,-1]



# then we should be able to write out a gsi_sim file easily
# get the pops we want in the order we want them:
the.pops <- gsub("[0-9]*", "", rownames(a2))
the.pops.f <- factor(the.pops, levels=unique(the.pops))

############################################################################
# let's look at patterns of non-genotyped loci across populations
psd <- split(a2, the.pops.f)
NonGenoTable <- sapply(psd, function(x) {
	lapply(seq(1,ncol(x), by=2), function(y) mean(c(x[[y]], x[[y+1]])==0) )
  }
)
rownames(NonGenoTable) <- names(a2)[c(T,F)]
num.non.genod.pops <- apply(NonGenoTable, 1, function(x) sum(x==1)) # here are the number of pops missing all data by locus

# here are the loci that are typed in all populations
full.data.loci <- paste(rep(names(num.non.genod.pops)[num.non.genod.pops==0],each=2), c("", ".1"), sep="")

# select just the full data loci:
#a2 <- a2[, full.data.loci]
##########################################################################################

# make a gsi_sim input file:
gPdf2gsi.sim(a2, the.pops.f)

# and then run that file:
gsi_Run_gsi_sim("-b gsi_sim_file.txt --self-assign")

# and get the self assignment results
SA <- gsi.simSelfAss2DF(file="GSI_SIM_Dumpola.txt")$Post

# figure out the max assignments to population:
MC <- gsi_simMaxColumnAndPost(SA,-c(1,2))  # dropping the first two columns here because they are not assignment posteriors

# then, here are our assignment matrices to population
topop<- gsi_simAssTableVariousCutoffs(SA$PopulationOfOrigin, MC$MaxColumn, MC$MaxPosterior)




# let us explore aggregating assignments by reporting unit
rg <- read.table("blueback-4-grps.txt", header=T, row=1)
rg.f <- factor(rg$RepGroup, levels=unique(rg$RepGroup))

# and get the self assignment to reporting units results
SA.rg <- gsi_aggScoresByRepUnit(SA, levels(the.pops.f), rg.f)  # here are the assignment values by reporting group

# figure out the max assignments to reporting unit:
MC.rg <- gsi_simMaxColumnAndPost(SA.rg,-c(1,2))

# then, here are our assignment matrices to reporting unit
toprg <- gsi_simAssTableVariousCutoffs(SA.rg$PopulationOfOrigin, MC.rg$MaxColumn, MC.rg$MaxPosterior)


#Export assignment matrices for additional analyses:
write.csv(topop,"1a. Blueback self assignment matrices to population - Palkovacs ONLY.csv")
write.csv(toprg,"2a. Blueback self assignment matrices to reporting group - Palkovacs ONLY.csv")


save(toprg, file= "Blueback toprg.R")




# here we summarize the number of correct assignments to population
yy <- t(sapply(topop, function(x) diag(x$AssTable)))
CorAssTabpop <- cbind(NumAssigned=sapply(topop, function(x) x$NumAssigned), yy, N.Correct=rowSums(yy))

# here are the cutoffs
cutspop <- as.numeric(sapply(strsplit(rownames(CorAssTabpop), "_"), function(x) x[2]))

#Export the matrix of correct self-assignments to population
write.csv(CorAssTabpop,"Blueback self assignment to population with increasing stringency.csv")





###################################################################################################################
#######THIS IS WRONG AND WILL NEED TO BE FIXED#######
# here we summarize the number of correct assignments to reporting group
zz <- t(sapply(toprg, function(x) diag(x$AssTable)))
CorAssTabprg <- cbind(NumAssigned=sapply(toprg, function(x) x$NumAssigned), zz, N.Correct=rowSums(zz))

# here are the cutoffs
cutsprg <- as.numeric(sapply(strsplit(rownames(CorAssTabprg), "_"), function(x) x[2]))

#Export the matrix of correct self-assignments to reporting group
write.csv(CorAssTabprg,"Blueback self assignment to reporting group with increasing stringency.csv")
####################################################################################################################




#### Here we start messing around with making a cool plot####
# if I were to fiddle around with making an interesting plot:
x<-topop[[1]]$AssTable  # this is using cutoff of 0
maxes <- apply(x,1,max)
sum.maxes <- sum(maxes)

# here is the rightward position to start each population
starts <- c(0,cumsum(maxes/sum.maxes))[-(length(maxes)+1)]
names(starts) <- names(maxes)  # these are the right hand start points
fish.x <- .9/sum.maxes   # this is the amount of x space each assigned fish equates to.

#####I think lat.table does not work b/c my file has lats and longs in it; how do I isolate the latitude column?######
lat.table <- read.table("Blueback lats and longs.txt", header=T, row=1)
lats <-lat.table[names(starts), 1] # latitudes of rivers as ordered in starts

rg.colors <- c("blue", "violet", "green", "orange")

plot(starts, lats, type="n")
abline(v=starts, lty="dotted", lwd=.1)

lapply(1:nrow(x), function(r) {
  z<-x[r,]
  the.col <- rg.colors[rg.f[r]]
  xx0<-starts[r]
  yy<-lats[z>0]
  xx1<-starts[r] + z[z>0]*fish.x
  segments(xx0, yy, xx1, yy, lend=1, col=rg.colors[rg.f[z>0]]) # this is if we want the destinations colored by reporting group
  #segments(xx0, yy, xx1, yy, lend=1, col=the.col)  # this is if we want the sources colored by reporting group
}
)



###################  And here we have our stacked barplot of self-assignment to stock
dan.col <- c("red", "blue", "green", "yellow")
x<-t(toprg[[1]]$AssTable)  # this is using cutoff of 0
y <- x[,rev(1:ncol(x))]  # get them in the right order

yp <- apply(y, 2, function(x) x/sum(x))

par(mar=c(2,7,.3,2))
barplot(yp, horiz=T, col=dan.col, las=1, names.arg=paste(colnames(yp), " (",colSums(y) ,")"))
dev.copy2pdf(file="blueback-stacked barplot self-assignment to stock - Palkovacs ONLY.pdf")



################### And here we have our stacked barplot of self-assignment to population
dan.col2 <- c("red", "red3", "red4", "blue", "blue4", "dodgerblue", "green", "green3", "green4", "greenyellow", 
              "darkgreen", "darkolivegreen2", "lawngreen", "forestgreen", "springgreen2", "seagreen1",
              "yellow", "yellow3", "yellow4", "khaki", "gold")
x1<-t(topop[[1]]$AssTable)  # this is using cutoff of 0
y1 <- x1[,rev(1:ncol(x1))]  # get them in the right order

yp <- apply(y1, 2, function(x1) x1/sum(x1))

par(mar=c(2,7,.3,2))
barplot(yp, horiz=T, col=dan.col2, las=1, names.arg=paste(colnames(yp), " (",colSums(y1) ,")"))
dev.copy2pdf(file="blueback-stacked barplot self-assignment to population - Palkovacs ONLY.pdf")




####################################################################################################
####################################################################################################
####
#### NOW WE MOVE ON TO THE BYCATCH
####
####################################################################################################
####################################################################################################

# read in the bycatch data.  Note that I had to mess with the data quite a bit.  There where 
# degree symbols which are multibyte, and the quoting was gnarly because some of the lat-longs
# were in minutes and seconds.  I ended up replacing all """ with " and all ' with nothing and 
# all weird degree symbols with nothing.  I should be able to parse it all out at some point.
byc <- read.csv("1a. Blueback herring bycatch - minimum 6 loci no nulls.csv", stringsAsFactors=F)

# hard-wired here to put the locus headers in there:
names(byc)[seq(16,40,by=2)] <- paste(names(byc)[seq(15,39,by=2)], "1", sep=".")

# here are the indices of those loci:
byc.loc.idx <- 15:40

# now, make a baseline data set that includes only those loci, and is assured to be in the 
# correct order
byc.base <- a2[,names(byc)[byc.loc.idx]]

# now, let's do a run on everybody together just to test.
# so, make a gPiper.data.frame out of it and then turn it to a 
# gsi_sim input file.  There is a bit of a problem in that the
# Sample.ID's are duplicated for a lot of the fish in byc.  For now
# we will just toss those out:
byc.gp <- byc[,byc.loc.idx]
rownames(byc.gp) <- byc$Sample.ID 
byc.gp[is.na(byc.gp)] <- 0  # put 0's in for missing data
gPdf2gsi.sim(byc.gp, outfile="all-bycatch.txt")
gPdf2gsi.sim(byc.base, pop.ize.them=the.pops.f, outfile="baseline-for-bycatch.txt")

gsi_WriteReportingUnitsFile(rownames(rg), rg$RepGroup, repufile="bb_rep_units.txt")  # make a gsi_sim reporting units file


# now run gsi_sim
gsi_Run_gsi_sim("-b baseline-for-bycatch.txt -t all-bycatch.txt -r bb_rep_units.txt  --mcmc-sweeps 10000 --mcmc-burnin 5000 --pi-trace-interval 1")


# looking at some results.
# here are Pi histograms:
dev.off()
PiTrace <- read.table("rep_unit_pi_trace.txt", header=T)
PiDens <- lapply(PiTrace[-1], function(x) density(x))
plot(0:1, c(0, max(unlist(lapply(PiDens, function(z) z$y)))), type="n", xlab="Proportion of Bycatch", ylab="Posterior Density")
i<-0
lapply(PiDens, function(z) {i<<-i+1; lines(z$x, z$y, col=c("green", "red", "blue", "yellow")[i])})
legend("topright", legend=names(PiDens), col=c("green", "red", "blue", "yellow"), lwd=1)

dev.copy2pdf(file="blueback-all-bycatch-pi.pdf")


#Now examine probabilities of assignments to stock of origin
repunitfull<-read.table("rep_unit_pofz_full_em_mle.txt", header=T)
head(repunitfull)

repunitposteriormean<-read.table("rep_unit_pofz_posterior_means.txt", header=T)
head(repunitposteriormean)



##Here we are looking for associations between  Year, Season, Region, and Target Fishery to determine how best to
##assign alewife and blueback herring bycatch to stock of origin
##Started by Dan Hasselman, March 11, 2014
library(plyr)

#Read in the bycatch data for BLUEBACK HERRING
blueback <- read.csv("1a. Blueback herring bycatch - minimum 6 loci no nulls.csv", as.is=T)

#Look at how blueback bycatch is parsed by Year, Season, region (stat areas, following Bethoney et al. 2014), fishery and gear type
blueback_Yr <- count(blueback, c("Year"))
blueback_Yr_Season <- count(blueback, c("Year", "Season"))
blueback_Yr_Season_Region <- count(blueback, c("Year", "Season", "Region"))
blueback_Yr_Season_Region_Fishery <- count(blueback, c("Year", "Season", "Region", "Target.Fishery"))
blueback_Yr_Season_Region_Fishery_Gear <- count(blueback, c("Year", "Season", "Region", "Target.Fishery","Gear.Type"))

#Export these groupings
write.csv(blueback_Yr,"Blueback bycatch by year.csv")
write.csv(blueback_Yr_Season,"Blueback bycatch by year season.csv")
write.csv(blueback_Yr_Season_Region,"Blueback bycatch by year season region.csv")
write.csv(blueback_Yr_Season_Region_Fishery,"Blueback bycatch by year season region fishery.csv")
write.csv(blueback_Yr_Season_Region_Fishery_Gear,"Blueback bycatch by year season region fishery gear.csv")

count(blueback, c("Target.Fishery"))
names(blueback)
blueback1 <- blueback[,c(2, 5, 6, 9, 10, 12)]
names(blueback1)

#Isolate blueback herring caught as bycatch in Atlantic Herring fishery
blueback2 <- blueback1[blueback1$Target.Fishery == "Atlantic Herring", ]

#Look for a correlation between [Year x Season x Region] with Target.Fishery with the 'stats' package
blueback.df <- data.frame(count(blueback, c("Year", "Season", "Region")))
blueback.df
is.numeric(blueback.df$freq)

cor(blueback.df$Year, blueback.df$freq)
####This is where I stopped for blueback (April 2, 2014)

