terraform {
  required_providers {
    multipass = {
      source = "todoroff/multipass"
    }
  }
}

resource "multipass_instance" "vm" {
  name  = var.name
  image = var.image
  cpus  = var.cpus
  memory = var.memory
  disk   = var.disk

  cloud_init_file = var.cloud_init_file
}