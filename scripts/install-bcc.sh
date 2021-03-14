#!/bin/bash

set -eux

# install make
sudo apt-get update
sudo apt-get -y install make

# install python 3.8
sudo apt-get install -y python3
sudo apt-get install -y python-is-python3
sudo apt-get install -y python3-pip

# install bcc
sudo apt-get install -y bpfcc-tools "linux-headers-$(uname -r)"

# install bazelisk
sudo curl -Lo /usr/local/bin/bazel https://github.com/bazelbuild/bazelisk/releases/download/v1.7.5/bazelisk-linux-amd64
sudo chmod +x /usr/local/bin/bazel
