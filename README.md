Power Monitor Automation
========================

Scripts in TCL and Ruby to automate the power monitor circuit available in some FPGA boards.

Background
===========
Some kits from Altera include an LTC2148 ADC whose differential inputs are
connected to shunt resistors in series with the power rails that supply 
current to the FPGA. The ADC is controller by an SLD node that can be 
controlled via JTAG using the System Console application.

If you know the shunt resistor values, you can calculate the current that
passes through each rail. This is what this script does.

Compatibility: this script has been tested with:
  - Cyclone IV GX Transceiver Starter Kit
  - Cyclone IV GX FPGA Development Kit

Auhor: Ricardo Jasinski

License: Public domain. Do with this code whatever you want, just don't hold me responsible for anything.
