A set of scripts and utilites to prepare AMI image for AWS Marketplace. 

git clone this repository onto EC2 Ubuntu instance, and run `sudo bash installGristFiles`. It should distributed files across the system. There is a protection from overriding already existing files, so to override files we can use flags:
* force - enable "force mode" that will override selected files 
* rc - rc.local file 
* r - restartGrist file
* p - gristParamters file 
* d - dex.yaml file 
* a -  all files

after all files are distributed, use instruction from cleanup file. It is safer to just call them in shell one after another, instead run whole file.
1. Stop all containtes 
2. Cleanup grist database 
3. Remove git repository 
4. Remove ssh keys (amazon will bring them back while creating new image from AMI)
5. Remove shell commands history 

Before create AMI from EC2 be sure that it follow checklist: https://docs.aws.amazon.com/marketplace/latest/userguide/aws-marketplace-listing-checklist.html

AWS workflow to crete new version: 
1. Create new Ubuntu EC2 instance 
2. Log in to the console
3. Clone git repository and copy files according to instruction above 
4. Cleanup - WARNING - after this step you will no longer be able to log in to this particular EC2 instance, unless you create AMI and recreate instance, what whill bring ssh keys back 
5. Create AMI image - wait for API status to be ready before stopping / terminating instance
6. Validate: Create EC2 instance from newly created AMI image, check if you can login on public http adress, log in with default credentials, and if formula works and is sandboxes. Then log in to the instance and check if no git repo or shell commands history is persist from previous work. Then try to configure SSL, domain and google/ms OAuth credentials, check if it's working 
7. If everything is allright, go to the AWS seller portal and go to Product->Servers->Grist Omnibus 
8. Request Changes -> Update version -> Add new version 
9. Put the ID of your AMI image with new version. as AMI access role ARN you can use `AWS-Marketplace-AMI-Scanner-Role`. Check this role ID on https://us-east-1.console.aws.amazon.com/iam/home?region=us-east-1#/roles. Submit
10. Wait for review to be done




When any changes are made to dex.yaml or gristParameters, `/etc/restartGrist clean` should be called to wipe out dex and grist databases
