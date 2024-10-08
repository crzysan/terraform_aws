variable "name" {
  description = "The name of your stack, e.g. \"demo\""
  type        = string
}

variable "vpc_id" {
  description = "The VPC in which to deploy to"
  type        = string
}

variable "environment" {
  description = "The Environment to deploy to, e.g. \"dev\" \"acc\" \"prd\""
  type        = string
}