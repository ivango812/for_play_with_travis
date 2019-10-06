resource "google_compute_global_forwarding_rule" "default" {
  name       = "tf-forwarding-rule-port-80"
  port_range = "80"
  target     = "${google_compute_target_http_proxy.default.self_link}"
}

resource "google_compute_target_http_proxy" "default" {
  name    = "tf-target-http-proxy"
  url_map = "${google_compute_url_map.default.self_link}"
}

resource "google_compute_url_map" "default" {
  name        = "tf-balancer"
  description = "a description"
  default_service = "${google_compute_backend_service.default.self_link}"
}

resource "google_compute_backend_service" "default" {
  name        = "tf-service"
  port_name   = "tf-http"
  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = ["${google_compute_health_check.default.self_link}"]

  backend {
    group = "${google_compute_instance_group.default.self_link}"
  }
}

resource "google_compute_health_check" "default" {
  name               = "tf-health-check"
  check_interval_sec = 10
  timeout_sec        = 3
  http_health_check {
    port = 9292
  }
}

resource "google_compute_instance_group" "default" {
  name = "tf-instance-group"
  description = "Reddit-app instance group"
  project = var.project
  instances = "${google_compute_instance.app.*.self_link}"

  named_port {
    name = "tf-http"
    port = "9292"
  }
  zone = var.zone
}
