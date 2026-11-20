terraform {
  backend "s3" {
    bucket       = "pa.abhradip-terraform-bucket"
    key          = "serverless-file-storage/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true
    profile      = "pa-abhradip"
  }
}
