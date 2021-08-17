#!/usr/bin/env Rscript
# File to run simulated data 

# Get arguments
date <- commandArgs(TRUE)[1]
typesim1 <- commandArgs(TRUE)[2]
iter1 <- as.numeric(commandArgs(TRUE)[3])
notes1 <- commandArgs(TRUE)[4]
keeps1 <- commandArgs(TRUE)[5]
run <- as.numeric(commandArgs(TRUE)[6])

resdir <- paste0("results-", date)
filen <- paste0("informprior-", date, "-", typesim1, ".RData")

library(here)

# load seeds
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
data(meansdlog)

cores1 <- parallel::detectCores()

# Run
stanres <- runstan(notes = notes1, 
                   iter = iter1, N = 200,
                   # stancode = "https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/stan-sa-inform-scale-y.stan",
                   stancode = "~/Documents/git/gestdc-sa-stan/stan-sa-inform-fixg.stan",
                   
                   # refers to whether using ambient
                   stantype = "noninform",
                   prof = prof, 
                   meansd = meansdlog, 
                   typesim = typesim1,
                   sderr = NULL, seeds = seeds,
                   cores = cores1,
                   chains = 1, keep = keeps1, fp = file.path(resdir, filen), log1 = T,
                   control = list(adapt_delta = 0.95, max_treedepth = 15), names = T)
save(stanres, file = (file.path(resdir, filen)))

plots <- plotstan(prof = prof, meansd = meansdlog, typesim =  typesim1,
                  stanres = stanres, dirname = resdir, pdf = T, hten = 350, wdbi = 20)




## Plot results
#load(here("rcode-sim/results-2dec20/inform-2dec20-local3.RData"))
# plots <- plotstan(prof = prof, meansd = meansd, typesim =  typesim1,
#                   stanres = stanres, dirname = resdir, pdf = T)

# Other diagnostics
# library(bayesplot)
# mcmc_nuts_energy(nuts_params(stanres$fit))
# mcmc_nuts_divergence(nuts_params(stanres$fit), log_posterior(stanres$fit))
# my_sso <- launch_shinystan(stanres$fit)
