variable "project_name" {
  description = "Project Name"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "aws_cidr_block" {
  description = "CIDR block of VPC"
  type        = string
}

variable "availability_zone" {
  description = "Availabitly Zone"
  type        = string
  default     = "sa-east-1a"
}

variable "public_cidr" {
  description = "Public subnet CIDR"
  type        = string

}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account Id"
  type        = string
}

variable "cloudflare_zone_id" {
  description = "Zone Id"
  type        = string
}

variable "domain_name" {
  description = "value"
  type        = string
}

variable "on-prem_tunnel_id" {
  description = "UUID do tunnel on-prem"
  type        = string
}

variable "app_image" {
  description = "Docker image"
  type        = string

}

variable "active_environment" {
  description = "Ambiente em produção do app ePauta"

  type = string

  validation {
    condition = contains(
      ["onprem", "dr"],
      var.active_environment
    )

    error_message = "active_environment deve ser 'onprem' ou 'dr'."
  }
}

variable "deploy_dr" {
  description = "Define se a infraestrutura AWS de DR deve existir"
  type        = bool
  default     = false
}

variable "dns_record_id" {
  type = string

}
