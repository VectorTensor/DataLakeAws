variable "owner_name" {
  type = string                     # The type of the variable, in this case a string
  default = "Prayash Thapa"                 # Default value for the variable
  description = "Name of the owner " # Description of what this variable represents
}

variable "environment" {
  type = string
  default = "dev"
  description = "Name of the environment e.g. dev, stage, prod"
}