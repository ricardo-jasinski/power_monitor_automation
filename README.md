# Power Monitor Automation

Scripts in TCL and Ruby for automating the power monitor circuit available in some FPGA boards.

## Background

Some kits from Altera include an LTC2148 ADC whose differential inputs are
connected to shunt resistors in series with the power rails that supply 
current to the FPGA. The ADC is controller by an SLD node that can be 
controlled via JTAG using the System Console application.

If you know the shunt resistor values, you can calculate the current that
passes through each rail. This is what this script does.

## Installing

There is no installation, just put everything in the same folder.

## Usage

Run the Ruby script. Depending on your environment, you could try:

```console
ruby power_reader.rb
./power_reader.rb
power_reader
```

Here is a sample output:
```console
Board detected: Cyclone IV GX Transceiver Starter Kit
Current readings:
2.5_VCC              0.041 A    Rail 8    0xbf 0x0
1.2_VCCL_GXB         0.068 A    Rail 1    0x3f 0x1
2.5_VCC_GXB          0.057 A    Rail 2    0xa 0x1
2.5_VCCIO            0.006 A    Rail 3    0x1e 0x0
1.2_VCCINT           0.166 A    Rail 4    0xe 0x3
1.2_VCCD_PLL         0.033 A    Rail 5    0x9d 0x0
open                 0.004 A    Rail 6    0x11 0x0
open                 0.005 A    Rail 7    0x16 0x0
```

### Going low-level

If you want, you can bypass the Ruby script and run the TCL script with System Console:


## Compatibility

This script has been tested with:

* Cyclone IV GX Transceiver Starter Kit
* Cyclone IV GX FPGA Development Kit

However, it should be possible to run it with little changes in other platforms. Please let me know if you succeed in doing so.

## License

Public domain. Do with this code whatever you want, just don't hold me responsible for anything.

If you find it useful, please drop me a note, so that I can gauge how much effort to put into this project. ☺

## Legal

Cyclone, Power Monitor, and System Console are trademarks of Altera Corporation.
