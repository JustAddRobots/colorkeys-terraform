terraform {
  backend "s3" {
    bucket          = "stage-terraform-state-colorkeys"
    key             = "stage.terraform.tfstate"
    region          = "us-west-1"
    dynamodb_table  = "stage-terraform-state-locks-colorkeys"
    encrypt         = true
  }
}
