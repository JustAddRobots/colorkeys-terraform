# stage

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = "${var.aws_region}"
  shared_credentials_file = "~/.aws/credentials"
  profile = "${var.aws_profile}"
}

module "pipeline" {
  source  = "../../infrastructure/service/pipeline"
}
