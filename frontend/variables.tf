variable "name" {
  description = "The name of your stack, e.g. \"demo\""
  default     = "demoapp"
  type        = string
}

variable "vpc_id" {
  description = "The VPC in which to deploy to"
  type        = string
  default     = "vpc-09f27cefd11b167c2"
}

variable "environment" {
  description = "The Environment to deploy to, e.g. \"dev\" \"acc\" \"prd\""
  type        = string
  default     = "dev"
}

variable "container_port" {
  description = "The docker port where the frontend server is exposed"
  default     = 8000
  type        = number
}
