provider "aws" {
  region = "us-east-1"
}

//vpc
module "aws_vpc" {
  source = "github.com/rogmanster/terraform-aws-vault-ent-starter/examples/aws-vpc"

  resource_name_prefix    = var.resource_name_prefix
}

//tls
module "aws_acm" {
  source = "github.com/rogmanster/terraform-aws-vault-ent-starter/examples/aws-secrets-manager-acm"

  resource_name_prefix    = var.resource_name_prefix
  aws_lb_dns_name         = var.aws_lb_dns_name

}

//vault
module "aws_vault_ent" {
  source = "github.com/rogmanster/terraform-aws-vault-ent-starter"

  resource_name_prefix    = var.resource_name_prefix
  vault_license_filepath  = "/Users/rogman/workspaces/working/terraform-aws-vault-ent-starter/license.hclic"
  instance_type           = "m5.large"
  node_count              = "3"
  #vault_version           = "1.9.4" #~1.10.0 not working apt-get install -y vault-enterprise=${vault_version}+ent
  vault_version           = "1.11.2+ent-1"
  lb_health_check_path    = "/v1/sys/health?standbyok=true&perfstandbyok=true"
  allowed_inbound_cidrs_lb   = ["0.0.0.0/0"]
  allowed_inbound_cidrs_ssh  = ["0.0.0.0/0"]
  lb_type                 = var.lb_type

  block_device_mappings = [
    {
      device_name  = "/dev/sda1"
      no_device    = "false"
      virtual_name = "root"
      ebs = {
        encrypted             = false
        volume_size           = 1000
        delete_on_termination = true
        iops                  = 3000
        kms_key_id            = null
        snapshot_id           = null
        volume_type           = "io2"
        throughput            = null #~valid for gp2/gp3
      }
     }
  ]

  private_subnet_tags     = module.aws_vpc.private_subnet_tags
  vpc_id                  = module.aws_vpc.vpc_id
  secrets_manager_arn     = module.aws_acm.secrets_manager_arn
  lb_certificate_arn      = module.aws_acm.lb_certificate_arn
  leader_tls_servername   = module.aws_acm.leader_tls_servername
  key_name                = module.bastion.key_name
}

//bastion
module "bastion" {
  source = "github.com/rogmanster/terraform-aws-vault-ent-starter-bastion?ref=nlb"

  bastion_count             = 5 #~node for benchmark-vault
  telemetry_count           = 1 #~should only be 1
  instance_type             = "m5.large"
  vault_version             = "1.11.2"
  aws_region                = var.aws_region
  resource_name_prefix      = var.resource_name_prefix
  vpc_id                    = module.aws_vpc.vpc_id
  public_subnet_tags        = module.aws_vpc.public_subnet_tags
  vault_lb_sg_id            = module.aws_vault_ent.vault_lb_sg_id
  secrets_manager_arn       = module.aws_acm.secrets_manager_arn
  vault_lb_dns_name         = module.aws_vault_ent.vault_lb_dns_name
  aws_iam_instance_profile  = module.aws_vault_ent.aws_iam_instance_profile
  lb_type                   = var.lb_type
}
