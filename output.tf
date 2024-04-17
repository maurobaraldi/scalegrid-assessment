output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.name
}

output "redis_haproxy_ip" {
  description = "IP address for HAproxy load balancer for Redis HA."
  value       = module.address-fe.addresses
}