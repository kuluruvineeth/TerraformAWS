# Terraform Remote State Datasource
data "terraform_remote_state" "vpc" {
  backend = "s3"
  config = {
    bucket = "terraformaws-forec2"
    key    = "dev/project1-vpc/terraform.tfstate"
    region = "us-east-1"
  }
}