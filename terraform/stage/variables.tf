variable project {
  description = "Project ID"
}

variable region {
  description = "Region"
  default     = "europe-west1"
}

variable disk_image {
  description = "Disk image"
}

variable public_key_path {
  description = "Path to the public key used for ssh access"
}

variable private_key_path {
  description = "Path to the private key used for ssh conection"
}

variable zone {
  description = "Zone for instance"
  default     = "europe-west1-b"
}

variable instances_count {
  description = "Count of instances"
  default     = 1
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable db_disk_image {
  description = "Disk image for reddit db"
  default     = "reddit-db-base"
}

variable env_name {
  description = "Environment prefix for resources names"
}

variable enable_provisioner {
  description = "Enable disable all provisioners"
  default     = true
}
