#!/usr/bin/env Rscript
# File to run simulated data

# Get arguments
# date <- commandArgs(TRUE)[1]
# typesim1 <- commandArgs(TRUE)[2]
# iter1 <- as.numeric(commandArgs(TRUE)[3])
# notes1 <- commandArgs(TRUE)[4]
# keeps1 <- commandArgs(TRUE)[5]
# run <- as.numeric(commandArgs(TRUE)[6])


date <- "30jul21"
typesim1 <- "local3"
iter1 <- 100000
notes1 <- "local3 joint: fix length vfl"
keeps1 <- "all"
run <- 1

resdir <- paste0("results-", date)
filen <- paste0("joint-", date, "-", typesim1, ".RData")

library(here)

# get seeds
set.seed(37474)
seeds <- sample(seq(1, 100000), 100 * 3, replace = T)
seeds <- matrix(seeds, nrow = 100)
seeds <- seeds[run, ]

# make folder if doesn't exist
if(!(resdir %in% list.files())) {
  system(paste0("mkdir ", resdir))
}

if(!("logs" %in% list.files())) {
  system("mkdir logs")
}



# load libraries
library(stansa)
# pipe load not working
library(magrittr)


# load simulation data
data(prof)
data(meansd)
data(meansdlog)

# Will not work if vFl = 0
load(here("data/prof.RData"))

load(here("data/meansdlog.RData"))


cores1 <- parallel::detectCores()

# Run
stanres <- runstan(notes = notes1,
                   iter = iter1, N = c(200, 200),
                   #stancode = "https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/stan-sa-inform-scale-y.stan",
                   stancode = "~/Documents/git/gestdc-sa-stan/stan-sa-joint-diffL.stan",
                   # refers to whether using ambient
                   stantype = "joint",
                   prof = prof,
                   meansd = meansdlog,
                   typesim = typesim1,
                   sderr = NULL, seeds = seeds,
                   cores = cores1,
                   chains = 1, keep = keeps1, fp = file.path(resdir, filen), log1 = T,
                   control = list(adapt_delta = 0.95, max_treedepth = 15), names = F)
# for local 1: adapt_delta (target acccept increase) to 0.98
save(stanres, file = (file.path(resdir, filen)))


## Plot results 
#load(here("rcode-sim/results-2dec20/inform-2dec20-local3.RData"))
# x <- Sys.time()
# plots <- plotstan(prof = prof, meansd = meansdlog, typesim =  typesim1,
#                   stanres = stanres, dirname = resdir, pdf = T)


source("~/Documents/git/stansa/R/plot-res.R")

# ambient/local1
plotsL <- plotstan(prof = prof, meansd = meansd, typesim =  typesim1,
                  stanres = stanres, dirname = resdir, pdf = T, hten = 350, wdbi = 20, typeplot = "local")

plotsA <- plotstan(prof = prof, meansd = meansd, typesim =  typesim1,
                  stanres = stanres, dirname = resdir, pdf = T, hten = 350, wdbi = 20,
                  typeplot = "ambient")



filename1 <- paste0(typesim1,"-pairs-joint.pdf")
pdf(here::here(resdir, filename1))
pairs(stanres$fit, pars = c("muga", "mugl", "sigmaga", "sigmagl"), condition = "energy")
dev.off()





# y <- Sys.time()
# cov1 <- rescoverage(prof = prof, meansd = meansd, typesim =  typesim1,
#                   stanres = stanres)
# dplyr::filter(cov1, coverage != 1) %>% dplyr::ungroup() %>% dplyr::count(var1)
# dplyr::ungroup(cov1) %>% dplyr::summarize(., mean(coverage))


# Other diagnostics
# library(bayesplot)
# mcmc_nuts_energy(nuts_params(stanres$fit))
# mcmc_nuts_divergence(nuts_params(stanres$fit), log_posterior(stanres$fit))
# my_sso <- launch_shinystan(stanres$fit)
