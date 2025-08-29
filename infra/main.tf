module "rg" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
}

module "network" {
  source              = "./modules/network"
  vnet_name           = "devops-vnet"
  address_space       = ["10.0.0.0/16"]
  subnet_prefixes     = ["10.0.1.0/24"]
  resource_group_name = module.rg.name
  location            = module.rg.location
}

module "acr" {
  source              = "./modules/acr"
  name                = "acrdevopsai"
  resource_group_name = module.rg.name
  location            = module.rg.location
}

module "monitor" {
  source              = "./modules/monitor"
  resource_group_name = module.rg.name
  location            = module.rg.location
}

module "aks" {
  source              = "./modules/aks"
  cluster_name        = "aks-devops-ai"
  resource_group_name = module.rg.name
  location            = module.rg.location
  subnet_id           = module.network.subnet_id
  acr_id              = module.acr.id
  log_analytics_id    = module.monitor.workspace_id
}
