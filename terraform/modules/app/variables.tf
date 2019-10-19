variable public_key_path {
  description = "Path to the public key used to connect to instance"
}

variable private_key_path {
  description = "Path to the private key used for provisioners to connect to instance"
}

variable zone {
  description = "Zone"
}

variable app_disk_image {
  description = "Disk image for reddit app"
  default     = "reddit-app-base"
}

variable env_name {
  description = "Environment prefix for resources names"
}

variable database_url {
  description = "Mongo url mongodb://<local_ip>:<port>/<database>"
}

variable enable_provisioner {
  description = "Enable disable all provisioners"
}
