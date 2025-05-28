variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  default     = "asia-south1"
  description = "Region in India"
}

variable "zone" {
  default     = "asia-south1-c"
  description = "Zone for VMs"
}
