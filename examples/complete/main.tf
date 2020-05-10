
data "aws_ami" "base" {
  most_recent = true
  owners      = [var.ami_owner]

  filter {
    name   = "name"
    values = [var.ami_name]
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

module "network" {
  source = "../.."

  create_vpc             = true
  create_zone            = true
  create_bastion         = true
  bastion_count          = 1
  domain_name            = var.domain_name
  name                   = var.name
  create_private_subnets = true
  create_public_subnets  = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  ssh_key_name           = var.ssh_key_name
  bastion_image_id       = data.aws_ami.base.id
  mongodb_version        = var.mongodb_version
  vpc_cidr               = "10.0.0.0/16"
  tags                   = var.tags
}