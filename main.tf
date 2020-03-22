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

data "template_file" "repo_install" {
  template = "${file("${path.module}/templates/install-repo.sh.tpl")}"

  vars = {
    mongodb_version   = "${var.mongodb_version}"
    mongodb_community = "${var.mongodb_community}"
  }
}

data "template_file" "shell_install" {
  template = "${file("${path.module}/templates/install-shell.sh.tpl")}"

  vars = {
    mongodb_community = "${var.mongodb_community}"
  }
}

module "ssh_keypair_aws" {
  source = "github.com/hashicorp-modules/ssh-keypair-aws"
  create = var.create && (var.bastion_count > 0 || var.bastion_count == -1) && var.ssh_key_name == ""
  name   = var.name
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
  create  = var.create && (var.bastion_count > 0 || var.bastion_count == -1)

  name        = format("%s-%s", var.name, "bastion")
  vpc_id      = var.create_vpc ? module.vpc.vpc_id : var.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["ssh-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags = var.tags
}

module "bastion" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 2.0"

  name                   = format("%s-%s", var.name, "bastion")
  instance_count         = var.create && var.bastion_count != -1 ? var.bastion_count : var.create ? length(var.vpc_cidrs_public) : 0

  ami                    = var.image_id != "" ? var.image_id : data.aws_ami.base.id
  instance_type          = var.instance_type
  key_name               = var.ssh_key_name != "" ? var.ssh_key_name : module.ssh_keypair_aws.name
  vpc_security_group_ids = [module.bastion_sg.this_security_group_id]
  subnet_ids             = module.vpc.public_subnets
  use_num_suffix         = true
  user_data              = <<EOF
${data.template_file.repo_install.rendered} # Runtime install mongodb package repo
${data.template_file.shell_install.rendered} # Runtime install mongodb shell
EOF

  tags = var.tags
}