#!/bin/bash

path=$(pwd)

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



# Create user
sudo useradd -r -m -U -d /opt/artifactory -s /bin/false artifactory 2>/dev/null


# Download latest Artifactory (using current modern OSS version)
cd /opt
sudo rm -rf jfrog* artifactory*

sudo wget https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/7.77.3/jfrog-artifactory-oss-7.77.3-linux.tar.gz > /dev/null 2>&1

sudo tar -xvzf jfrog-artifactory-oss-7.77.3-linux.tar.gz

sudo mv artifactory-oss-7.77.3 /opt/artifactory > /dev/null 2>&1
sudo rm -rf jfrog-artifactory-oss-7.77.3-linux.tar.gz > /dev/null 2>&1

sudo chown -R artifactory:artifactory /opt/artifactory > /dev/null 2>&1

# Copy service file
sudo cp $path/artifactory.service /etc/systemd/system/artifactory.service
sudo systemctl daemon-reload
# Start service
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
