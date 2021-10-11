#!/bin/sh

#echo "Usage: setup_prebuilt.sh <public-bucket-name> <private-bucket-name>"

PublicBucket=$1
PrivateBucket=$2

WORKDIR=`pwd`

aws s3 ls s3://${PublicBucket} > /dev/null 2>&1
retVal=$?
if [ $retVal -eq 254 -o $retVal -eq 255 ]
then
    aws s3api create-bucket --bucket ${PublicBucket} --acl public-read
fi
aws s3 ls s3://${PrivateBucket} > /dev/null 2>&1
retVal=$?
if [ $retVal -eq 254 -o $retVal -eq 255 ]
then
    aws s3api create-bucket --bucket ${PrivateBucket}
fi

if [ ! -d ~/environment/quickstart-progress-openedge ]
then
    cd ~/environment
    git clone --recurse-submodules https://github.com/progress/quickstart-progress-openedge.git
    cd ~/environment/quickstart-progress-openedge
    git checkout work-in-progress
fi

cd $WORKDIR
# Download Deployment Packages
rm -f db.tar.gz pas.tar.gz web.tar.gz
wget https://openedge-on-aws-workshop.s3.amazonaws.com/db.tar.gz
wget https://openedge-on-aws-workshop.s3.amazonaws.com/pas.tar.gz
wget https://openedge-on-aws-workshop.s3.amazonaws.com/web.tar.gz

# Add private files
tar xzvf db.tar.gz 
cp progress.cfg sshkey.pem app/
cp -r files_to_include/* app/
tar cvzf db.tar.gz app/
rm -rf app/

tar xzvf pas.tar.gz 
cp progress.cfg app/
tar cvzf pas.tar.gz app/
rm -rf app/

# Upload Deployment Packages to S3
aws s3 cp db.tar.gz s3://${PrivateBucket}/db.tar.gz 
aws s3 cp pas.tar.gz s3://${PrivateBucket}/pas.tar.gz 
aws s3 cp web.tar.gz s3://${PrivateBucket}/web.tar.gz 
