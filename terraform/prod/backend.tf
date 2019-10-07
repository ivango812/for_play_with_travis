terraform {
  required_version = "~> 0.12"
  backend "gcs" {
    bucket = "storage-gis-tfstate"
    prefix = "terraform/state-prod"
  }
}
