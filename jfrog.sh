#!/bin/bash

distro=$(cat /etc/os-release | grep "^ID=" | cut -d "=" -f2 | sed 's/"//g')

echo "Installing JFrog Artifactory on $distro.."

if [ "$distro" == "rhel" ]; then
    sudo yum update -y > /dev/null 2>&1
    sudo yum install -y wget unzip java-25-openjdk > /dev/null 2>&1

    JAVA_HOME_PATH="/usr/lib/jvm/java-25-openjdk"

elif [ "$distro" == "ubuntu" ]; then
    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get install -y wget unzip openjdk-25-jdk > /dev/null 2>&1

    JAVA_HOME_PATH="/usr/lib/jvm/java-25-openjdk-amd64"

else
    echo "Unsupported Distribution - Only RHEL and Ubuntu are supported!!!!"
    exit 1
fi

echo "            -> Done"

# Create user
echo "*****Creating Artifactory user"
sudo useradd -r -m -U -d /opt/artifactory -s /bin/false artifactory 2>/dev/null
echo "            -> Done"

# Download latest Artifactory (using current modern OSS version)
echo "*****Downloading JFrog Artifactory"

cd /opt
sudo rm -rf jfrog* artifactory*

sudo wget -q https://releases.jfrog.io/artifactory/artifactory-oss/jfrog-artifactory-oss-latest.zip
sudo unzip -q jfrog-artifactory-oss-latest.zip -d /opt/artifactory
sudo rm -rf jfrog-artifactory-oss-latest.zip

# Get extracted folder name
ARTI_DIR=$(ls /opt/artifactory | grep artifactory)

# Ownership
sudo chown -R artifactory:artifactory /opt/artifactory

echo "            -> Done"

# Copy service file
echo "*****Configuring Artifactory Service"
sudo cp artifactory.service /etc/systemd/system/artifactory.service
sudo systemctl daemon-reload > /dev/null 2>&1
echo "            -> Done"

# Start service
echo "*****Starting Artifactory Service"
sudo systemctl start artifactory

# Check status
sudo systemctl is-active --quiet artifactory

echo -e "\n################################################################\n"

if [ $? -eq 0 ]; then
    echo "Artifactory installed Successfully"
    echo "Access Artifactory at: http://$(curl -s ifconfig.me):8081"
else
    echo "Artifactory installation failed"
    echo "Check logs in /opt/artifactory"
fi

echo -e "\n################################################################\n"
