#!/bin/sh
sudo amazon-linux-extras install "R4"
sudo yum install clang
sudo yum install curl-devel
wget https://raw.githubusercontent.com/kralljr/gestdc-sa-stan/main/sim-run-base.R