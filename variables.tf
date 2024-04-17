variable "project_id" {
  description = "The project ID to host the cluster in"
  default     = "tests-1258"
}
variable "cluster_name" {
  description = "The name for the GKE cluster"
  default     = "scalegrid"
}
variable "env_name" {
  description = "The environment for the GKE cluster"
  default     = "prod"
}
variable "region" {
  description = "The region to host the cluster in"
  default     = "europe-west1"
}
variable "network" {
  description = "The VPC network created to host the cluster in"
  default     = "scalegrid-vpc"
}
variable "subnetwork" {
  description = "The subnetwork created to host the cluster in"
  default     = "scalegrid-subnet"
}
variable "ip_range_pods_name" {
  description = "The secondary ip range to use for pods"
  default     = "ip-cidr-pods"
}
variable "ip_range_services_name" {
  description = "The secondary ip range to use for services"
  default     = "ip-cidr-services"
}
