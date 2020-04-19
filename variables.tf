variable "name" {
  description = "Name for resources, defaults to \"network-aws\"."
  default     = "network-aws"
}

variable "create_vpc" {
  description = "Determines whether a VPC should be created or if a VPC ID will be passed in."
  type        = bool
  default     = true
}

variable "create_zone" {
  description = "Create route53 private hosted zone, defaults to `false`"
  type        = bool
  default     = false
}

variable "create_bastion" {
  description = "Create bastion host flag, defaults to `true`"
  type        = bool
  default     = true
}

variable "create_public_subnets" {
  description = "Create public subnets if `vpc_cidrs_public` is not provided, defaults to `true`"
  type        = bool
  default     = true
}

variable "create_private_subnets" {
  description = "Create private subnets if `vpc_cidrs_private` is not provided, defaults to `true`"
  type        = bool
  default     = true
}

variable "vpc_id" {
  description = "VPC ID to override, must be entered if \"create_vpc\" is false."
  default     = ""
}

variable "vpc_cidr" {
  description = "VPC CIDR block, defaults to \"10.0.0.0/16\"."
  default     = "10.0.0.0/16"
}

variable "vpc_cidrs_public" {
  description = "VPC CIDR blocks for public subnets."
  type        = list(string)
  default     = []
}

variable "vpc_cidrs_private" {
  description = "VPC CIDR blocks for private subnets."
  type        = list(string)
  default     = []
}

variable "vpc_cidr_prefix_length_public" {
  description = "CIDR prefix length for calculating public subnet, defaults to `8`."
  type        = number
  default     = 8
}

variable "vpc_cidr_prefix_length_private" {
  description = "CIDR prefix length for calculating private subnet, defaults to `8`."
  type        = number
  default     = 8
}

variable "vpc_cidr_offset_public" {
  description = "Offset for public subnet, defaults to `0`"
  type        = number
  default     = 0
}

variable "vpc_cidr_offset_private" {
  description = "Offset for private subnet, defaults to `10`"
  type        = number
  default     = 10
}

variable "single_nat_gateway" {
  description = "Should be true if you want to provision a single shared NAT Gateway across all of your private networks"
  type        = bool
  default     = false
}

variable "one_nat_gateway_per_az" {
  description = "Should be true if you want only one NAT Gateway per availability zone. Requires `var.azs` to be set, and the number of `public_subnets` created to be greater than or equal to the number of availability zones specified in `var.azs`."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "Should be true if you want to provision NAT Gateways for each of your private networks"
  type        = bool
  default     = false
}

variable "mongodb_version" {
  description = "MongoDB version tag (e.g. 4.0.0 or 4.0.0-ent), defaults to \"4.2\"."
  default     = "4.2"
}

variable "mongodb_community" {
  description = "MongoDB community version, defaults to false."
  type        = bool
  default     = false
}

variable "bastion_count" {
  description = "Number of bastion hosts to provision across public subnets, defaults to public subnet count."
  default     = -1
}

variable "bastion_ami" {
  description = "AMI to use for bastion host. Required."
  default     = ""
}

variable "bastion_instance_type" {
  description = "AWS instance type for bastion host (e.g. m4.large), defaults to \"t2.micro\"."
  default     = "t2.micro"
}

variable "user_data" {
  description = "user_data script to pass in at runtime for bastion host."
  default     = ""
}

variable "ssh_key_name" {
  description = "AWS key name you will use to access the Bastion host instance(s), defaults to generating an SSH key for you."
  default     = ""
}

variable "private_key_file" {
  description = "Private key filename for AWS key passed in, defaults to empty."
  default     = ""
}

variable "zone_domain" {
  description = "The hosted zone domain name. Required if create_zone is `true`"
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet ids for the bastion server(s). Required if `bastion_count` > 0 and `create_vpc` is false."
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Existing route53 private host zone id"
  default     = ""
}

# variable "os" {
#   description = "Operating System (e.g. RHEL or Ubuntu), defaults to \"RHEL\"."
#   default     = "RHEL"
# }

# variable "os_version" {
#   description = "Operating System version (e.g. 7.3 for RHEL or 16.04 for Ubuntu), defaults to \"7.3\"."
#   default     = "7.3"
# }

# variable "users" {
#   description = "Map of SSH users."

#   default = {
#     RHEL   = "ec2-user"
#     Ubuntu = "ubuntu"
#   }
# }

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(string)
  default     = {}
}