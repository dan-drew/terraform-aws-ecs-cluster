variable "name" {
  type = string
}

variable "vpc" {
  type = object({
    id = string
    cidr_block = string
    public_subnet_ids = list(string)
    private_subnet_ids = list(string)
  })
}

variable "tagging" {
  type = object({
    managed_by = string
    production = bool
  })
}

variable "type" {
  type = string
  default = "public"
  validation {
    condition = var.type == "public" || var.type == "private"
    error_message = "Cluster type must be public or private"
  }
}

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "initial_hosts" {
  type    = number
  default = 1
}

variable "max_hosts" {
  type    = number
  default = 2
}

variable "min_hosts" {
  type    = number
  default = 1
}

variable "min_scaling_step" {
  default = 1
  validation {
    condition     = var.min_scaling_step >= 1 && var.min_scaling_step <= 10000
    error_message = "Must be between 1 and 10000."
  }
}

variable "max_scaling_step" {
  default = 3
  validation {
    condition     = var.max_scaling_step >= 1 && var.max_scaling_step <= 10000
    error_message = "Must be between 1 and 10000."
  }
}

variable "target_capacity" {
  type        = number
  default     = null
  description = "Percentage of target tracking cloudwatch metric utilization"
}

# variable "load_balancers" {
#   type = list(string)
#   default = []
#   description = "List of load balancer ARNs that will be used to access cluster services"
# }

variable "shared_data" {
  type        = bool
  default     = false
  description = "Create a shared EFS that can be mounted to containers for persisting shared data"
}

variable "key_pair" {
  type    = string
  default = null
}

# variable "backup_vault" {
#   type    = string
#   default = null
# }

variable "logging" {
  type    = string
  default = null

  validation {
    condition     = var.logging == null || can(regex("^(aws|fluent)$", var.logging))
    error_message = "Logging must be aws or fluent (default)"
  }
}

# variable "ami_name" {
#   type    = string
#   default = "amzn2-ami-ecs-hvm-*-x86_64-ebs"
# }

# variable "ami_owner" {
#   type    = string
#   default = "amazon"
# }

variable "auto_scale" {
  default     = true
  description = "Auto-scale hosts using a capacity provider"
}

variable "assign_public_ips" {
  type    = bool
  default = null
}

variable "users" {
  type = list(object({
    name = string
    ssh = string
  }))
  default = []
  description = "Add users with SSH access to container host instances"
}
