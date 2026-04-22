# Micro-TPU: 4x4 Systolic Array Coprocessor

![TPU Output Comparison](sw(host)/tpu_comparison_plot.png)

## Overview
This repository contains the RTL, testbenches, and host software for a custom Micro-Tensor Processing Unit (TPU). The core computational engine is a 4x4 weight-stationary systolic array designed for matrix multiplication and hardware-accelerated image processing. 

##  Current Status: UART Debugging Phase
The RTL is fully simulated and synthesized using Quartus on a Terasic DE10-Standard (Cyclone V) board. 

**Known Issue:** The physical UART interface is currently dropping bytes during the host-to-FPGA data chunking process. This data loss leads to the systolic array computing on empty input matrices, resulting in striped/corrupted output images. Currently working on adding a robust FIFO buffer and flow control to the UART receiver.

## Architecture Highlights
* **Core:** 4x4 Systolic Array (Weight-Stationary Dataflow)
* **Processing Elements:** Custom MAC (Multiply-Accumulate) units
* **Interface:** UART for host PC communication
* **Host Software:** Python-based driver for sending image matrices and plotting hardware output.

## Directory Structure
* `rtl/` - SystemVerilog source files for the TPU and UART controllers.
* `tb/` - Testbenches for module-level and top-level simulation.
* `sim/` - Simulation scripts (ModelSim/Questa).
* `syn/` - Quartus project files and Yosys synthesis scripts.
* `sw/` - Python host scripts for data formatting and visualization.

## Toolchain
* **Hardware Description:** SystemVerilog
* **Synthesis & Implementation:** Intel Quartus Prime / Yosys
* **Verification:** ModelSim / Verilator
* **Host Scripting:** Python 3
