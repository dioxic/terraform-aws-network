data "aws_availability_zones" "main" {}

data "aws_ami" "amzn2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
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
  bastion_count          = 1
  zone_domain            = "example.com"
  name                   = "example"
  create_private_subnets = true
  create_public_subnets  = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  ssh_key_name           = var.ssh_key_name
  bastion_image_id       = data.aws_ami.amzn2.id
  mongodb_version        = "4.2"
  vpc_cidr               = "10.0.0.0/16"
  tags = {
    owner = "mark.baker-munton"
  }
}