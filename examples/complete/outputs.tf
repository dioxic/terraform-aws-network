output "vpc_cidr" {
  value = module.network.vpc_cidr
}

output "vpc_id" {
  value = module.network.vpc_id
}

output "vpc_cidrs_public" {
  value = module.network.vpc_cidrs_public
}

output "vpc_cidrs_private" {
  value = module.network.vpc_cidrs_private
}

output "bastion_public_ip" {
  value = module.network.bastion_public_ip
}
