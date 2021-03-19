#!/usr/bin/env Rscript
# File to set up EC-2

# for Rstan
Sys.setenv(DOWNLOAD_STATIC_LIBV8 = 1) 
install.packages("rstan", repos = "https://cloud.r-project.org/", dependencies = TRUE)

# Install loggr/stansa
install.packages("remotes")
remotes::install_github("mike-lawrence/loggr")
remotes::install_github("kralljr/stansa")