variable "name" {
  type = string
}

variable "image" {
  type = string
  default = "22.04"
}

variable "cpus" {
  type = number
  default = 1
}

variable "memory" {
  type = string
  default = "1G"
}

variable "disk" {
  type = string
  default = "5G"
}

variable "cloud_init_file" {
  type = string
}