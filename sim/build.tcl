# build.tcl
load_package flow

# Create project
project_new mac_project -overwrite

# Set FPGA Device (Change this to your specific board's chip)
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CGXFC7C7F23C8

# Add RTL and SDC files
set_global_assignment -name SYSTEMVERILOG_FILE mac_pe.sv
set_global_assignment -name SDC_FILE constraints.sdc

# Assign a specific pin for your clock (Example: Pin Y2)
set_location_assignment PIN_Y2 -to clk

puts "--- STARTING SYNTHESIS & ROUTING ---"
# This single command runs: Synthesis -> Fitter -> Timing Analyzer -> Assembler (Bitstream)
execute_flow -compile

puts "--- COMPILATION COMPLETE ---"
project_close