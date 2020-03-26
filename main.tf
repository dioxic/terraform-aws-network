terraform {
  required_version = ">= 0.12.11"
}

data "aws_availability_zones" "main" {}

data "aws_ami" "base" {
  #count       = "${var.create && var.image_id == "" && var.bastion_count > 0 ? 1 : 0}"
  most_recent = true
  owners      = ["${var.ami_owner}"]

  filter {
    name   = "name"
    values = ["${var.ami_name}"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "template_file" "shell_install" {
  template = "${file("${path.module}/templates/install-shell.sh.tpl")}"

  vars = {
    mongodb_community = "${var.mongodb_community}"
  }
}

data "template_file" "set_hostname" {
  template = "${file("${path.module}/templates/set-hostname.sh.tpl")}"

  vars = {
    hostname = "${var.mongodb_community}"
  }
}

locals {
  create_bastion = var.create && (var.bastion_count > 0 || var.bastion_count == -1)
  install_repo   = templatefile("${path.module}/templates/install-repo.sh.tpl",
    {
      mongodb_version   = "${var.mongodb_version}",
      mongodb_community = "${var.mongodb_community}"
    }
  )
  install_shell  = templatefile("${path.module}/templates/install-shell.sh.tpl",
    {
      mongodb_version   = "${var.mongodb_version}",
      mongodb_community = "${var.mongodb_community}"
    }
  )
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
  create_vpc = var.create && var.create_vpc

  name = var.name
  cidr = var.vpc_cidr

  azs             = data.aws_availability_zones.main.names
  private_subnets = var.vpc_cidrs_private
  public_subnets  = var.vpc_cidrs_public

  enable_nat_gateway     = var.single_nat_gateway
  one_nat_gateway_per_az = var.one_nat_gateway_per_az
  single_nat_gateway     = var.single_nat_gateway

  tags = var.tags
}

module "bastion_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 3.0"
  create  = local.create_bastion

  name        = format("%s-%s", var.name, "bastion")
  vpc_id      = var.create_vpc ? module.vpc.vpc_id : var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

resource "aws_instance" "bastion" {
  count = var.create && var.bastion_count != -1 ? var.bastion_count : var.create ? length(module.vpc.public_subnets) : 0

  ami                    = var.image_id != "" ? var.image_id : data.aws_ami.base.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name != "" ? var.ssh_key_name : aws_key_pair.main[0].key_name
  vpc_security_group_ids = [module.bastion_sg.this_security_group_id]
  subnet_id              = element(
    module.vpc.public_subnets,
    count.index,
  )

  user_data              = <<EOF
${local.install_repo}  # Runtime install mongodb package repo
${local.install_shell} # Runtime install mongodb shell
templatefile("${path.module}/templates/install-repo.sh.tpl", { hostname = format("%s-%s-%d.%s", var.name, "bastion", var.bastion_domain_name)})
EOF

  tags = merge(
    {
      "Name" = format("%s-%s-%d", var.name, "bastion", count.index + 1)
    },
    var.tags
  )
}