## Deploy AWS Vault Enterprise Cluster (IS)

TLS certs need to be seeded in aws certificate manager & aws secret manager for the vault cluster to come up. However, the `vault_lb_dns_name` needs to be added to the tls cert which isn't known. So,the certs need to be updated after the vault cluster is deployed.


#### Deploy VPC and ACM/ASM

```
terraform apply -target=module.aws_vpc -target=module.aws_acm
```

#### Deploy Vault Cluster

*Note:* The Terraform output has the DNS name of the AWS LB which is needed to recreate the tls cert.
```
terraform apply -target=module.aws_vault_ent
```
```
output:
vault_lb_dns_name = "internal-rchao-vault-lb-1681010981.us-east-1.elb.amazonaws.com"
```

#### Update TLS certificates and reseed in ACM/ASM

```
terraform apply -var aws_lb_dns_name="<REPLACE with vault_lb_dns_name>"
```
```
example:
terraform apply -var aws_lb_dns_name="internal-rchao-vault-lb-1631971535.us-east-1.elb.amazonaws.com"
```

#### ASG Instance refresh to pick up updated TLS certificates

*Note:* This takes up to 20+ mins for 3 node cluster. Wait for it to complete.

*refresh:*
```
aws autoscaling start-instance-refresh --auto-scaling-group-name rchao-vault --region us-east-1
```
*status:*
```
aws autoscaling describe-scaling-activities --auto-scaling-group-name rchao-vault --region us-east-1
```

#### Initialize Vault

*Note:* Use session manager in the AWS console. Be sure to copy `root_token` in unseal.json. The additional Vaults nodes will auto join.
```
sudo -i
vault operator init -address='https://localhost:8200' -key-shares=1 -key-threshold=1 -format=json > unseal.json
```
<br>

## Bastion

*Note:* You'll need to `scp` benchmark-vault to the bastion nodes.

```
output of two bastion and one telemetry node(s):

bastion_public_dns = [
  "ec2-44-202-146-149.compute-1.amazonaws.com",
  "ec2-52-5-113-185.compute-1.amazonaws.com",
]
bastion_public_ip = [
  "44.202.146.149",
  "52.5.113.185",
]
telemetry_public_dns = [
  "ec2-44-204-11-117.compute-1.amazonaws.com",
]
telemetry_public_ip = [
  "44.204.11.117",
]
vault_lb_dns_name = "internal-rchao-vault-lb-859430941.us-east-1.elb.amazonaws.com"
```
```
ssh example:
ssh -i awskey.pem ubuntu@ec2-44-202-146-149.compute-1.amazonaws.com
```
<br>

## Telemetry

Prometheus needs the target IP's of the Vault nodes to metric scape. However, since the cluster is deployed as an ASG there are [no IPs](https://github.com/hashicorp/terraform-provider-aws/issues/511)  or Instance IDs known to Terraform.

*Note:* The `prometheus.yml` configuration may need updating with the Vault node correct IPs after deployed. If so, restart the Prometheus container on the telemetry node after updating.

```
fetch instance ips:
for x in $(aws --output text --query "AutoScalingGroups[0].Instances[*].InstanceId" autoscaling describe-auto-scaling-groups --auto-scaling-group-names rchao-vault --region us-east-1);
do
echo $(aws --region us-east-1 ec2 describe-instances --filters "Name=instance-state-name,Values=running" "Name=instance-id,Values=$x" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text):8200;
done

sudo vi /etc/prometheus/prometheus.yml

static_configs:
- targets: ['']  <-- REPLACE & RESTART PROMETHEUS CONTAINER

restart:
sudo docker restart prometheus

example:
scrape_configs:
  - job_name: 'vault'
    metrics_path: '/v1/sys/metrics'
    params:
      format: [prometheus]
    bearer_token: 'example'
    scheme: 'https'
    tls_config:
      ca_file: /etc/prometheus/vault-ca.pem
      cert_file: /etc/prometheus/vault-cert.pem
      key_file: /etc/prometheus/vault-key.pem
    static_configs:
            - targets: ['10.0.18.120:8200','10.0.82.20:8200','10.0.49.203:8200']
```
```
grafana:
open http://ec2-44-204-11-117.compute-1.amazonaws.com:3000

prometheus:
open http://ec2-44-204-11-117.compute-1.amazonaws.com:9090
```
