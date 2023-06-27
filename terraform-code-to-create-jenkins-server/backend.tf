terraform {
  backend "s3" {
    bucket = "Photoprism-app"
    region = "us-east-1"
    key = "jenkins-server/terraform.tfstate"
    profile = "terraform"
  }
}