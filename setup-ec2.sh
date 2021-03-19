#!/bin/sh
sudo amazon-linux-extras install "R4"
sudo yum install clang
sudo yum install curl-devel
wget https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/sim-run-base.R
chmod +x sim-run-base.R
wget https://github.com/kralljr/gestdc-sa-stan/blob/main/setup-ec2.R
chmod +x setup-ec2.R
Rscript setup-ec2.R
