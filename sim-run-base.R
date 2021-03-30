#!/usr/bin/env Rscript
# File to run simulated data 

# Get arguments
date <- commandArgs(TRUE)[1]
typesim1 <- commandArgs(TRUE)[2]
iter1 <- as.numeric(commandArgs(TRUE)[3])
notes1 <- commandArgs(TRUE)[4]
keeps1 <- commandArgs(TRUE)[5]

resdir <- paste0("results-", date)
filen <- paste0("informprior-", date, "-", typesim1, ".RData")

library(here)

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



# Run
stanres <- runstan(notes = notes1, 
                   iter = iter1, N = 200,
                   stancode = "https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/stan-sa-inform-scale-y.stan",
                   # refers to whether using ambient
                   stantype = "noninform",
                   prof = prof, 
                   meansd = meansd, 
                   typesim = typesim1,
                   sderr = 0.01, cores = 2,
                   chains = 1, keepall = keeps1, fp = file.path(resdir, filen),
                   control = list(adapt_delta = 0.99, max_treedepth = 15))
save(stanres, file = (file.path(resdir, filen)))


## Plot results
#load(here("rcode-sim/results-2dec20/inform-2dec20-local3.RData"))
# plots <- plotstan(prof = prof, meansd = meansd, typesim =  typesim1,
#                   stanres = stanres, dirname = resdir, pdf = T)

# Other diagnostics
# library(bayesplot)
# mcmc_nuts_energy(nuts_params(stanres$fit))
# mcmc_nuts_divergence(nuts_params(stanres$fit), log_posterior(stanres$fit))
# my_sso <- launch_shinystan(stanres$fit)
