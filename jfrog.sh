#!/bin/bash

# Specify the latest version of JFrog/Artifactory below. You can get the direct link here: https://jfrog.com/community/download-artifactory-oss/
VERSION=7.133.17

path=$(pwd)

# Identifying the distro of the server.
distro=$(cat /etc/os-release | grep "^ID=" | cut -d "=" -f2 | sed 's/"//g')

echo
echo
echo
echo "Installing JFrog/Artifactory on $distro"

if [ "$distro" == "rhel" ]; then

    sudo yum update -y > /dev/null 2>&1
    sudo yum upgrade -y > /dev/null 2>&1
    sudo yum install wget -y > /dev/null 2>&1
    sudo dnf install java-25-openjdk-devel -y > /dev/null 2>&1

elif [ "$distro" == "ubuntu" ]; then

    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get upgrade -y > /dev/null 2>&1
    sudo apt-get install openjdk-25-jdk -y > /dev/null 2>&1

else
    echo "Unsupported Distribution - Only RHEL and Ubuntu are supported by this Script!!!!"
    exit 1
fi


wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/$VERSION/jfrog-artifactory-oss-$VERSION-linux.tar.gz > /dev/null 2>&1

sudo mkdir -p /opt/jfrog
sudo tar -xzf jfrog-artifactory-oss-$VERSION-linux.tar.gz -C /opt/jfrog > /dev/null 2>&1

cd /opt/jfrog
sudo mv artifactory-oss-* artifactory

sudo useradd -r -m -U -d /opt/jfrog/artifactory -s /bin/bash artifactory

sudo chown -R artifactory:artifactory /opt/jfrog

sudo cp $path/artifactory.service /etc/systemd/system/artifactory.service

sudo systemctl daemon-reexec
sudo systemctl daemon-reload

sudo systemctl enable artifactory
sudo systemctl start artifactory > /dev/null 2>&1

echo "JFrog/Artifactory installed the $distro successfully."
echo "You can access with the URL: http://$(curl -s ifconfig.me):8082\n"
echo -e "\n\n\nYou can check the port here: /opt/jfrog/artifactory/var/etc/system.yaml  --> externalPort: 8082"
