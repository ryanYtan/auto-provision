# TAP GIG Assessment 1

Automated Deployment of Cloud Resources

## Architecture
![](https://github.com/ryanYtan/auto-provision/blob/master/architecture.png?raw=true)

## Instructions for Deployment
Download AWS CLI and check if it's installed
```bash
$ aws --version
aws-cli/1.29.52 Python/3.8.10 Linux/5.10.16.3-microsoft-standard-WSL2 botocore/1.31.52
```
Configure AWS credentials
```
aws configure
```
An initial setting up of the remote infrastructure (mainly an S3 bucket for
handling TF state) must be done first. Do this by going into `remote-state`:
```bash
cd infrastructure/remote-state
terraform init
terraform plan
terraform apply
```
To deploy the infrastructure to AWS
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```
If a new image was pushed, redeploy the tasks by running
```bash
./deploy.sh
```
