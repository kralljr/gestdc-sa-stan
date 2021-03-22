#!/bin/sh
sudo yum update-y
sudo amazon-linux-extras install "R4" -y
sudo yum install clang -y
sudo yum install curl-devel -y
wget https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/sim-run-base.R
chmod +x sim-run-base.R
wget https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/setup-ec2.R
chmod +x setup-ec2.R
mkdir R/
mkdir R/x86_64-koji-linux-gnu-library/
mkdir R/x86_64-koji-linux-gnu-library/4.0/
Rscript setup-ec2.R
