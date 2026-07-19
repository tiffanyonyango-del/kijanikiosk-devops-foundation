terraform {
  required_version = ">= 1.5.0"

  backend "s3" {
    bucket = "terraform-state"
    key    = "kk-payments/terraform.tfstate"
    region = "us-east-1"

    endpoint = "http://localhost:9000"

    force_path_style            = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
  }

  required_providers {
    multipass = {
      source  = "todoroff/multipass"
      version = "~> 1.0"
    }
  }
}

provider "multipass" {}

module "app_server" {

  source = "./terraform/modules/app_server"

  for_each = {
    api      = {}
    payments = {}
    logs     = {}
  }

  name            = each.key
  image           = var.image
  cpus            = var.cpus
  memory          = var.memory
  disk            = var.disk
  cloud_init_file = "${path.root}/cloud-init.yaml"
}
