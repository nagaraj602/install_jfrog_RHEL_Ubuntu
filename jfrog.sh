#!/bin/bash


distro=$(grep "^ID=" /etc/os-release | cut -d "=" -f2 | tr -d '"')

echo
echo "Installing JFrog Artifactory on $distro..."
echo


if [ "$distro" == "rhel" ]; then

    sudo yum update -y > /dev/null 2>&1
    sudo yum upgrade -y > /dev/null 2>&1
    sudo yum install wget -y > /dev/null 2>&1
    sudo dnf install java-21-openjdk-devel -y > /dev/null 2>&1

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
# Install JFrog Artifactory
# ==============================
ART_VERSION=7.133.17

cd /opt

sudo wget -q https://releases.jfrog.io/artifactory/bintray-artifactory/org/artifactory/oss/jfrog-artifactory-oss/$ART_VERSION/jfrog-artifactory-oss-$ART_VERSION-linux.tar.gz

sudo tar -xvf jfrog-artifactory-oss-$ART_VERSION-linux.tar.gz > /dev/null

# Create dedicated user
sudo useradd -r -m -U -d /opt/artifactory -s /bin/false artifactory || true

# Move to standard path
sudo mv artifactory-oss-$ART_VERSION /opt/artifactory

# Set ownership
sudo chown -R artifactory:artifactory /opt/artifactory


sudo tee /etc/systemd/system/artifactory.service > /dev/null <<EOF
[Unit]
Description=JFrog Artifactory
After=network.target

[Service]
Type=forking
User=artifactory
ExecStart=/opt/artifactory/app/bin/artifactory.sh start
ExecStop=/opt/artifactory/app/bin/artifactory.sh stop
Restart=always
LimitNOFILE=65536
Environment=JAVA_HOME=$JAVA_HOME_PATH

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable artifactory
sudo systemctl start artifactory


echo
echo "Artifactory Status:"
systemctl status artifactory --no-pager

echo
echo "Access URL: http://<your-server-ip>:8081"
echo "Default login: admin / password"
echo
echo "Done."
