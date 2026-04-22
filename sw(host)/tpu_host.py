import serial
import time
import numpy as np
import matplotlib.pyplot as plt
from PIL import Image
import sys

# =====================================================================
# 1. HARDWARE CONFIGURATION
# =====================================================================
PORT = 'COM9' 
BAUD_RATE = 115200

# Opcodes matching the Verilog FSM
OP_LOAD_WTS = b'\xAA'
OP_COMPUTE  = b'\xBB'

# =====================================================================
# 2. DATA PREPARATION (FILE LOADING)
# =====================================================================
print("Preparing Data...")

# 4x4 Edge Detection Weight Matrix (Sobel-like)
weights = np.array([
    [-1, -1, -1, -1],
    [-1,  8, -1, -1],
    [-1, -1, -1, -1],
    [ 0,  0,  0,  0]
], dtype=np.int8)

# Convert directly to bytes (preserves two's complement for negative numbers)
weights_bytes = weights.tobytes()

# --- LOAD ACTUAL IMAGE FILE ---
# Change this to whatever image you want to test!
IMAGE_FILENAME = "waves.png" 

try:
    img = Image.open(IMAGE_FILENAME)
    img = img.convert('L') # Convert to grayscale (1-byte per pixel)
    
    # Resize to a multiple of 4 (128x128 is a good size for UART speed vs Quality)
    img = img.resize((128, 128)) 
    original_img = np.array(img, dtype=np.uint8)
    img_h, img_w = original_img.shape
    
except FileNotFoundError:
    print(f"\n[!] ERROR: Cannot find '{IMAGE_FILENAME}'.")
    print("Ensure the image is in the same folder as this script.")
    sys.exit()

# Empty array to hold the hardware output
result_img = np.zeros_like(original_img)

# =====================================================================
# 3. FPGA COMMUNICATION
# =====================================================================
try:
    print(f"Connecting to FPGA on {PORT} at {BAUD_RATE} baud...")
    tpu = serial.Serial(PORT, BAUD_RATE, timeout=2)
    time.sleep(1) # Give port time to open safely
    
    tpu.reset_input_buffer() # Clear any garbage left in the UART buffer

    # --- A. SEND WEIGHTS ---
    print("Sending Opcode 0xAA (Load Weights)...")
    tpu.write(OP_LOAD_WTS)
    tpu.write(weights_bytes)
    time.sleep(0.1) # Brief pause to let FPGA lock weights

    # --- B. PROCESS THE IMAGE IN 4x4 CHUNKS ---
    total_chunks = (img_h // 4) * (img_w // 4)
    print(f"Streaming {total_chunks} pixel blocks to the TPU...")
    
    chunks_processed = 0
    
    for y in range(0, img_h, 4):
        for x in range(0, img_w, 4):
            
            # Extract 4x4 block and convert to bytes
            chunk = original_img[y:y+4, x:x+4]
            chunk_bytes = chunk.tobytes()
            
            # Instruct FPGA to compute, then send data
            tpu.write(OP_COMPUTE)
            tpu.write(chunk_bytes)
            
            # Read back exactly 16 processed bytes
            res_bytes = tpu.read(16)
            
            if len(res_bytes) != 16:
                print(f"\nUART ERROR: Only received {len(res_bytes)} bytes at chunk ({y},{x})")
                continue
                
            # Reconstruct the 4x4 matrix and place it in the result image
            res_chunk = np.frombuffer(res_bytes, dtype=np.uint8).reshape((4, 4))
            result_img[y:y+4, x:x+4] = res_chunk
            
            # Simple progress tracker
            chunks_processed += 1
            if chunks_processed % 100 == 0:
                print(f"  -> Processed {chunks_processed}/{total_chunks} blocks")

    print("\nHardware Processing Complete!")
    tpu.close()

    # =====================================================================
    # 4. DISPLAY & SAVE THE RESULTS
    # =====================================================================
    plt.imsave("tpu_hardware_output.png", result_img, cmap='gray', vmin=0, vmax=255)
    print("Raw output image saved as 'tpu_hardware_output.png'")

    # Show side-by-side comparison on screen
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))
    
    ax1.imshow(original_img, cmap='gray', vmin=0, vmax=255)
    ax1.set_title(f"Original ({img_w}x{img_h})")
    ax1.axis('off')
    
    ax2.imshow(result_img, cmap='gray', vmin=0, vmax=255)
    ax2.set_title("FPGA TPU Output (Edge Detected)")
    ax2.axis('off')
    
    plt.savefig("tpu_comparison_plot.png", bbox_inches='tight', dpi=300)
    print("Comparison plot saved as 'tpu_comparison_plot.png'")
    
    plt.show()

except serial.SerialException as e:
    print("\n[!] CONNECTION FAILED [!]")
    print(f"Error details: {e}")
    print("\nChecklist:")
    print("1. Is the COM port correct? Check Device Manager.")
    print("2. Is the USB FTDI adapter plugged in?")
    print("3. Are the 3 wires (TX, RX, GND) securely connected?")