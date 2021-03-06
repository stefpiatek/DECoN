options(na.action=na.exclude) # preserve missings
options(contrasts=c('contr.treatment', 'contr.poly')) #ensure constrast type
library(survival)

#
# Test out the revised model.matrix code
#
test1 <- data.frame(time=  c(9, 3,1,1,6,6,8),
                    status=c(1,NA,1,0,1,1,0),
                    x=     c(0, 2,1,1,1,0,0),
                    z= factor(c('a', 'a', 'b', 'b', 'c', 'c', 'a')))

fit1 <- coxph(Surv(time, status) ~ z, test1, iter=1)
fit2 <- coxph(Surv(time, status) ~z, test1, x=T, iter=1)
all.equal(model.matrix(fit1), fit2$x)

# This has no level 'b', make sure dummies recode properly
test2 <- data.frame(time=  c(9, 3,1,1,6,6,8),
                    status=c(1,NA,1,0,1,1,0),
                    x=     c(0, 2,1,1,1,0,0),
                    z= factor(c('a', 'a', 'a', 'a', 'c', 'c', 'a')))

ftest <- model.frame(fit1, data=test2)
all.equal(levels(ftest$z), levels(test1$z))

# xtest will have one more row than the others, since it does not delete
#  the observation with a missing value for status
xtest <- model.matrix(fit1, data=test2)
dummy <- fit2$x
dummy[,1] <- 0
all.equal(xtest[-2,], dummy, check.attributes=FALSE)

# The case of a strata by factor interaction
#  Use iter=0 since there are too many covariates and it won't converge
test1$x2 <- factor(rep(1:2, length=7))
fit3 <- coxph(Surv(time, status) ~ strata(x2)*z, test1, iter=0)
xx <- model.matrix(fit3)
all.equal(attr(xx, "assign"), c(2,2,3,3))
all.equal(colnames(xx), c("zb", "zc", "strata(x2)x2=2:zb",
                          "strata(x2)x2=2:zc"))
all.equal(attr(xx, "contrasts"), 
          list("strata(x2)"= "contr.treatment", z="contr.treatment"))

fit3b <-   coxph(Surv(time, status) ~ strata(x2)*z, test1, iter=0, x=TRUE)
all.equal(fit3b$x, xx)


# A model with  a tt term
fit4 <- coxph(Surv(time, status) ~ tt(x) + x, test1, iter=0,
              tt = function(x, t, ...) x*t)
ff <- model.frame(fit4)
# There is 1 subject in the final risk set, 4 at risk at time 6, 6 at time 1
# The .strata. variable numbers from last time point to first
all.equal(ff$.strata., rep(1:3, c(1, 4,6)))
all.equal(ff[["tt(x)"]], ff$x* c(9,6,1)[ff$.strata.])

xx <- model.matrix(fit4)
all.equal(xx[,1], ff[[2]], check.attributes=FALSE)

