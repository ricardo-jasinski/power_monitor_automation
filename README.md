# Power Monitor Automation

Scripts in TCL and Ruby for automating the power monitor circuit available in some FPGA boards.

## Background

Some kits from Altera® include an LTC2148 ADC whose differential inputs are
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

```
\altera\14.0\quartus\sopc_builder\bin\system-console --script=read_power_rails.tcl
```

## Compatibility

This script has been tested with:

* Cyclone IV GX Transceiver Starter Kit
* Cyclone IV GX FPGA Development Kit

### Adapting to other FPGA boards and environments

It should be possible to run it with little changes in other platforms compatible with the Power Monitor™ infrastructure. Here are some directions:

* Change the value of QUARTUS_DIR in the Ruby script if it is not `\altera\13.0sp1\quartus`
* Each of the two supported boards have different procedures for reading the ADC samples. You may have to adapt proc read_adc_channel in the TCL script.
* The Ruby script is preconfigured with board information for the two mentioned kits. If you need to change it to support another kit:
   * Find the place in the Ruby script where the variable `rails` is set.
   * Look up the power rail names in the Power Monitor GUI and board schematics.
   * Look up the resistor values on the SMD resistors and in the board schematics.
   * Update the column `ADC_idx` with the index of the ADC channels for each rail.
   * Update the colum `Rail #` with the values you see when you run the TCL script.

Please let me know if you succeed in doing so or if you need any help.

## License

Public domain. Do with this code whatever you want, just don't hold me responsible for anything.

If you find it useful, please drop me a note so that I can gauge how much effort to put into this project. :)

## Legal

Cyclone, Power Monitor, and System Console are trademarks of Altera Corporation.
