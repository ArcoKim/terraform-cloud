variable "vpc" {
  type = string
}

variable "public" {
  type = map(string)
}

variable "private" {
  type = map(string)
}

variable "bastion_role" {
  type = string
}