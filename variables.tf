variable "location" {
  type        = string
  default     = "West US 2"
  description = "Location of the resources"
}

variable "resource_group_name" {
  default = "mylinux-RG"
  type    = string
}

variable "adminpw" {
  type = string
  sensitive = true
  description = "password to vm"
}