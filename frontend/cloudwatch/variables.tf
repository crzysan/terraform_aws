variable "name" {
  description = "the name of your stack, e.g. \"demo\""
  type        = string
}

variable "environment" {
  description = "The Environment to deploy to, e.g. \"dev\" \"acc\" \"prd\""
  type        = string
}