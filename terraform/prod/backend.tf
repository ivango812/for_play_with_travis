terraform {
  required_version = "0.12.8"
  backend "gcs" {
    bucket  = "storage-tfstate"
    prefix  = "terraform/state-prod"
  }
}
