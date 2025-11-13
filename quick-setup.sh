#!/bin/bash

# Quick setup with defaults - no prompts
set -e

echo "Quick Setup - Real-Time Translator"
echo "Using default models: whisper base.en + gemma2:2b"
echo ""

# Install Python deps
pip3 install -r requirements.txt

# Setup Whisper
if [ ! -d "whisper.cpp" ]; then
    git clone https://github.com/ggerganov/whisper.cpp.git
    cd whisper.cpp
    make
    bash ./models/download-ggml-model.sh base.en
    cd ..
fi

# Setup Ollama
if ! command -v ollama &> /dev/null; then
    curl -fsSL https://ollama.com/install.sh | sh
fi

# Start Ollama and pull model
ollama serve > /dev/null 2>&1 &
sleep 2
ollama pull gemma2:2b

# Update paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODEL_PATH="${SCRIPT_DIR}/whisper.cpp/models/ggml-base.en.bin"

sed -i "s|MODEL_PATH = \".*\"|MODEL_PATH = \"${MODEL_PATH}\"|" translator.py
sed -i "s|LLM_MODEL = \".*\"|LLM_MODEL = \"gemma2:2b\"|" translator.py

echo ""
echo "Setup complete! Run with: python3 translator.py"
