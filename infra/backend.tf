terraform {
  backend "s3" {
    bucket         = "bp-terraform-state-1764230215"
    key            = "bp-calculator/terraform.tfstate"
    region         = "eu-west-1"
    dynamodb_table = "bp-terraform-locks"
    encrypt        = true
  }
}
