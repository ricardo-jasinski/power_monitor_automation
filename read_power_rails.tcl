################################################################################
# Read the ADC channels that measure the current consumption of the FPGA.
#
# Some kits from Altera include an LTC2148 ADC whose differential inputs are
# connected to shunt resistors in series with the power rails that supply 
# current to the FPGA. The ADC is controller by an SLD node that can be 
# controlled via JTAG using the System Console application.
#
# This script reads the 8 ADC channels and outputs the measured values to 
# stdout. Example:
#
# ...
# Rail 1: 0xca 0x0
# Rail 2: 0x3d 0x0
# ...
#
# This output can be parsed by another script which interprets the results.
# This script does not try to calculate the current values because the formulas
# will vary from board to board. Besides, this task is better suited for other
# programming languages such as Ruby.
#
# Compatibility: this script has been tested with:
#   - Cyclone IV GX Transceiver Starter Kit
#   - Cyclone IV GX FPGA Development Kit
#
# Auhor: Ricardo Jasinski
# License: Public domain. Do with this code whatever you want, just don't 
#          hold me responsible for anything.
################################################################################

puts "Script read_power_rails.tcl started."

# Define delay values for inidividual operations
global inter_cmd_delay; set inter_cmd_delay 100 ;# in milliseconds
global ir_delay; set ir_delay 1000 ;# in microseconds
global dr_delay; set dr_delay 1000 ;# in microseconds
global fpga_device;
global max_device; 

# List connected devices and look for the EPM2210 System Controller and Cyclone FPGA
puts "Devices:"
set devices [ get_service_paths device ]
foreach dev $devices { 
    puts "  $dev" 
    if { [string match "*EPM2210*" $dev] } {
        set max_device $dev
    }
    if { [string match "*EP*CGX*" $dev] } {
        set fpga_device $dev
    }
}

# Check if we have all the info we need before proceeding
if { ! [info exists fpga_device] } { puts "Supported FPGAs not detected. Exiting."; exit -1 }
if { ! [info exists max_device] } { puts "CPLD not detected. Exiting."; exit -1 }

# List SLD paths (nodes) and look for the power monitor node (110:8 v0 #0)
global sld_service_path
puts "SLD paths:"
set sld_paths [ get_service_paths sld ]
foreach path $sld_paths { 
    puts "  $path" 
    if { [string match "*(110:8 v0 #0)*" $path] } {
        set sld_service_path $path
    }
}

# Check if we have all the info we need before proceeding
if { ! [info exists sld_service_path] } { puts "SLD node not detected. Exiting."; exit -1 }

# Open service by claiming path since 'open_service' has been deprecated
set sld_node_path [claim_service sld $sld_service_path power_measurement]

# Write a value to the instruction register (IR).
proc write_ir {value} {
	global ir_delay
	global sld_node_path
	global inter_cmd_delay

	# Command arguments:
	# sld_access_ir <service_path> <ir_value> <delay_in_μs>
	sld_access_ir $sld_node_path $value $ir_delay
	after $inter_cmd_delay	
}

# Write (shift in) a value to the data register (DR) and return
# the old value (bits that were shifted out).
proc read_write_dr {values num_bits} {
	global dr_delay
	global sld_node_path
	global inter_cmd_delay

	# Command arguments:
	# sld_access_dr <service_path> <size_in_bits> <delay_in_μs> <list_of_byte_values>
	set response [ sld_access_dr $sld_node_path $num_bits $dr_delay $values ] 
	after $inter_cmd_delay	

	return $response
}

# Do all the necessary steps to read an ADC channel (from 1 to 8).
proc read_adc_channel {channel_number} {
    global fpga_device

	############################################################################
	# Select the ADC channel to read from (0x81 is first channel)
	############################################################################
	
	# IR <- 0 (write command '0' = 'set_read_address')
	write_ir 0
	# DR <- address (0x81 to 0x88) (write data for 'set_read_address' command)
	set address [expr {0x80 + $channel_number}]
	read_write_dr [list $address] 8 

	############################################################################
	# The following IR/DR operations are needed only for the Transceiver Kit
	############################################################################

    # This is a hacky way to detect the FPGA board by looking at the FPGA chip.
    # It could be problematic if we ver use other kits.
    if { [string match *EP4CGX15@* $fpga_device] } {
    	# IR <- 2 (write command '2')
    	write_ir 2
    	# DR <- 0x0 (4 bits)
    	read_write_dr [list 0x0] 4
    }

	############################################################################
	# Read ADC voltage from the configured channel
	############################################################################

	# IR <- 1 (write command '1' = 'read_current_address')
	write_ir 1
	# DR <- 0x0000 (shift in 16 bits, return shifted out value)
	set response [ read_write_dr [list 0x00 0x00] 16 ]

	return $response
}

# Read all 8 rails, printing the hex value read (2x 8-bit values) to stdout.
for {set i 1} {$i <= 8} {incr i} {
	set response [read_adc_channel $i]
	# For the Development Kit, we need to repeat the read operation
	# For the Transceiver Kit, it is not necessary but does no harm
	read_adc_channel $i
	puts "Rail $i: $response"
}

# Clean up after ourselves
close_service sld $sld_node_path