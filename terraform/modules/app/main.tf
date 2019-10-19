resource "google_compute_instance" "app" {
  name = "reddit-app-${var.env_name}"
  machine_type = "g1-small"
  zone = var.zone
  tags = ["reddit-app-${var.env_name}"]
  boot_disk {
    initialize_params { image = var.app_disk_image }
  }
  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.app_ip.address
    }
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
    source      = "${path.module}/files/puma.service"
    destination = var.enable_provisioner == true ? "/tmp/puma.service": "/dev/null"
  }
  provisioner "remote-exec" {
    inline = [
      var.enable_provisioner == true ? "echo export DATABASE_URL=\"${var.database_url}\" >> ~/.profile": "echo"
    ]
  }
  provisioner "remote-exec" {
    script = var.enable_provisioner == true ? "${path.module}/files/deploy.sh": ""
  }
  provisioner "local-exec" {
    when = "destroy"
    command = "ssh-keygen -R ${self.network_interface[0].access_config[0].nat_ip}"
  }
}

resource "google_compute_address" "app_ip" { 
  name = "reddit-app-ip-${var.env_name}" 
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default-${var.env_name}"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["reddit-app-${var.env_name}"]
}
