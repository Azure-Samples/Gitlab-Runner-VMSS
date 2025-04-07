#!/bin/bash

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --gitlab-token) GITLAB_TOKEN="$2"; shift ;;
        --subscription-id) AZURE_SUBSCRIPTION_ID="$2"; shift ;;
        --resource-group-name) RESOURCE_GROUP_NAME="$2"; shift ;;
        --username) ADMIN_USERNAME="$2"; shift ;;
        --password) ADMIN_PASSWORD="$2"; shift ;;
        --vmss-name) VMSS_NAME="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Validate required arguments
if [[ -z "$GITLAB_TOKEN" || -z "$AZURE_SUBSCRIPTION_ID" || -z "$RESOURCE_GROUP_NAME" || -z "$ADMIN_USERNAME" || -z "$ADMIN_PASSWORD" || -z "$VMSS_NAME" ]]; then
    echo "Missing required arguments. Please provide all required parameters."
    exit 1
fi

# Update and upgrade packages
apt-get update -y
apt-get upgrade -y

# Install required packages
apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt-get update -y
apt-get install -y docker-ce
systemctl enable docker
systemctl start docker

# Install GitLab Runner
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash
apt-get install -y gitlab-runner

# Create GitLab Runner configuration file
cat <<EOF > /etc/gitlab-runner/config.toml
concurrent = 1
check_interval = 0
shutdown_timeout = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "$RUNNER_NAME"
  url = "https://gitlab.com/"
  token = "$GITLAB_TOKEN"
  token_expires_at = 0001-01-01T00:00:00Z
  executor = "instance"
  [runners.cache]
    MaxUploadedArchiveSize = 0
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.autoscaler]
    plugin = "azure"
    capacity_per_instance = 1
    max_use_count = 1
    max_instances = 10
    [runners.autoscaler.plugin_config]
      name = "$VMSS_NAME"
      subscription_id = "$AZURE_SUBSCRIPTION_ID"
      resource_group_name = "$RESOURCE_GROUP_NAME"
    [runners.autoscaler.connector_config]
      username = "$ADMIN_USERNAME"
      password = "$ADMIN_PASSWORD"
      use_static_credentials = true
      timeout = "10m"
      use_external_addr = true
    [[runners.autoscaler.policy]]
      idle_count = 1
      idle_time = "20m0s"
EOF

# Set permissions for the configuration file
chown -R gitlab-runner:gitlab-runner /etc/gitlab-runner

# Install the autoscaler plugin
gitlab-runner fleeting install

# Register the GitLab Runner
gitlab-runner register --non-interactive \
  --executor "instance" \
  --url "https://gitlab.com/" \
  --token "$GITLAB_TOKEN"

# Restart GitLab Runner service
systemctl restart gitlab-runner

echo "VM configuration completed successfully!"