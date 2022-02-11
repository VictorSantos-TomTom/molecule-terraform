terraform {
  backend "azurerm" {
  }
  required_providers {
    local = {
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=2.94.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  variables = yamldecode(file("${path.cwd}/../molecule.yml"))
}

resource "azurerm_resource_group" "rg" {
  name     = local.variables.resource_group_name
  location = local.variables.location
  tags     = merge(local.variables.azure_tags)
}

module "linuxservers" {
  for_each                      = { for servers in local.variables.platforms : servers.name => servers }
  source                        = "git::https://oauth2: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@github.com/tomtom-internal/cit-compute_terraform-compute-azurerm.git?ref=tt-v1.0.3"
  vm_hostname                   = each.key
  resource_group_name           = azurerm_resource_group.rg.name
  location                      = azurerm_resource_group.rg.location
  admin_username                = local.variables.admin_username
  admin_password                = local.variables.admin_password
  vm_os_id                      = each.value.vm_os_id
  enable_accelerated_networking = false
  vm_size                       = local.variables.vm_size
  nb_data_disk                  = local.variables.nb_data_disk
  identity_type                 = local.variables.identity_type
  enable_ssh_key                = local.variables.enable_ssh_key
  extra_ssh_keys                = local.variables.extra_ssh_keys
  depends_on                    = [azurerm_resource_group.rg]
  vnet_subnet_id                = local.variables.subnet
  remote_ports                  = each.value.remote_ports
}

output "ips" {
  value = [
    for i in module.linuxservers : {
       private_ips = "${i.network_interface_private_ip}", public_ips = "${i.public_ip_address}", vm_name = "${i.vm_name}" 
    }
  ]
}
