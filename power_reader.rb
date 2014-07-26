#!/usr/bin/env ruby

################################################################################
# Invoke script read_power_rails.tcl and interpret the results, presenting
# the current values for each power rail.
#
# Compatibility: this script has been tested with:
#   - Cyclone IV GX Transceiver Starter Kit
#   - Cyclone IV GX FPGA Development Kit
#
# Auhor: Ricardo Jasinski
# License: Public domain. Do with this code whatever you want, just don't 
#          hold me responsible for anything.
################################################################################

# User configurable switches, enable or disable as desired
config = {}
# config[:print_script_output] = true            # print script output
config[:redirect_stderr_to_stdout] = true     # make system console output quieter
config[:highlight_unexpected_values] = true   # compare current reading against expected values

QUARTUS_DIR = '\altera\13.0sp1\quartus'

################################################################################
# Supporting classes for the application.
################################################################################

# Data structure for holding all the information required to read and interpret
# an ADC read corresponding to a current value.
class RailConfig
  attr_reader :name, :resistor_ohms, :power_monitor_list_index, :adc_channel_index, :rail_num_from_script

  def initialize(name, resistor_ohms, power_monitor_list_index, adc_channel_index, rail_num_from_script)
    @name = name
    @resistor_ohms = resistor_ohms
    @power_monitor_list_index = power_monitor_list_index
    @adc_channel_index = adc_channel_index
    @rail_num_from_script = rail_num_from_script
  end
end

################################################################################
# Support routines for the application.
################################################################################

# Find a line containing the given string in the TCL script output.
def get_line_matching(str)
  $script_output.each do |line|
    return line if line.include?(str)
  end
  return nil
end

# Extract only the part of the line that corresponds to a sample value 
# read from the ADC.
def hex_value_from_line(line)
  line.split(": ").last
end

# Extract only the part of the line that corresponds to a sample value 
# read from the ADC.
def sample_value_from_line(line)
  hex_str = line.split(": ").last
  hex_bytes = hex_str.split(" ")
  hex_bytes[0].hex + 256 * hex_bytes[1].hex
end

# Convert the sample value read from the ADC (decimal) to a voltage value (float).
def voltage_from_adc_sample(adc_sample)
  # VREF is 5.35 in the Cyclone IV GX Transceiver Starter Kit and Cyclone IV GX
  # FPGA Development Kit (even though the schematics say it should be 5.0V)
  v_ref = 5.35
  num_steps = 2**23
  v_rail = adc_sample * v_ref / num_steps
end


def current_from_line(line, resistor_ohms)
  adc_sample = sample_value_from_line(line)
  volt_read = voltage_from_adc_sample(adc_sample)
  current = volt_read / resistor_ohms
end


################################################################################
# Start of script code (application starts here).
################################################################################

BASE_DIR = Dir.exists?('\eda\\') ? "\\eda\\#{QUARTUS_DIR}" : $QUARTUS_DIR
cmd_line = BASE_DIR + '\sopc_builder\bin\system-console --script=read_power_rails.tcl'
cmd_line += ' 2>&1' if config[:redirect_stderr_to_stdout]

# Run system-console and capture its output
puts 'Starting system console...'
system_console_output = `#{cmd_line}`
puts 'System console exited.'

# We are interested only in the output that we generated (script output)
$script_output = []
script_output_started = false
system_console_output.lines do |line|
  if script_output_started
    $script_output << line
  elsif line =~ /Script read_power_rails.tcl started./
    script_output_started = true
  end    
end

# Show script output if requested
if config[:print_script_output]
  puts "Script output:"
  puts $script_output
end

# Assume a different FPGA board depending on the FPGA chip detected
if get_line_matching('EP4CGX150@')
  $BOARD = :civgx_development_kit
  puts 'Board detected: Cyclone IV GX FPGA Development Kit'
elsif get_line_matching('EP4CGX15@')
  $BOARD = :civgx_transceiver_kit
  puts 'Board detected: Cyclone IV GX Transceiver Starter Kit'
end

# Define the rails from each FPGA board
if $BOARD == :civgx_transceiver_kit
  rails = [       # Rail name            Res    PM_idx  ADC_idx  Rail#
    RailConfig.new("2.5_VCC",            0.003,      0,       0,     8),
    RailConfig.new("1.2_VCCL_GXB",       0.003,      1,       1,     1),
    RailConfig.new("2.5_VCC_GXB",        0.003,      2,       2,     2),
    RailConfig.new("2.5_VCCIO",          0.003,      3,       3,     3),
    RailConfig.new("1.2_VCCINT",         0.003,      4,       4,     4),
    RailConfig.new("1.2_VCCD_PLL",       0.003,      5,       5,     5),
    RailConfig.new("open",               0.003,    nil,       6,     6),
    RailConfig.new("open",               0.003,    nil,       7,     7)
  ]  
elsif $BOARD == :civgx_development_kit
  rails = [       # Rail name            Res    PM_idx  ADC_idx  Rail#
    RailConfig.new("VCCA",               0.003,      0,       0,     1),
    RailConfig.new("2.5V_VCCA_VCCH_GXB", 0.003,      1,       1,     2),
    RailConfig.new("2.5V_B5_B6",         0.009,      2,       2,     3),
    RailConfig.new("1.8V_B3_B4",         0.009,      3,       3,     4),
    RailConfig.new("1.8V_B7_B8",         0.009,      4,       4,     5),
    RailConfig.new("VCC",                0.003,      5,       5,     6),
    RailConfig.new("1.2V_VCCL_GXB",      0.003,      6,       6,     7),
    RailConfig.new("VCCD_PLL",           0.003,      7,       7,     8)
  ]
end

# Print results
if not config[:highlight_unexpected_values]
  puts "Current readings:"

  rails.each_with_index do |rail, i|
    rail_num = rail.adc_channel_index + 1
    line = get_line_matching("Rail #{rail.rail_num_from_script}")
    current = current_from_line(line, rail.resistor_ohms)
    puts "#{rail.name.ljust(20)} #{current.round(3).to_s.ljust(5)} A    Rail #{rail.rail_num_from_script}    #{hex_value_from_line(line)}"
  end
end


################################################################################
# Optional: log results to a CSV file.
################################################################################

# Append results to CSV file
# open('results.csv', 'a') do |file|
#   file.puts( current_reads.join(', ') )
# end 


################################################################################
# Optional: check output values by comparing with expected values measured
# with the Power Monitor GUI and the default designs from each board.
################################################################################

def format_current_reading(reading, rail)
  if $BOARD == :civgx_transceiver_kit
    expected_readings = [ 0.040, 0.067, 0.057, 0.006, 0.168, 0.033, 0.000, 0.000 ]
  elsif $BOARD == :civgx_development_kit
    expected_readings = [ 0.043, 0.011, 0.000, 0.000, 0.004, 0.304, 0.004, 0.027 ]
  end

  formatted_reading = reading.round(3).to_s.ljust(5)

  if (reading - expected_readings[rail.adc_channel_index]).abs < 0.005
    return formatted_reading
  else
    return (formatted_reading + " (exp #{expected_readings[rail.adc_channel_index]})")
  end
end 

if config[:highlight_unexpected_values]
  puts "Highlighted current readings:"

  rails.each_with_index do |rail, i|
    rail_num = rail.adc_channel_index + 1
    line = get_line_matching("Rail #{rail.rail_num_from_script}")
    current = current_from_line(line, rail.resistor_ohms)
    puts "#{rail.name.ljust(20)} #{format_current_reading(current, rail)} A    Rail #{rail.rail_num_from_script}    #{hex_value_from_line(line)}"
  end
end