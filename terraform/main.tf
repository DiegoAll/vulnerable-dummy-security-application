resource "google_artifact_registry_repository" "vulnerable_dummy" {
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = "Registry para las imagenes del pipeline DevSecOps de vulnerable-dummy-security-application"
}
