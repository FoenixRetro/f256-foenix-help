# Installer for Help document viewer

# Change this line to the correct serial port for your computer
port=/dev/ttyUSB0

python3 fnxmgr.zip --port $port --flash-bulk bulk.csv

echo "Help Installed"
