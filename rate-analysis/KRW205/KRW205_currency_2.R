library(xts)
library(xtsExtra)

#currency <- read.csv('INR266.csv',stringsAsFactors = FALSE)
index <- read.csv('KRW205_currency.csv',stringsAsFactors = FALSE)

data <- index
dates <- data$Date
rates <- data[,-1]
dates <- as.POSIXct(dates,format ="%m/%d/%Y")
t <- as.xts(rates, order.by = dates)
# t <- diff(t)[-1,]
  # scale 
rate_name <- names(t)
span <- 0.1

tsoutliers <- function(x,plot=TRUE,span=0.1,name="",percentile = c(0.2,0.75),k=3,range = c(-1.1))
{
    # x <- as.ts(x)
    if(frequency(x)>1)
        resid <- stl(x,s.window="periodic",robust=TRUE)$time.series[,3]
    else
    {
        tt <- 1:length(x)
        #resid <- residuals(loess(x ~ tt,span=span))

        loe <- loess(x~tt, span = span)
    pred <- predict(loe,tt,se=TRUE)
    resid <- loe$residuals
    }


    # can adjust the parameters to control the outlier 
    resid.q <- quantile(resid,prob= percentile)
    iqr <- diff(resid.q)
    limits <- resid.q + k*iqr*range
    score <- pmin((resid-limits[1])/iqr,0) + pmax((resid - limits[2])/iqr,0)
    indicator <- ifelse(score==0,0,ifelse(score>0,1,-1))
    indi <- cbind(indicator,x)[,1]

    if(plot)
    {
        custom.panel <- function(index,x,...) {
        default.panel(index,x,...)
        points(x=index(indi[indi == 1]),
          y=x[,1][index(indi[indi == 1])],cex=0.9,pch=19,
          col="blue")
        points(x=index(indi[indi == -1]),
          y=x[,1][index(indi[indi == -1])],cex=0.9,pch=19,
          col="deeppink3")
          #abline(v=index(indi[indi == 1]),col="grey")
    }

      newlist <- list(score = score, resid = resid,indicator = indicator)
    plot.xts(x=cbind(x,fitted=loe$fitted,residual=loe$residuals),panel = custom.panel, screens = factor(1, 1), auto.legend = TRUE, main = paste("LOESS plot",rate_name[i],sep=" "))

        cat("Number of outliers for ",name," is ", sum(abs(indicator)),"\n")
        return(invisible(newlist))
    }
    else
        return(list(score,resid,indicator))
}


jpeg(file = " KRW205  currency LOESS plot %d.jpeg",quality=100,width = 1200, height = 800,units = 'px', pointsize = 12)

indi <- rep(0,nrow(t)) # initialize the indicator vector
indi.matrix <- matrix(0,nrow = nrow(t),ncol = ncol(t))
for (i in 1:ncol(t))
{
  a <- tsoutliers(t[,i],name = rate_name[i],span=span, percentile = c(0.2,0.9),k=3,range=c(-1,1))
# if any col in one raw has 1, label this row as 1
indi <- indi | a$indicator
indi.matrix[,i] <- a$indicator
}
dev.off()


indi <- cbind(indi,t)[,1]
num <- sum(abs(indi))
per <-num/nrow(t)

cat("\ntotal number of outliers is ", num)
cat("\npercentage of outliers is ",per)
# percenatge of potential outlier

jpeg(file = "KRW205 currency.jpeg",quality=100,width = 1200,height = 800,units = 'px', pointsize = 12)

# try to add points to show outlier
# index(indi[indi == 1]) get outlier
custom.panel <- function(index,x,...) {
  default.panel(index,x,...)
  abline(v=index(indi[indi == 1]),col=rgb(1,0,0,0.2),lwd=0.7)
  #abline(v=index(indi[indi == -1]),col=rgb(0,1,0,0.2),lwd=0.7)
  usr <- par( "usr" )
  text( usr[ 2 ], usr[ 4 ], paste("number of outliers: ",num,"\n","ratio: ",format(per,digits=4)),  adj = c( 1, 1 ), col = "blue",cex=1.5 )

}

plot.xts(t, screens = factor(1, 1), panel = custom.panel, auto.legend = TRUE, main = "KRW205 currency")
dev.off()


# get the indi.matrix 
# judge based on the 









# write the index into file
data <- cbind(indi,t)
data <- data.frame(date=index(data), coredata(data))
colnames(data)[2] <- "indicator" 
write.csv(data, file = "KRW205_currency_outlier.csv",row.names=TRUE)
