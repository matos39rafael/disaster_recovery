resource "cloudflare_zero_trust_tunnel_cloudflared" "aws_tunnel" {
  count      = var.deploy_dr ? 1 : 0
  account_id = var.cloudflare_account_id
  name       = "${var.project_name}_aws_tunnel"
  config_src = "cloudflare"

}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "aws_tunnel_config" {
  count      = var.deploy_dr ? 1 : 0
  account_id = var.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.aws_tunnel[0].id

  config = {
    ingress = [{
      hostname = var.domain_name
      service  = "http://app:5000"
      },

      {
        service = "http_status:404"
      }
    ]
  }
}

locals {
  active_tunnel_id = (
    var.active_environment == "dr" && var.deploy_dr
    ? cloudflare_zero_trust_tunnel_cloudflared.aws_tunnel[0].id
    : var.on-prem_tunnel_id
  )
}


resource "cloudflare_dns_record" "webapp" {
  zone_id = var.cloudflare_zone_id
  name    = "epauta"


  content = "${local.active_tunnel_id}.cfargotunnel.com"
  ttl     = 1
  type    = "CNAME"
  proxied = true

  lifecycle {
    precondition {
      condition = (
        var.active_environment != "dr"
        ||
        var.deploy_dr
      )

      error_message = "active_environment='dr' exige deploy_dr=true."
    }
  }
}
