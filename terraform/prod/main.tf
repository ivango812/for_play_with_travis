provider "google" {
  version = "~>2.15"
  project = var.project
  region  = var.region
}

module "app" {
  source           = "../modules/app"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  zone             = var.zone
  app_disk_image   = var.app_disk_image
  env_name         = var.env_name
  database_url     = "${module.db.mongo_ip}:${module.db.mongo_port}"
  enable_provisioner = var.enable_provisioner
}

module "db" {
  source           = "../modules/db"
  public_key_path  = var.public_key_path
  private_key_path = var.private_key_path
  zone             = var.zone
  db_disk_image    = var.db_disk_image
  env_name         = var.env_name
  enable_provisioner = var.enable_provisioner
}

module "vpc" {
  source        = "../modules/vpc"
  source_ranges = ["95.161.223.68/32"]
  env_name      = var.env_name
}
