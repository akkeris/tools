# Install k8s scripts into /usr/local/bin

# Make scripts executable
chmod +x ./kport.sh
chmod +x ./kbounce.sh

# Copy scripts to /usr/local/bin
cp ./kbounce.sh /usr/local/bin/kbounce
cp ./kport.sh /usr/local/bin/kport