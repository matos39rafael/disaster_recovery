output "active_environment" {
  description = "Ambiente atualmente configurado para receber o tráfego"
  value       = var.active_environment
}

output "dr_instance_id" {
  description = "EC2 utilizada pelo ambiente DR"
  value       = var.deploy_dr ? aws_instance.DR_instance[0].id : null
}

output "dr_tunnel_id" {
  description = "Cloudflare Tunnel utilizado pelo DR"
  value = (
    var.deploy_dr
    ? cloudflare_zero_trust_tunnel_cloudflared.aws_tunnel[0].id
    : null
  )
}

output "s3_bucket_arn" {
  description = "Bucket ARN"
  value       = aws_s3_bucket.disaster_recovery.arn
}
