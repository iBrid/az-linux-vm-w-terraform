variable "location" {
  type        = string
  default     = "West US 2"
  description = "Location of the resources"
}

variable "resource_group_name" {
  default = "mylinux-RG"
  type    = string
}

variable "vm_admin_pw" {
  type        = string
  sensitive   = true
  description = "password to vm"
}