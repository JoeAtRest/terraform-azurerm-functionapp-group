# This file defines what the variables are in this deployment
# tou can provide them with default values, if you wanted to
# Descriptions a great idea, you don't get that in ARM

variable "subscription_prefix" {
  type        = string
  description = "The subscription prefix. E.g dev-uks-rg-mygroup where dev is the subscription prefix"
}

variable "location_prefix" {
  type        = string
  description = "The location prefix. E.g dev-uks-rg-mygroup where uks is the location prefix"
}

variable "location" {
  type        = string
  description = "Azure datacentre, e.g. uksouth"
}

variable "app_name" {
  type        = string
  description = "The overall name of this app, used to name the resoure group and other singular components"
}

variable "keyvault_secrets" {
  type        = map
  default     = {}
  description = "KeyVault secrets required by the function app"  
  }

variable "tags" {
  type        = map
  default     = {}
  description = "Tags for resources in Azure"
}

variable "functionapps" {
  type = set(object({   
    name              = string 
    zip_path          = string 
    ip_restrictions   = list(string)   
    settings          = map(string)   
    key_settings      = set(object({
      name    = string
      secret  = string
    }))     
  }))
  description = <<EOF
  The set of function apps to deploy
  - The name of the function app
  - The path to zip file containing this function app  
  - Any app settings which do not require key vault
  - Any app settings which do require key vault
  EOF  
}

variable "access-policies" {
  type = set(object({
    tenant_id           = string
    object_id           = string
    key_permissions     = list(string)
    secret_permissions  = list(string)
  }))
  default = []  
  description = <<EOF
  Key  Vault access policies for internal teams, e.g. to provide the Dev Team with full access
  - tenant_id           : The tenant id of the object to provide with a policy
  - object_id           : The object id of the object to provide with a policy
  - key_permissions     : The permissions to provide this object with for keys
  - secret_permissions  : The permissions to provide this object with for secrets
  EOF
}