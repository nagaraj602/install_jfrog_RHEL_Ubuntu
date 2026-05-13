#!/bin/bash

set -e

distro=$(cat /etc/os-release | grep "^ID=" | cut -d "=" -f2 | sed 's/"//g')

echo
echo "Installing JFrog Artifactory on $distro..."
echo

# ==============================
# Install Java (your logic)
# ==============================
if [ "$distro" == "rhel" ] || [ "$distro" == "amzn" ]; then

    sudo yum update -y > /dev/null 2>&1
    sudo yum upgrade -y > /dev/null 2>&1
    sudo yum install wget -y > /dev/null 2>&1
    sudo dnf install java-21-openjdk-devel -y > /dev/null 2>&1
    sudo yum install java-21-amazon-corretto -y > /dev/null 2>&1

elif [ "$distro" == "ubuntu" ]; then

    sudo apt-get update -y > /dev/null 2>&1
    sudo apt-get upgrade -y > /dev/null 2>&1
    sudo apt-get install openjdk-21-jdk -y > /dev/null 2>&1

else
    echo "Unsupported Distribution - Only RHEL and Ubuntu supported!"
    exit 1
fi

# ==============================
# Detect JAVA_HOME
# ==============================
JAVA_HOME_PATH=$(dirname $(dirname $(readlink -f $(which javac))))


# ==============================
# CLEAN OLD INSTALLATION
# ==============================
echo "Cleaning old Artifactory installation..."

# Stop service if exists
sudo systemctl stop artifactory 2>/dev/null || true

# Kill any running processes
sudo pkill -f artifactory 2>/dev/null || true
sudo pkill -f '/opt/artifactory' 2>/dev/null || true

# Remove old PID files
sudo rm -rf /opt/artifactory/var/work/run/*.pid 2>/dev/null || true

# Remove old directory
sudo rm -rf /opt/artifactory

# ==============================
# Install JFrog Artifactory
# ==============================
ART_VERSION=7.133.17

cd /opt

sudo wget -q https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/$ART_VERSION/jfrog-artifactory-oss-$ART_VERSION-linux.tar.gz

# Create directory
sudo mkdir -p /opt/artifactory

# Extract properly (no nested folder)
sudo tar -xzf jfrog-artifactory-oss-$ART_VERSION-linux.tar.gz -C /opt/artifactory --strip-components=1

# Create user (only if not exists)
id artifactory &>/dev/null || sudo useradd -r -m -U -d /opt/artifactory -s /bin/false artifactory

# Set permissions
sudo chown -R artifactory:artifactory /opt/artifactory
sudo chmod +x /opt/artifactory/app/bin/artifactory.sh

# ==============================
# Create systemd service
# ==============================


sudo tee /etc/systemd/system/artifactory.service > /dev/null <<EOF
[Unit]
Description=JFrog Artifactory
After=network.target

[Service]
Type=simple
User=artifactory
ExecStart=/opt/artifactory/app/bin/artifactory.sh
ExecStop=/opt/artifactory/app/bin/artifactory.sh stop
Restart=always
LimitNOFILE=65536
Environment=JAVA_HOME=$JAVA_HOME_PATH

[Install]
WantedBy=multi-user.target
EOF

# ==============================
# Start service
# ==============================


sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable artifactory
sudo systemctl start artifactory

# ==============================
# Status
# ==============================
echo
echo "Artifactory Status:"
systemctl status artifactory --no-pager


echo
echo "Access URL: http://$(curl -s ifconfig.me):8081"
echo "User: admin"
echo "Password: password"
echo
echo "Done."
