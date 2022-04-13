---
title: Terraform Iac Devops using AWS CodePipeline
description: Create AWS CodePipeline with Multiple Environments Dev and Staging
---
# IaC DevOps using AWS CodePipeline

## Step-00: Introduction
1. Terraform Backend with backend-config
2. How to create multiple environments related Pipeline with single TF Config files in Terraform ?
3. As part of Multiple environments we are going to create `dev` and `stag` environments
4. We are going to build IaC DevOps Pipelines using
- AWS CodeBuild
- AWS CodePipeline
- Github
5. We are going to streamline the `terraform-manifests` taken from `section-14` and streamline that to support Multiple environments.

[![Image](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-1.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-1.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-2.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-2.png)

[![Image](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-3.png "Terraform on AWS with IAC DevOps and SRE")](https://stacksimplify.com/course-images/terraform-aws-codepipeline-iac-devops-3.png)

## Step-01: Copy terraform-manifests from section-14
- Copy `terraform-manifests` from section-14 `14-Autoscaling-with-Launch-Templates`
- Update `private-key\terraform-key.pem` with your private key with same name.

## Step-02: c1-versions.tf - Terraform Backends
### Step-02-01: Add backend block as below.
```t
    # Adding Backend as S3 for Remote State Storage
    backend "s3" {}
```
### Step-02-02: Create file named `dev.conf`
```t
bucket = "terraformaws-forec2"
key = "iacdevops/dev/terraform.tfstate"
region = "us-east-1"
dynamodb_table = "iacdevops_dev_tfstate"
```
### Step-02-03: Create file named `stag.conf`
```t
bucket = "terraformaws-forec2"
key = "iacdevops/stag/terraform.tfstate"
region = "us-east-1"
dynamodb_table = "iacdevops_stag_tfstate"
```
### Step-02-04: Create S3 Bucket related folders for both environments for Terraform State Storage
- Go to Services -> S3 -> terraformaws-forec2
- Create Folder `iacdevops`
- Create Folder `iacdevops\dev`
- Create Folder `iacdevops\stag`

### Step-02-05: Create DynamoDB Tables for Both Environments for Terraform State Locking
- Create Dynamo DB Table for Dev Environment
  - **Table Name:** iacdevops_dev_tfstate
  - **Partition key (Primary Key):** LockID (Type as String)
  - **Table settings:** Use default settings (checked)
  - Click on **create**
- Create Dynamo DB Table for Staging Environment
  - **Table Name:** iacdevops_stag_tfstate
  - **Partition key (Primary Key):** LockID (Type as String)
  - **Table settings:** Use default settings (checked)
  - Click on **Create**

## Step-03: Pipeline Build Out - Decisions
- We have two options here.
### Step-03-01: Option-1: Create separate folders per environment and have same TF Config files (c1 to c13) maintained per environment
    - More work as we need to manage many environment related configs
    - Dev - c1 to c13 - Approximate 30 files
    - QA - c1 to c13 - Approximate 30 files
    - Stg - c1 to c13 - Approximate 30 files
    - Prd - c1 to c13 - Approximate 30 files
    - DR - C1 to c13 - Approximate 30 files
- Close to 150 files you need to manage changes
- For critical projects which you want to isolate as above, Terraform also recommends this approach but its all case to case basis on the environment we have built, skill level and organization level standards.

### Step-03-02: Option-2: Create only 1 folder and leverage same c1 to c13 files (approx 30 files) across environments.
    - Only 30 files to manage across Dev, QA, Staging, Production and DR environments.
    - We are going to take this `option-2` and build the pipeline for Dev and Staging environments

## Step-04: Merge vpc.auto.tfvars and ec2instance.auto.tfvars
- Merge `vpc.auto.tfvars` and `ec2instance.auto.tfvars` to environment specific `.tfvars` example `dev.tfvars` and `stag.tfvars`
- Also don't provide `.auto.` in `dev.tfvars` or `stag.tfvars` if we want to leverage same TF Config files across environments.
- We are going to pass the `.tfvars` file as `-var-file` argument to `terraform apply` command
```t
terraform apply -input=false -var-file=dev.tfvars -auto-approve
```
### Step-04-01: dev.tfvars
```t
# Environment
environment = "dev"
# VPC Variables
vpc_name = "myvpc"
vpc_cidr_block = "10.0.0.0/16"
vpc_availability_zones = ["us-east-1a","us-east-1b","us-east-1c"]
vpc_public_subnets = ["10.0.101.0/24","10.0.102.o/24","10.0.103.0/24"]
vpc_private_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
vpc_database_subnets = ["10.0.151.0/24","10.0.152.0/24","10.0.153.0/24"]
vpc_create_database_subnet_group = true
vpc_create_database_subnet_route_table = true
vpc_enable_nat_gateway = true
vpc_single_nat_gateway = true

# EC2 Instance Variables
instance_type = "t3.micro"
instance_keypair = "terraform-key"
private_instance_count = 2
```
### Step-04-01: stag.tfvars
```t
# Environment
environment = "stag"
# VPC Variables
vpc_name = "myvpc"
vpc_cidr_block = "10.0.0.0/16"
vpc_availability_zones = ["us-east-1a","us-east-1b","us-east-1c"]
vpc_public_subnets = ["10.0.101.0/24","10.0.102.o/24","10.0.103.0/24"]
vpc_private_subnets = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
vpc_database_subnets = ["10.0.151.0/24","10.0.152.0/24","10.0.153.0/24"]
vpc_create_database_subnet_group = true
vpc_create_database_subnet_route_table = true
vpc_enable_nat_gateway = true
vpc_single_nat_gateway = true

# EC2 Instance Variables
instane_type = "t3.micro"
instance_keypair = "terraform-key"
private_instance_count = 2
```
- Remove / Delete the following two files
  - vpc.auto.tfvars
  - ec2instance.auto.tfvars

## Step-05: terraform.tfvars
- `terraform.tfvars` which autoloads for all environment creations will have only generic variables.
```t
# Generic Variables
aws_region = "us-east-1"
business_division = "hr"
```


## Step-06: Remove local-exec Provisioners
### Step-06-01: c9-nullresource-provisioners.tf
- Remove Local Exec Provisioner which is not applicable in CodePipeline -> CodeBuild case.
```t
## Local Exec Provisioner: local-exec provisioner (Creation-Time Provisioner - Triggered during Create Resource)
provisioner "local-exec" {
    command = "echo Destroy time prov `date` >> destroy-time-prov.txt"
    working_dir = "local-exec-output-files/"
    when = destroy
    #on_failure = continue
}
```

## Step-07: To Support Multiple Environments
### Step-07-01: c5-03-securitygroup-bastionsg.tf
```t
# Before
  name = "public-bastion-sg"
# After
  name = "${local.name}-public-bastion-sg"
```
### Step-07-02: c5-04-securitygroup-privatesg.tf
```t
# Before
  name = "private-sg"
# After
  name = "${local.name}-private-sg"
```

### Step-07-03: c5-05-securitygroup-loadbalancersg.tf
```t
# Before
  name = "loadbalancer-sg"
# After
  name = "${local.name}-loadbalancer-sg"
```

### Step-07-04: Create Variable for DNS Name to support multiple environments
#### Step-07-04-01: c12-route53-dnsregistration.tf
```t
# DNS Name Input Variable
variable "dns_name" {
    description = "DNS Name to support multiple environments"
    type = string
}
```
#### Step-07-04-02: c12-route53-dnsregistration.tf
```t
resource "aws_route53_record" "apps_dns" {
    zone_id = data.aws_route53_zone.mydomain.zone_id
    name = var.dns_name
    type = "A"
    alias {
        name = module.alb.lb_dns_name
        zone_id = module.alb.lb_zone_id
        evaluate_target_health = true
    }
}
```
#### Step-07-04-03: dev.tfvars
```t
# DNS Name
dns_name = "devdemo.onspot.click"
```
#### Step-07-04-04: stag.tfvars
```t
# DNS Name
dns_name = "stagedemo.onspot.click"
```

### Step-07-05: c11-acm-certificatemanager.tf
- In your case, the domain names will change as per this step.
```t
# Before
  subject_alternative_names = [
      "*.onspot.click"
  ]

# After
  subject_alternative_names = [
      #"*.onspot.click"
      var.dns_name
  ]
```

### Step-07-06: c13-02-autoscaling-launchtemplate-resource.tf
```t
# Before
  name = "my-launch-template"
# After
  name_prefix = "${local.name}-"
```
### Step-07-07: c13-02-autoscaling-launchtemplate-resource.tf
```t
# Before
  tag_specifications {
      resource_type = "instance"
      tags = {
          Name = "myasg"
      }
  }
# After
  tag_specifications {
      resource_type = "instance"
      tags = {
          #Name = "myasg"
          Name = local.name
      }
  }
```
### Step-07-08: c13-08-autoscaling-resource.tf
```t
# Before
  name_prefix = "myasg-"
# After
  name_prefix = "${local.name}-"
```
### Step-07-09: c13-06-autoscaling-ttsp.tf
```t
# Before
  name = "avg-cpu-policy-greater-than-xx"
  name = "alb-target-requests-greater-than-yy"
# After
  name = "${local.name}-avg-cpu-policy-greater-than-xx"
  name = "${local.name}-alb-target-requests-greater-than-yy"
  ```

  ## Step-08: Create Secure Parameters in Parameter Store
  ### Step-08-01: Create MY_AWS_SECRET_ACCESS_KEY
  - Go to Services -> Systems Manager -> Application Management -> Parameter Store -> Create Parameter
    - Name: /CodeBuild/MY_AWS_ACCESS_KEY_ID
    - Description: My AWS Access Key ID for Terraform CodePipeline Project
    - Tier: Standard
    - Type: Secure String
    - Rest all defaults
    - Value: ABCXXXXDEFXXXXGHXXX

### Step-08-02: Create MY_AWS_SECRET_ACCESS_KEY
- Go to Services -> Systems Manager -> Application Management -> Parameter Store -> Create Parameter
  - Name: /CodeBuild/MY_AWS_SECRET_ACCESS_KEY
  - Description: My AWS Secret Access Key for Terraform CodePipeline Project
  - Tier: Standard
  - Type: Secure String
  - Rest all defaults
  - Value: abcdefxjkdklsa55dsjlkdjsakj

## Step-09: buildspec-dev.yml
- Discuss about following Environment variables we are going to pass
- TERRAFORM_VERSION
  - which version of terraform codebuild should use
  - As on today `0.15.3` is latest we will use that
- TF_COMMAND
  - we will use `apply` to create resources
  - we will use `destroy` in CodeBuild Environment
- AWS_ACCESS_KEY_ID: /CodeBuild/MY_AWS_ACCESS_KEY_ID
  - AWS Access Key ID is safely stored in Parameter Store
- AWS_SECRET_ACCESS_KEY: /CodeBuild/MY_AWS_SECRET_ACCESS_KEY
  - AWS Secret Access Key is safely stored in Parameter Store
```yaml
version: 0.2

env:
  variables:
    TERRAFORM_VERSION: "0.15.3"
    TF_COMMAND: "apply"
    #TF_COMMAND: "destroy"
  parameter-store:
    AWS_ACCESS_KEY_ID: "/CodeBuild/MY_AWS_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY: "/CodeBuild/MY_AWS_SECRET_ACCESS_KEY"

phases:
  install:
    runtime-version:
      python: 3.7
    on-failure: ABORT
    commands:
      - tf_version=$TERRAFORM_VERSION
      - wget https://releases.hashicorp.com/terraform/"$TERRAFORM_VERSION"/terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
      - unzip terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
      - mv terraform /usr/local/bin/
pre_build:
  on-failure: ABORT
  commands:
    - echo terraform execution started on `date`
build:
  on-failure: ABORT
  commands:
  # Project-1: AWS VPC, ASG, ALB, Route53, ACM, Security Groups and SNS
    - cd "$CODEBUILD_SRC_DIR/terraform-manifests"
    - ls -lrt "$CODEBUILD_SRC_DIR/terraform-manifests"
    - terraform --version
    - terraform init -input=false --backend-config=dev.conf
    - terraform validate
    - terraform plan -lock=false -input=false -var-file=dev.tfvars
    - terraform $TF_COMMAND -input=false -var-file=dev.tfvars -auto-approve
post_build:
  on-failure: CONTINUE
  commands:
    - echo terraform execution completed on `date`
```

## Step-10: buildspec-stag.yml
```yaml
version: 0.2

env:
  variables:
    TERRAFORM_VERSION: "0.15.3"
    TF_COMMAND: "apply"
    #TF_COMMAND: "destroy"
  parameter-store:
    AWS_ACCESS_KEY_ID: "/CodeBuild/MY_AWS_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY: "/CodeBuild/MY_AWS_SECRET_ACCESS_KEY"

phases:
  install:
    runtime-versions:
      python: 3.7
    on-failure: ABORT
    commands:
      - tf_version=$TERRAFORM_VERSION
      - wget https://releases.hashicorp.com/terraform/"$TERRAFORM_VERSION"/terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
      - unzip terraform_"$TERRAFORM_VERSION"_linux_amd64.zip
      - mv terraform /usr/local/bin/
  pre_build:
    on-failure: ABORT
    commands:
      - echo terraform execution started on `date`
  build:
    on-failure: ABORT
    commands:
    # Project-1: AWS VPC, ASG, ALB, Route53, ACM, Security Groups and SNS
      - cd "$CODEBUILD_SRC_DIR/terraform-manifests"
      - ls -lrt "$CODEBUILD_SRC_DIR/terraform-manifests"
      - terraform --version
      - terraform init -input=false --backend-config=stag.conf
      - terraform validate
      - terraform plan -lock=false -input=false -var-file=stag.tfvars
      - terraform $TF_COMMAND -input=false -var-file=stag.tfvars -auto-approve
  post_build:
    on-failure: CONTINUE
    commands:
      - echo terraform execution completed on `date`
```

## Step-11: Create Github Repository and Check-In file
### Step-11-01: Create New Github Repository
- Go to github.com and login with your credentials
- URL: https://github.com/kuluruvineeth (my git repo url)
- Click on **Repositories Tab**
- Click on **New** to create a new repository
- **Repository Name:** terraform-iacdevops-with-aws-codepipeline
- **Description:** Implement Terraform IAC Devops for AWS Project with AWS CodePipeline
- **Repository Type:** Private
- **Choose License:** Apache License 2.0
- Click on **Create Repository**
- Click on **Code** and Copy Repo link
### Step-11-02: Clone Remote Repo and Copy all related files
```t
# Change Directory
cd demo-repos

# Execute Git Clone
git clone https://github.com/kuluruvineeth/terraform-iacdevops-with-aws-codepipeline.git

# Copy all files from section-21 Git-Repo-Files folder
1. Source Folder Path: 21-IaC-Devops-using-AWS-CodePipeline/Git-Repo-Files
2. Copy all files from Source Folder to Destination Folder
3. Destination Folder Path: demo-repos/terraform-iacdevops-with-aws-codepipeline

# Verify Git Status
git status

# Git Commit
git commit -am "First Commit"

# Push files to Remote Repository
git push

# Verify same on Remote Repository
https://github.com/kuluruvineeth/terraform-iacdevops-with-aws-codepipeline.git

## Step-12: Verify if AWS Connector for GitHub already installed on your Github
- Go to below url and verify
- **URL:** https://github.com/settings/installations

## Step-13: Create GitHub Connection from AWS Developer Tools
- Go to Services -> CodePipeline -> Create Pipeline
- In Developer Tools -> Click on **Settings** -> Connections -> Create Connection
- **Select Provider:** Github
- **Connection Name:** terraform-iacdevops-aws-cp-con1
- Click on **Connect to Github**
- Github Apps: Click on **Install new app**
- It should redirect to github page `Install AWS Connector for Github`
- **Only select repositories:** terraform-iacdevops-with-aws-codepipeline
- Click on **Install**
- Click on **Connect**
- Verify Connection Status: It should be in **Available** state
- Go to below url and verify
- **URL:**  https://github.com/settings/installations
- You should see `Install AWS Connector for Github` app installed

## Step-14: Create AWS CodePipeline
- Go to Services -> CodePipeline -> Create Pipeline
### Pipeline settings
- **Pipeline Name:** tf-iacdevops-aws-cp1
- **Service role:** New Service Role
- rest all defaults
  - Artifact store: Default Location
  - Encryption Key: Default AWS Managed Key
- Click **Next**
### Source Stage
- **Source Provider:** Github (Version 2)
- **Connection:** terraform-iacdevops-aws-cp-con1
- **Repository name:** terraform-iacdevops-with-aws-codepipeline
- **Branch name:** main
- **Change detection options:** leave to defaults as checked
- **Output artifact format:** leave to defaults as `CodePipeline default`
### Add Build Stage
- **Build Provider:** AWS CodeBuild
- **Region:** N.Virginia
- **Project Name:** Click on **Create Project**
  - **Project Name:** codebuild-tf-iacdevops-aws-cp1
  - **Description:** CodeBuild Project for Dev Stage of IAC Devops Terrafrom Demo
  - **Environment image:** Managed Image
  - **Operating System:** Amazon Linux 2
  - **Runtimes:** Standard
  - **Image:** latest available today
  - **Environment Type:** Linux
  - **Service Role:** New (leave to defaults including Role Name)
  - **Build specifications:** use a buildspec file
  - **Buildspec name - optional:** buildspec-dev.yaml (Ensure that this file is present in root folder of your github repository)
  - Rest all leave to defaults
  - Click on **Continue to CodePipeline**
- **Project Name:** This value should be auto-populated with `codebuild-tf-iacdevops-aws-cp1`
- **Build Type:** Single Build
- Click **Next**
### Add Deploy Stage
- click on **Skip Deploy Stage**
### Review Stage
- Click on **Create Pipeline**

## Step-15: Verify the Pipeline created
- **Verify Source Stage:** Should pass
- **Verify Build Stage:** should fail with error
- Verify Build Stage logs by clicking on **details** in pipeline screen
```log
dcsdc
```
## Step-16: Fix ssm:GetParameters IAM Role issues
### Step-16-01: Get IAM Service Role used by CodeBuild Project
- Get the IAM Service Role name CodeBuild Project is using
- Go to CodeBuild -> codebuild-tf-iacdevops-aws-cp1 -> Edit -> Environment
- Make a note of Service Role ARN
```t
# CodeBuild Service Role ARN

```
### Step-16-02: Create IAM Policy with Systems Manager Get Parameter Read Permission
- Go to Services -> IAM -> Policies -> Create Policy
- **Service:** Systems Manager
- **Actions:** Get Parameters (Under Read)
- **Resources:** All
- Click **Next Tags**
- Click **Next Review**
- **Policy name:** systems-manager-get-parameter-access
- **Policy Description:** Read Parameters from Parameter Store in AWS Systems Manager Service
- Click on **Create Policy**

### Step-16-03: Associate this Policy to IAM Role
- Go to Services -> IAM -> Roles -> Search for `codebuild-codebuild-tf-iacdevops-aws-cp1-service-role`
- Attach the policy named `systems-manager-get-parameter-access`

## Step-17: Re-run the CodePipeline
- Go to Services -> CodePipeline -> tf-iacdevops-aws-cp1
- Click on **Release Change**
- **Verify Source Stage:**
  - Should pass
- **Verify Build Stage:**
  - Verify Build Stage logs by clicking on **details** in pipeline screen
  - Verify `cloudwatch -> Log Groups` logs too (Logs saved in CloudWatch for additional reference)

## Step-18: Verify Resources
0. Confirm SNS Subscription in your email
1. Verify EC2 Instances
2. Verify Launch Templates (High Level)
3. Verify Autoscaling Group (High Level)
4. Verify Load Balancer
5. Verify Load Balancer Target Group - Health Checks
6. Access and Test
```t
# Access and Test
http://devdemo.onspot.click
http://devdemo.onspot.click/app1/index.html
http://devdemo.onspot.click/app1/metadata.html
```

## Step-19: Add Approval Stage before deploying to staging environment
- Go to Services -> AWS CodePipeline -> tf-iacdevops-aws-cp1 -> Edit
### Add Stage
  - Name: Email-Approval
### Add Action Group
- Action Name: Email-Approval
- Action Provider: Manual Approval
- SNS Topic: Select SNS Topic from drop down
- Comments: Approve to deploy to staging environment

## Step-20: Add Staging Environment Deploy Stage
- Go to Services -> AWS CodePipeline -> tf-iacdevops-aws-cp1 -> Edit
### Add Stage
  - Name: Stage-Deploy
### Add Action Group
- Action Name: Stage-Deploy
- Region: US East (N.Virginia)
- Action Provider: AWS CodeBuild
- Input Artifacts: Source Artifact
- **Project Name:** Click on **Create Project**
  - **Project Name:** stage-deploy-tf-iacdevops-aws-cp1
  - **Description:** CodeBuild Project for Staging Environment of IAC DevOps Terraform Demo
  - **Environment image:** Managed Image
  - **Operating System:** Amazon Linux 2
  - **Runtimes:** Standard
  - **Image:** latest available today
  - **Environment Type:** Linux
  - **Service Role:** New
  - **Build specifications:** use a buildspec file
  - **Buildspec name - optional:** buildspec-stag.yaml (Ensure that this file is present in root folder of your github repository)
  - Rest all leave to defaults
  - Click on **Continue to CodePipeline**
- **Project Name:** This value should be auto-populated with `stage-deploy-tf-iacdevops-aws-cp1`
- **Build Type:** Single Build
- Click on **Done**
- Click on **Save**

## Step-21: Update the IAM Role
- Update the IAM Role created as part of this `stage-deploy-tf-iacdevops-aws-cp1` CodeBuild project by adding the policy `systems-manager-get-parameter-access1`

## Step-22: Run the Pipeline
- Go to Services -> AWS CodePipeline -> tf-iacdevops-aws-cp1
- Click on **Release Change**
- Verify Source Stage
- Verify Build Stage (Dev Environment - Dev Deploy phase)
- Verify Manual Approval Stage - Approve the change
- Verify Stage Deploy Stage
  - Verify build logs

## Step-23: Verify Staging Environment
0. Confirm SNS Subscription in your email
1. Verify EC2 Instances
2. Verify Launch Templates (High Level)
3. Verify Autoscaling Group (High Level)
4. Verify Load Balancer
5. Verify Load Balancer Target Group - Health Checks
7. Access and Test
```t
# Access and Test
http://stagedemo.onspot.click
http://stagedemo.onspot.click/app1/index.html
http://stagedemo.onspot.click/app1/metadata.html
```

## Step-24: Make a change and test the entire pipeline
### Step-24-01: c13-03-autoscaling-resource.tf
- Increase minimum EC2 Instances from 2 to 3
```t
# Before
  desired_capacity = 2
  max_size = 10
  min_size = 2
# After
  desired_capacity = 4
  max_size = 10
  min_size = 4
```
### Step-24-02: Commit Changes via Git Repo
```t
# Verify Changes
git status

# Commit Changes to Local Repository
git add .
git commit -am "ASG Min Size from 2 to 4"

# Push changes to Remote Repository
git push
```
### Step-24-03: Review Build Logs
- Go to Services -> CodePipeline -> tf-iacdevops-aws-cp1
- Verify Dev Deploy Logs
- Approve at `Manual Approval` stage
- Verify Stage Deploy Logs

### Step-24-04: Verify EC2 Instances
- Go to Services -> EC2 Instances
- Newly created instances should be visible
- hr-dev: 4 EC2 Instances
- hr-stag: 4 EC2 Instances

## Step-25: Destroy Resources
### Step-25-01: Update buildspec-dev.yaml
```t
# Before
    TF_COMMAND: "apply"
    #TF_COMMAND: "destroy"
# After
    #TF_COMMAND: "apply"
    TF_COMMAND: "destroy"
```
### Step-25-02: Update buildspec-stag.yml
```t
# Before
    TF_COMMAND: "apply"
    #TF_COMMAND: "destroy"
# After
    #TF_COMMAND: "apply"
    TF_COMMAND: "destroy"    
```
### Step-25-03: Commit Changes via Git Repo
```t
# Verify Changes
git status

# Commit Changes to Local Repository
git add .
git commit -am "Destroy Resources"

# Push changes to Remote Repository
git push
```
### Step-25-04: Review Build Logs
- Go to Services -> CodePipeline -> tf-iacdevops-aws-cp1
- Verify Dev Deploy Logs
- Approve at `Manual Approval` stage
- Verify Stage Deploy Logs

## Step-26: Change Everything back to original Demo State
### Step-26-01: c13-03-autoscaling-resource.tf
- Change them back to original state
```t
# Before
  desired_capacity = 4
  max_size = 10
  min_size = 4
# After
  desired_capacity = 2
  max_size = 10
  min_size = 2
```
### Step-26-02: buildspec-dev.yml and buildspec-stag.yml
- Change them back to original state
```t
# Before
    #TF_COMMAND: "apply"
    TF_COMMAND: "destroy"   
# After
    TF_COMMAND: "apply"
    #TF_COMMAND: "destroy"     
```
### Step-26-03: Commit Changes via Git Repo
```t
# Verify Changes
git status

# Commit Changes to Local Repository
git add .
git commit -am "Fixed all the changes back to demo state"

# Push changes to Remote Repository
git push
```


## References
- [1:Backend configuration Dynamic](https://www.terraform.io/docs/cli/commands/init.html)
- [2:Backend configuration Dynamic](https://www.terraform.io/docs/language/settings/backends/configuration.html#partial-configuration)
- [AWS CodeBuild Builspe file reference](https://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html#build-spec.env)