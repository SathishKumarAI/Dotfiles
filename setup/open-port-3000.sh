#!/bin/bash
# Open port 3000 for local network access
# Run as: sudo bash open-port-3000.sh

sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
echo "Port 3000 opened. Access from other devices at:"
echo "  http://$(hostname -I | awk '{print $1}'):3000"
