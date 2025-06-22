#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "--- Starting User Data Script ---"

# Update and install dependencies
echo "Updating and installing system dependencies..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y python3 python3-pip tmux unzip curl

# Install required Python libraries
echo "Installing Python libraries..."
sudo pip3 install --upgrade pip
sudo pip3 install fastapi uvicorn[standard] pillow numpy boto3 rembg[onnx] opencv-python-headless

# Create app directory
echo "Creating application directory..."
sudo mkdir -p /opt/nailcolorizer
cd /opt/nailcolorizer

# Create main FastAPI app
echo "Creating main.py..."
sudo cat << 'EOF' > main.py
from fastapi import FastAPI, UploadFile, Form
from fastapi.responses import StreamingResponse
from rembg import remove
from PIL import Image
import numpy as np
import cv2
from io import BytesIO

app = FastAPI()

@app.post("/recolor")
async def recolor(file: UploadFile, color: str = Form(...)):
    img = Image.open(BytesIO(await file.read())).convert("RGBA")
    fg_image = remove(img)

    fg_np = np.array(fg_image)
    bgr = cv2.cvtColor(fg_np, cv2.COLOR_RGBA2BGR)

    rgb = tuple(int(color.lstrip('#')[i:i+2], 16) for i in (0, 2 ,4))
    overlay = np.full_like(bgr, rgb[::-1])
    mask = fg_np[:, :, 3] > 0
    result = bgr.copy()
    result[mask] = cv2.addWeighted(bgr[mask], 0.5, overlay[mask], 0.5, 0)

    out = Image.fromarray(cv2.cvtColor(result, cv2.COLOR_BGR2RGB))
    buffer = BytesIO()
    out.save(buffer, format="PNG")
    buffer.seek(0)
    return StreamingResponse(buffer, media_type="image/png")
EOF

# Start server in tmux
echo "Starting Uvicorn server in a tmux session..."
sudo tmux new-session -d -s nailcolorizer 'uvicorn main:app --host 0.0.0.0 --port 8000'

echo "--- User Data Script Finished ---"
