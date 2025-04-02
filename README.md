# Setting up a GitLab Runner on Azure using a VMSS For Linux

This guide will help you set up a GitLab Runner on Azure using a Virtual Machine Scale Set (VMSS) for Linux. The VMSS will allow you to scale your runners as needed, making it easier to manage your CI/CD pipelines.

Same can be replicated for Windows VMSS as well.

## Table of Contents

- [Setting up a GitLab Runner on Azure using a VMSS For Linux](#setting-up-a-gitlab-runner-on-azure-using-a-vmss-for-linux)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Steps](#steps)

## Prerequisites

- Azure CLI installed
- GitLab account
- Azure subscription
- Basic knowledge of Azure and GitLab

## Steps

- **Create a Resource Group**: This is where all your resources will be stored.

  ```bash
    az login
    az account set --subscription <your-subscription-id>

    RESOURCE_GROUP_NAME=gitlab-runner

    az group create \
      --name $RESOURCE_GROUP_NAME \
      --location eastus
  ```

- **Create a Virtual Machine Scale Set (VMSS)**: This will allow you to scale your runners as needed. Adjust default options to avoid creating loadbalancer and public IP.

  ```bash
    VMSS_NAME=gitlab-runner-vmss
    VMSS_INSTANCE_COUNT=0
    VMSS_ADMIN_USERNAME=adminuser
    VMSS_ADMIN_PASSWORD=<your-password>

  ```

- Create Project runner token in GitLab project settings

- Update `cloud-init.yml` with your GitLab URL and token. Also add relevant vmss details like resource group name, vmss name, subscription id, etc.

- **Create Runner Manager**: This will manage the runners

  ```bash

    VM_NAME=gitlab-runner-manager

    az vm create  \
      --resource-group $RESOURCE_GROUP_NAME \
      --name $VM_NAME \
      --image Ubuntu2204   \
      --admin-username adminuser   \
      --generate-ssh-keys   \
      --custom-data cloud-init.yml   \
      --size Standard_D8als_v6 \
      --assign-identity

    # Assing identity to permission of Contributor role to subscription

    IDENTITY_PRINCIPAL_ID=$(az vm show --resource-group $RESOURCE_GROUP_NAME --name $VM_NAME --query "identity.principalId" --output tsv)

    az role assignment create \
      --assignee $IDENTITY_PRINCIPAL_ID \
      --role "Contributor" \
      --scope /subscriptions/<your-subscription-id>

  ````
