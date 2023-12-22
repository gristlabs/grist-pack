A set of scripts and utilites to prepare AMI image for AWS Marketplace. 

git clone this repository onto EC2 Ubuntu instance, and run `sudo bash installGristFiles`

When any changes are made to dex.yaml or gristParameters, `/etc/restartGrist clean` should be called to whipe out dex and grist databases