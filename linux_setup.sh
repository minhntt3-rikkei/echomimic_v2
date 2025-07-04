#!/bin/bash

# Install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc

# Create virtual environment
uv venv -p 3.11
source .venv/bin/activate

# Function to check file existence
verify_file() {
    if [ ! -f "$1" ]; then
        echo "Missing file: $1"
        echo "Please ensure the file structure is correct or download the file."
        exit 1
    fi
}

# Function to check directory existence
verify_dir() {
    if [ ! -d "$1" ]; then
        echo "Creating missing directory: $1"
        mkdir -p "$1"
    fi
}

# Install dependencies
echo "Installing dependencies..."
uv pip install torch torchvision torchaudio xformers --index-url https://download.pytorch.org/whl/cu128
uv pip install torchao
if [ -f "requirements.in" ]; then
    uv pip install -r requirements.in
else
    echo "requirements.in not found. Skipping requirements installation."
fi

# Install FFmpeg
if [ ! -d "ffmpeg-4.4-amd64-static" ]; then
    echo "Downloading and extracting FFmpeg..."
    wget https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.4-amd64-static.tar.xz
    tar -xvf ffmpeg-4.4-amd64-static.tar.xz
else
    echo "FFmpeg already downloaded and extracted. Skipping."
fi
export FFMPEG_PATH="$PWD/ffmpeg-4.4-amd64-static"

# Initialize git LFS and clone pretrained weights
if ! git lfs env &>/dev/null; then
    echo "Initializing Git LFS..."
    git lfs install
else
    echo "Git LFS already initialized. Skipping."
fi

if [ ! -d "pretrained_weights" ]; then
    echo "Cloning pretrained weights repository..."
    git clone https://huggingface.co/BadToBest/EchoMimicV2 pretrained_weights
else
    echo "Pretrained weights directory already exists. Skipping clone."
fi

# Clone additional repositories
echo "Verifying additional repositories..."
verify_dir "./pretrained_weights/sd-vae-ft-mse"
if [ -z "$(ls -A ./pretrained_weights/sd-vae-ft-mse)" ]; then
    git clone https://huggingface.co/stabilityai/sd-vae-ft-mse ./pretrained_weights/sd-vae-ft-mse
else
    echo "sd-vae-ft-mse repository already exists. Skipping clone."
fi

verify_dir "./pretrained_weights/sd-image-variations-diffusers"
if [ -z "$(ls -A ./pretrained_weights/sd-image-variations-diffusers)" ]; then
    git clone https://huggingface.co/lambdalabs/sd-image-variations-diffusers ./pretrained_weights/sd-image-variations-diffusers
else
    echo "sd-image-variations-diffusers repository already exists. Skipping clone."
fi

# Verify required model files in pretrained_weights
echo "Checking required model files in pretrained_weights..."
verify_file "./pretrained_weights/denoising_unet.pth"
verify_file "./pretrained_weights/reference_unet.pth"
verify_file "./pretrained_weights/motion_module.pth"
verify_file "./pretrained_weights/pose_encoder.pth"

# Set up audio processor inside pretrained_weights and download tiny.pt
AUDIO_PROCESSOR_DIR="./pretrained_weights/audio_processor"
verify_dir "$AUDIO_PROCESSOR_DIR"
cd "$AUDIO_PROCESSOR_DIR" || exit

if [ ! -f "tiny.pt" ]; then
    echo "Downloading tiny.pt model..."
    wget https://openaipublic.azureedge.net/main/whisper/models/65147644a518d12f04e32d6f3b26facc3f8dd46e5390956a9424a650c0ce22b9/tiny.pt
else
    echo "tiny.pt model already exists. Skipping download."
fi
cd ../..

# Install yolox_l.onnx and dw-ll_ucoco_384.onnx
MODEL_DIR="./models"
verify_dir "$MODEL_DIR"
cd "$MODEL_DIR" || exit

if [ ! -f "yolox_l.onnx" ]; then
    echo "Downloading yolox_l.onnx model..."
    wget https://huggingface.co/yzd-v/DWPose/resolve/main/yolox_l.onnx
else
    echo "yolox_l.onnx model already exists. Skipping download."
fi
if [ ! -f "dw-ll_ucoco_384.onnx" ]; then
    echo "Downloading dw-ll_ucoco_384.onnx model..."
    wget https://huggingface.co/yzd-v/DWPose/resolve/main/dw-ll_ucoco_384.onnx
else
    echo "dw-ll_ucoco_384.onnx model already exists. Skipping download."
fi
cd ../..

# Set up CUDA environment to use python cudnn if not globally installed
export LD_LIBRARY_PATH=$PWD/.venv/lib/python3.11/site-packages/nvidia/cudnn/lib:$LD_LIBRARY_PATH

# Install FFmpeg Enviroment
if ! dpkg -l | grep -q ffmpeg; then
    echo "Installing FFmpeg enviroment..."
    sudo apt update && sudo apt install -y ffmpeg
else
    echo "FFmpeg enviroment already installed. Skipping."
fi

echo "Setup complete!"
