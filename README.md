![TPU Output Comparison](sw(host)/tpu_comparison_plot.png)

### Current Progress: UART Debugging
The RTL is fully simulated and synthesized using Quartus on a DE10-Standard Cyclone V board. However, the physical UART is currently dropping bytes during the chunking process. This results in striped/corrupted images, mostly due to the computation of blank input matrices.
