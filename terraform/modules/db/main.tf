resource "google_compute_instance" "db" {
  name = "reddit-db-${var.env_name}"
  machine_type = "g1-small"
  zone = var.zone
  tags = ["reddit-db-${var.env_name}"]
  boot_disk {
    initialize_params {
      image = var.db_disk_image
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
  connection {
    type  = "ssh"
    host  = self.network_interface[0].access_config[0].nat_ip
    user  = "appuser"
    agent = false
    private_key = file(var.private_key_path)
  }
  provisioner "file" {
    source      = "${path.module}/files/mongod.conf"
    destination = var.enable_provisioner == true ? "/tmp/mongod.conf": "/dev/null"
  }
  provisioner "remote-exec" {
    script = var.enable_provisioner == true ? "${path.module}/files/deploy.sh": ""
  }
  provisioner "local-exec" {
    when = "destroy"
    command = "ssh-keygen -R ${self.network_interface[0].access_config[0].nat_ip}"
  }
}

resource "google_compute_firewall" "firewall_mongo" {
  name = "allow-mongo-default-${var.env_name}"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["27017"]
  }
  target_tags = ["reddit-db-${var.env_name}"]
  source_tags = ["reddit-app-${var.env_name}"]
}

