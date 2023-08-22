
# Installing help on your F256 computer

Before you can install the application, you need to make sure you have Python 3
installed on your system.

Start by editing either install.bat (for Windows) or install.sh (for Linux/Mac).

You will need to change the serial port. These are set to COM3 and /dev/ttyUSB0
by default, which may already be correct.

Once you have updated the install script, on Windows you can just double click
on the install.bat file. On Linux/Mac you need to open a terminal, and in this
release directory type: sh install.sh


The program and documents will be installed to flash slot $11 - $14. If you
would like to move the program or documents to another slot, just edit the
bulk.csv file before installation.

The program and documents can be moved to any slot in flash.
