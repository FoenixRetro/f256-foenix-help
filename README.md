# Foenix help!

A help system for the Foenix F256 line of computers.


## Installation

The release directory contains everything needed for installing the application in
flash on your F256.

Refere to the README file in that directory on how to install.


## Usage

After installation the program is accessed by typing '/help' from the SuperBASIC
prompt.

You are then presented with a simple menu from which various documents can be
accessed. Documents are selected by pressing the corresponding key next to the
document title. Pressing escape exits out to SuperBASIC.

Inside of a document, the up and down arrow keys are used for flipping between
pages. Escape takes you back to the menu.


## Building

A few tools are required to be able to build the program.

For building we need a native GCC compiler, GNU Make, Python version 3 and the
6502 compiler suite cc65. You will also need FoenixMgr to be able to transfere
the program to your F256.
