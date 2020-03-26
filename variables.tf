variable "create" {
  description = "Create Module, defaults to true."
  type        = bool
  default     = true
}

variable "name" {
  description = "Name for resources, defaults to \"network-aws\"."
  default     = "network-aws"
}

variable "create_vpc" {
  description = "Determines whether a VPC should be created or if a VPC ID will be passed in."
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
  description = "VPC CIDR blocks for public subnets, defaults to \"10.0.1.0/24\", \"10.0.2.0/24\", and \"10.0.3.0/24\"."
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24",]
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

variable "vpc_cidrs_private" {
  description = "VPC CIDR blocks for private subnets, defaults to \"10.0.11.0/24\", \"10.0.12.0/24\", and \"10.0.13.0/24\"."
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24",]
}

variable "ami_owner" {
  description = "Account ID of AMI owner."
  default     = "amazon"
}

variable "ami_name" {
  description = "Machine image name."
  default     = "amzn2-ami-hvm-*-x86_64-gp2"
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

variable "image_id" {
  description = "AMI to use, defaults to amazon linux 2 latest."
  default     = ""
}

variable "instance_type" {
  description = "AWS instance type for bastion host (e.g. m4.large), defaults to \"t2.micro\"."
  default     = "t2.micro"
}

variable "user_data" {
  description = "user_data script to pass in at runtime."
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

variable "bastion_domain_name" {
  description = "The domain name for the hostname"
  default     = ""
}

variable "os" {
  description = "Operating System (e.g. RHEL or Ubuntu), defaults to \"RHEL\"."
  default     = "RHEL"
}

variable "os_version" {
  description = "Operating System version (e.g. 7.3 for RHEL or 16.04 for Ubuntu), defaults to \"7.3\"."
  default     = "7.3"
}

variable "users" {
  description = "Map of SSH users."

  default = {
    RHEL   = "ec2-user"
    Ubuntu = "ubuntu"
  }
}

variable "tags" {
  description = "Optional map of tags to set on resources, defaults to empty map."
  type        = map(string)
  default     = {}
}