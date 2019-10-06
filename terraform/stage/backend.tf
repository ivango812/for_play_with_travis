terraform {
  # Версия terraform
  required_version = "0.12.18"
  backend "gcs" {
    bucket  = "storage-gis-tfstate"
    prefix  = "terraform/state-stage"
  }
}
