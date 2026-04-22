vlib work
vlog -sv mac_pe.sv
vlog -sv mac_pe_tb.sv
vsim -c mac_pe_tb

run 1000ns
quit