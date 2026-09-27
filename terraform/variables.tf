variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
  default     = "project-f50a094d-d02b-40c5-b0d"
}

variable "region" {
  description = "Region de GCP"
  type        = string
  default     = "us-east1"
}

variable "repository_id" {
  description = "Nombre del repositorio de Artifact Registry"
  type        = string
  default     = "vulnerable-dummy"
}
