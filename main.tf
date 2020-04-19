terraform {
  required_version = ">= 0.12.20"
}

data "aws_availability_zones" "main" {}

locals {
  create_bastion     = var.create_bastion && var.bastion_count != 0
  create_zone        = var.create_zone && var.zone_id == "" && var.zone_domain != ""
  create_vpc         = var.create_vpc && var.vpc_id == "" && length(var.subnet_ids) == 0
  bastion_count      = !local.create_bastion ? 0 : var.bastion_count > -1 ? var.bastion_count : length(local.subnet_ids)
  vpc_id             = local.create_vpc ? module.vpc.vpc_id : var.vpc_id
  subnet_ids         = local.create_vpc ? module.vpc.public_subnets : var.subnet_ids
  zone_id            = local.create_zone ? aws_route53_zone.main[0].zone_id : var.zone_id

  generated_cidrs_public = [
    for i in range(length(data.aws_availability_zones.main.names)) : cidrsubnet(var.vpc_cidr, var.vpc_cidr_prefix_length_public, i+var.vpc_cidr_offset_public)
  ]
  generated_cidrs_private = [
    for i in range(length(data.aws_availability_zones.main.names)) : cidrsubnet(var.vpc_cidr, var.vpc_cidr_prefix_length_private, i+var.vpc_cidr_offset_private)
  ]

  vpc_cidrs_public  = length(var.vpc_cidrs_public) > 0 ? var.vpc_cidrs_public : var.create_public_subnets ? local.generated_cidrs_public : []
  vpc_cidrs_private = length(var.vpc_cidrs_private) > 0 ? var.vpc_cidrs_private : var.create_private_subnets ? local.generated_cidrs_private : []

  bastions = [ for i in range(local.bastion_count): {
    name      = format("%s-%s-%d", var.name, "bastion", i)
    subnet_id = element(local.subnet_ids,i % length(local.subnet_ids))
    hostname  = var.zone_domain != "" ? format("%s-%s-%d.%s", var.name, "bastion", i, var.zone_domain) : null
    num       = i
  }]
}

module "tls_private_key" {
  source = "github.com/dioxic/terraform-aws-tls-private-key"

  create    = local.create_bastion && var.ssh_key_name == ""
  name      = var.name
  rsa_bits  = 2048
}

resource "aws_key_pair" "main" {
  count = local.create_bastion && var.ssh_key_name == "" ? 1 : 0

  key_name_prefix = "${module.tls_private_key.private_key_name}-"
  public_key      = module.tls_private_key.public_key_openssh
}

module "vpc" {
  source     = "terraform-aws-modules/vpc/aws"
  create_vpc = var.create_vpc

  name = var.name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.main.names
  private_subnets = local.vpc_cidrs_private
  public_subnets  = local.vpc_cidrs_public

  enable_nat_gateway     = var.enable_nat_gateway
  enable_dns_hostnames   = var.create_zone
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway

  tags = var.tags
}

resource "aws_security_group" "bastion" {
  count = var.create_bastion ? 1 : 0

  name        = format("%s-%s", var.name, "bastion")
  vpc_id      = local.vpc_id
  description = "Bastion servers security group"
  tags        = merge(
    {
      "Name" = format("%s-%s", var.name, "bastion")
    },
    var.tags
  )
}

resource "aws_security_group_rule" "egress" {
  count = var.create_bastion ? 1 : 0

  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.bastion[0].id
}

resource "aws_security_group_rule" "ssh" {
  count = var.create_bastion ? 1 : 0

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "SSH from Bastion"
  security_group_id        = aws_security_group.bastion[0].id
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_instance" "bastion" {
  for_each = { for o in local.bastions : o.name => o }

  ami                    = var.bastion_ami
  instance_type          = var.bastion_instance_type
  key_name               = var.ssh_key_name != "" ? var.ssh_key_name : aws_key_pair.main[0].key_name
  vpc_security_group_ids = [aws_security_group.bastion[0].id]
  subnet_id              = each.value.subnet_id

  user_data              = <<EOF
${each.value.hostname != null ? templatefile("${path.module}/templates/set-hostname.sh.tpl",
  {
    hostname = each.value.hostname
  }
) : ""}
${templatefile("${path.module}/templates/install-repo.sh.tpl",
  {
    mongodb_version   = var.mongodb_version,
    mongodb_community = var.mongodb_community
  }
)}
${templatefile("${path.module}/templates/install-shell.sh.tpl",
  {
    mongodb_community = var.mongodb_community
  }
)}
EOF

  tags = merge(
    {
      "Name" = each.value.name
    },
    var.tags
  )
}

resource "aws_route53_zone" "main" {
  count = local.create_zone ? 1 : 0

  name = var.zone_domain

  vpc {
    vpc_id = local.vpc_id
  }

  tags = var.tags
}

resource "aws_route53_record" "bastion" {
  for_each = { for o in local.bastions : o.name => o if o.hostname != null }

  zone_id = local.zone_id
  name    = each.value.hostname
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion[each.value.name].private_ip]
}