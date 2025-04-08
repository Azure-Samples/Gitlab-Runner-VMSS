# Setting up a GitLab Runner on Azure using a VMSS For Linux/Windows

This guide will help you set up a GitLab Runner on Azure using a Virtual Machine Scale Set (VMSS) for Linux. The VMSS will allow you to scale your runners as needed, making it easier to manage your CI/CD pipelines.

Same can be replicated for Windows VMSS as well.

## Table of Contents

- [Setting up a GitLab Runner on Azure using a VMSS For Linux](#setting-up-a-gitlab-runner-on-azure-using-a-vmss-for-linux)
- [Table of Contents](#table-of-contents)
- [Prerequisites](#prerequisites)
- [Steps](#steps)

## Prerequisites

- Azure CLI installed
- Azure developer CLI installed
- GitLab account
- Azure subscription
- Basic knowledge of Azure and GitLab

## Steps

- In your Gitlab account, create a new project or use an existing one. Register a new runner in your project. You will get a registration token that you will use to register the runner on the VMSS.

- You can use the following command to create and configure gitlab runner using Azure CLI. Follow the prompts to set up the runner. You can either pass your own virtual network or let it create a new one for you with address space you specify.

The runner can be provisioned for type linux or windows. The default is linux.

  ```bash
    azd up
  ```

> Note: The Vnet created by module is setup with minimal security best practices configurations for ease of demo. You can modify the security rules as per your requirements.  If you are passing your own Vnet, make sure to open the ports for the runner to communicate with GitLab so that runner can register itself.
