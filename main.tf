terraform {
  required_version = ">= 0.12.20"
}

data "aws_availability_zones" "main" {}

locals {
  create_vpc         = var.create_vpc && var.vpc_id == "" && length(var.subnet_ids) == 0
  bastion_count      = var.bastion_count != null ? var.bastion_count : length(local.subnet_ids)
  vpc_id             = local.create_vpc ? module.vpc.vpc_id : var.vpc_id
  subnet_ids         = local.create_vpc ? module.vpc.public_subnets : var.subnet_ids
  zone_id            = var.create_zone ? aws_route53_zone.main[0].zone_id : var.zone_id

  generated_cidrs_public = length(var.vpc_cidrs_public) == 0 ? [
    for i in range(length(data.aws_availability_zones.main.names)) :
      cidrsubnet(var.vpc_cidr, var.vpc_cidr_prefix_length_public, i+var.vpc_cidr_offset_public)
  ] : []

  generated_cidrs_private = length(var.vpc_cidrs_private) == 0 ? [
    for i in range(length(data.aws_availability_zones.main.names)) :
      cidrsubnet(var.vpc_cidr, var.vpc_cidr_prefix_length_private, i+var.vpc_cidr_offset_private)
  ] : []

  vpc_cidrs_public  = var.create_public_subnets ? concat(local.generated_cidrs_public, var.vpc_cidrs_public) : []
  vpc_cidrs_private = var.create_private_subnets ? concat(local.generated_cidrs_private, var.vpc_cidrs_private) : []

  bastions = var.create_bastion ? { for i in range(local.bastion_count): "${var.name}-bastion-${i}" => {
    subnet_id = element(local.subnet_ids, i % length(local.subnet_ids))
    fqdn      = "${var.name}-bastion-${i}.${var.domain_name}"
  }} : {}
}

module "tls_private_key" {
  source = "github.com/dioxic/terraform-aws-tls-private-key"

  create    = var.create_bastion && var.ssh_key_name == ""
  name      = var.name
  rsa_bits  = 2048
}

resource "aws_key_pair" "main" {
  count = var.create_bastion && var.ssh_key_name == "" ? 1 : 0

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

  name_prefix = "${var.name}-bastion-"
  vpc_id      = local.vpc_id
  description = "Bastion security group"
  tags        = merge(
    {
      "Name" = "${var.name}-bastion"
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
  description              = "SSH"
  security_group_id        = aws_security_group.bastion[0].id
  cidr_blocks              = ["0.0.0.0/0"]
}

data "template_cloudinit_config" "shell" {
  for_each = local.bastions

  gzip          = true
  base64_encode = true

  part {
    filename     = "shell-init.cfg"
    content_type = "text/cloud-config"
    content      = templatefile("${path.module}/templates/cloud-init-shell.yaml", {
      mongodb_package     = var.enterprise_binaries ? "mongodb-enterprise" : "mongodb-org"
      mongodb_version     = var.mongodb_version
      repo_url            = var.enterprise_binaries ? "repo.mongodb.com" : "repo.mongodb.org"
      fqdn                = each.value.fqdn
    })
  }
}

resource "aws_instance" "bastion" {
  for_each = local.bastions

  ami                    = var.bastion_image_id
  instance_type          = var.bastion_instance_type
  key_name               = var.ssh_key_name != "" ? var.ssh_key_name : aws_key_pair.main[0].key_name
  vpc_security_group_ids = aws_security_group.bastion[*].id
  subnet_id              = each.value.subnet_id

  user_data = data.template_cloudinit_config.shell[each.key].rendered

  tags = merge(
    {
      "Name" = each.key
    },
    var.tags
  )
}

resource "aws_route53_zone" "main" {
  count = var.create_zone ? 1 : 0

  name = var.domain_name

  vpc {
    vpc_id = local.vpc_id
  }

  tags = var.tags
}

resource "aws_route53_record" "bastion" {
  for_each = local.bastions

  zone_id = local.zone_id
  name    = each.value.fqdn
  type    = "A"
  ttl     = "300"
  records = [aws_instance.bastion[each.key].private_ip]
}