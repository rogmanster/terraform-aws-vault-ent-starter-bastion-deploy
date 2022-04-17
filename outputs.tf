output "vault_lb_dns_name" {
  description = "lb dns name to be added to generated certificate for tls"
  value       = module.aws_vault_ent.vault_lb_dns_name
}

output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
}

output "bastion_public_dns" {
  value       = module.bastion.bastion_public_dns
}

output "telemetry_public_ip" {
  value       = module.bastion.telemetry_public_ip
}

output "telemetry_public_dns" {
  value       = module.bastion.telemetry_public_dns
}

/*
output "Connection_Info" {
value = <<README

Grafana:
http://${module.bastion.telemetry_public_ip[0]}:9090)}

Prometheus:
http://${module.bastion.telemetry_public_ip[0]}:9090)}
ssh -i awskey.pem ubuntu@ec2-44-192-39-223.compute-1.amazonaws.com sudo docker restart prometheus

Bastion:
ssh -i awskey.pem ubuntu@${element(module.bastion.*.bastion_public_ip, 0)}

Telemetry:
ssh -i awskey.pem ubuntu@${module.bastion.*.telemetry_public_dns[0]}

README
*/
