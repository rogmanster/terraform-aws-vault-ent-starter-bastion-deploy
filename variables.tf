variable "aws_lb_dns_name" {
  type        = string
  description = "add aws lb dns name as a dns name to certificate"
  default = "aws_lb.example.com"
}

variable "resource_name_prefix" {
  type        = string
  description = "Resource name prefix used for tagging and naming AWS resources"
}

variable "aws_region" {
  description = "Bastion module requires region to generate bastion.tpl to fetch tls certs from ASM"
}

variable "lb_type" {
  description = "Set as 'application' or 'network'. The L4 network option is needed cert auth which passes thru TLS to the Vault nodes themselves. "
}
