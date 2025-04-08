#!/bin/bash

# Script to install Git on a Linux system

# Update the package list
echo "Updating package list..."
sudo apt update -y

# Install Git
echo "Installing Git..."
sudo apt install git -y

# Verify the installation
echo "Verifying Git installation..."
git --version

# Output success message
if [ $? -eq 0 ]; then
  echo "Git has been successfully installed!"
else
  echo "Git installation failed."
  exit 1
fi