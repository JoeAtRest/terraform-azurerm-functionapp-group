# terraform-functionapp-group

## Deploys a resource group with 1 or more function apps, keyvault and application insights

This module deploys a resource group which can contain

- 1 or more function apps
- A keyvault, which the function apps can use to store secrets
- An application insights which the function apps use

## Simple Usage

Include the module in you main.tf file along with the variables you need to pass in

```hcl
module "terraform-functionapp-group" {
    source = "JoeAtRest/functionapp-group/azurerm"

    subscription_prefix = "dev"
    location_prefix = "uks"
    location = "uksouth"

    # App name will form part of the name for app insights and the resource group
    app_name = "mytestgroup"

    # Any secrets you want to put into the key vault
    keyvault_secrets = { "secret-name" : "the secret", "secret-name2" : "squirrel" }

    # Any tags you want on everything which supports tags in this deployment
    tags = { "Solution" : "Test" }

    # Definition for the function apps you want to create
    functionapps = [{
        name              = "fa-1"

        # This is the path to the zip file containing the function app
        zip_path          = "local/fa1"

        # A list of any IP restrictions, the function app will then only accept
        # requests from IP addresses on this list
        ip_restrictions   = ["192.168.1.23","200.32.29.4"]

        # The function apps settings that do not require key vault
        settings          = { "NameInFuctionApp" = "https://some-url" ,  "OtherThingInFunctionApp" = "false" }

        # The function app settings which do require keyvault, the name is the name which will appear
        # in the app settings ( as you refer to it in the code ) and the secret is the name of the
        # secret you must create in keyvault_secrets
        key_settings      = [{ name = "mysecret", secret = "secret1" },{name = "myothersecret", secret = "secret2"}]
    }]

    # Any acccess policies you want to set in keyvault
    access-policies = []

}
```

You can configure the module directly in your main.tf, as shown above but can also handle the variables in a terraform.tfvars file, or a *.auto.tfvars files. If so you need to make sure your main.tf passes them to the module, as in the top example.

```hcl
module "terraform-functionapp-group" {
    source = "JoeAtRest/functionapp-group/azurerm"

    subscription_prefix = var.subscription_prefix
    location_prefix = var.location_prefix
    location = var.location
    app_name = var.app_name
    keyvault_secrets = var.keyvault_secrets
    tags = var.tags
    functionapps = var.functionapps
    access-policies = var.access-policies
}
```

This allows you split the variables up into subscription/location specific files and maintain things like the keyvault secrets in Azure secure files

### Function App Files

The function apps require zip files, containing the code you have built in your pipeline. These are stored in a storage blob, from where the function app runs them.

When you create the zip files to be deployed you need to ensure they have a unique name, if they do not have a unique name then terraform will assume they have not changed and not update them
