#**************************************************************
# Time Information
#**************************************************************
set_time_format -unit ns -decimal_places 3

#**************************************************************
# 1. Create Clock (Set to 50MHz. Change to 10.000 for 100MHz)
#**************************************************************
create_clock -name {clk} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk}]

#**************************************************************
# 2. Derive Clock Uncertainty 
# (This auto-calculates jitter so you don't need all those manual lines)
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# 3. Asynchronous False Paths (Tell Quartus to ignore slow physical pins)
#**************************************************************
# Human button press is asynchronous
set_false_path -from [get_ports {rst}] -to *

# UART RX is asynchronous to our system clock
set_false_path -from [get_ports {rx}] -to *

# UART TX is asynchronous to our system clock
set_false_path -from * -to [get_ports {tx}]
set_false_path -from * -to [get_ports {tx}]