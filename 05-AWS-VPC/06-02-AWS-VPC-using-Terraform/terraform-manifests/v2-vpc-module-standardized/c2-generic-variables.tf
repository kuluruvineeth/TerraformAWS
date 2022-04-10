# Input Variables
# AWS Region
variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type = string
  default = "us-east-1"
}

# Environment Variable
variable "environment" {
  description = "Environemnt Variable used as a prefix"
  type = string
  default = "dev"
}

# Business Division
variable "business_divison" {
  description = "Business Divison in the large organization this Infrastructure belongs"
  type = string
  default = "SAP"
}