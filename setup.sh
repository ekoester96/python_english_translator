#!/bin/bash

# Real-Time Translator Setup Script
# This script automates the installation of all dependencies

set -e  # Exit on error

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "\n${BLUE}==>${NC} $1"
}

# Check if running on supported OS
check_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        print_error "Unsupported operating system: $OSTYPE"
        print_info "This script supports Linux and macOS"
        exit 1
    fi
    print_info "Detected OS: $OS"
}

# Check for required tools
check_requirements() {
    print_step "Checking requirements..."
    
    # Check Python
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        exit 1
    fi
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_info "Python version: $PYTHON_VERSION"
    
    # Check pip
    if ! command -v pip3 &> /dev/null; then
        print_error "pip3 is not installed"
        exit 1
    fi
    
    # Check git
    if ! command -v git &> /dev/null; then
        print_error "git is not installed"
        exit 1
    fi
    
    # Check make
    if ! command -v make &> /dev/null; then
        print_warning "make is not installed"
        print_info "Installing build tools..."
        if [ "$OS" == "linux" ]; then
            sudo apt-get update
            sudo apt-get install -y build-essential
        elif [ "$OS" == "macos" ]; then
            xcode-select --install
        fi
    fi
}

# Install Python dependencies
install_python_deps() {
    print_step "Installing Python dependencies..."
    
    # Install PortAudio (required for sounddevice)
    if [ "$OS" == "linux" ]; then
        print_info "Installing PortAudio..."
        sudo apt-get update
        sudo apt-get install -y portaudio19-dev python3-dev
    elif [ "$OS" == "macos" ]; then
        if command -v brew &> /dev/null; then
            print_info "Installing PortAudio..."
            brew install portaudio
        else
            print_warning "Homebrew not found. Please install PortAudio manually."
        fi
    fi
    
    print_info "Installing Python packages..."
    pip3 install -r requirements.txt
    print_info "Python dependencies installed successfully"
}

# Setup Whisper.cpp
setup_whisper() {
    print_step "Setting up Whisper.cpp..."
    
    if [ -d "whisper.cpp" ]; then
        print_warning "whisper.cpp directory already exists"
        read -p "Do you want to reinstall? (y/n): " reinstall
        if [ "$reinstall" != "y" ]; then
            print_info "Skipping Whisper.cpp installation"
            return
        fi
        rm -rf whisper.cpp
    fi
    
    print_info "Cloning Whisper.cpp repository..."
    git clone https://github.com/ggerganov/whisper.cpp.git
    
    cd whisper.cpp
    
    print_info "Building Whisper.cpp..."
    make
    
    print_info "Whisper.cpp built successfully"
    
    # Download model
    print_step "Downloading Whisper model..."
    echo "Available models:"
    echo "  1) tiny.en   - Fastest, least accurate (~75MB)"
    echo "  2) base.en   - Recommended balance (~142MB)"
    echo "  3) small.en  - More accurate (~466MB)"
    echo "  4) medium.en - Best accuracy (~1.5GB)"
    echo ""
    read -p "Select model (1-4, default: 2): " model_choice
    
    case ${model_choice:-2} in
        1) MODEL="tiny.en" ;;
        2) MODEL="base.en" ;;
        3) MODEL="small.en" ;;
        4) MODEL="medium.en" ;;
        *) MODEL="base.en" ;;
    esac
    
    print_info "Downloading $MODEL model..."
    bash ./models/download-ggml-model.sh $MODEL
    
    cd ..
    
    # Update MODEL_PATH in translator.py
    MODEL_FILE="whisper.cpp/models/ggml-${MODEL}.bin"
    print_info "Updating MODEL_PATH in translator.py..."
    
    # Get absolute path
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    FULL_MODEL_PATH="${SCRIPT_DIR}/${MODEL_FILE}"
    
    # Update the Python script
    if [[ "$OS" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|MODEL_PATH = \".*\"|MODEL_PATH = \"${FULL_MODEL_PATH}\"|" translator.py
    else
        # Linux
        sed -i "s|MODEL_PATH = \".*\"|MODEL_PATH = \"${FULL_MODEL_PATH}\"|" translator.py
    fi
    
    print_info "Whisper.cpp setup complete"
}

# Setup Ollama
setup_ollama() {
    print_step "Setting up Ollama..."
    
    if command -v ollama &> /dev/null; then
        print_info "Ollama is already installed"
        OLLAMA_VERSION=$(ollama --version 2>&1 | head -n1)
        print_info "Version: $OLLAMA_VERSION"
    else
        print_info "Installing Ollama..."
        
        if [ "$OS" == "linux" ]; then
            curl -fsSL https://ollama.com/install.sh | sh
        elif [ "$OS" == "macos" ]; then
            if command -v brew &> /dev/null; then
                brew install ollama
            else
                print_error "Please install Homebrew first, then run: brew install ollama"
                exit 1
            fi
        fi
        
        print_info "Ollama installed successfully"
    fi
    
    # Start Ollama service
    print_info "Starting Ollama service..."
    if [ "$OS" == "linux" ]; then
        if systemctl is-active --quiet ollama; then
            print_info "Ollama service is already running"
        else
            sudo systemctl start ollama
            sudo systemctl enable ollama
        fi
    elif [ "$OS" == "macos" ]; then
        # Start Ollama in background
        if pgrep -x "ollama" > /dev/null; then
            print_info "Ollama is already running"
        else
            ollama serve > /dev/null 2>&1 &
            sleep 2
        fi
    fi
    
    # Pull translation model
    print_step "Downloading translation model..."
    echo "Available models:"
    echo "  1) gemma2:2b  - Recommended: Fast, good quality"
    echo "  2) llama3.2:3b - Good balance"
    echo "  3) gemma3:4b   - Better quality, slower (default in script)"
    echo "  4) llama3.1:8b - Best quality, needs more RAM"
    echo ""
    read -p "Select model (1-4, default: 1): " llm_choice
    
    case ${llm_choice:-1} in
        1) LLM="gemma2:2b" ;;
        2) LLM="llama3.2:3b" ;;
        3) LLM="gemma3:4b" ;;
        4) LLM="llama3.1:8b" ;;
        *) LLM="gemma2:2b" ;;
    esac
    
    print_info "Pulling $LLM model (this may take a few minutes)..."
    ollama pull $LLM
    
    # Update LLM_MODEL in translator.py
    print_info "Updating LLM_MODEL in translator.py..."
    if [[ "$OS" == "darwin"* ]]; then
        sed -i '' "s|LLM_MODEL = \".*\"|LLM_MODEL = \"${LLM}\"|" translator.py
    else
        sed -i "s|LLM_MODEL = \".*\"|LLM_MODEL = \"${LLM}\"|" translator.py
    fi
    
    print_info "Ollama setup complete"
}

# Test installation
test_installation() {
    print_step "Testing installation..."
    
    # Test Python imports
    print_info "Testing Python dependencies..."
    python3 -c "
import sounddevice
import scipy
import numpy
import requests
import readchar
print('All Python packages imported successfully')
" || {
    print_error "Python dependency test failed"
    exit 1
}
    
    # Test Whisper binary
    print_info "Testing Whisper.cpp binary..."
    if [ -f "whisper.cpp/build/bin/whisper-cli" ]; then
        print_info "Whisper binary found"
    else
        print_error "Whisper binary not found"
        exit 1
    fi
    
    # Test Ollama
    print_info "Testing Ollama connection..."
    if curl -s http://localhost:11434/api/version > /dev/null; then
        print_info "Ollama is responding"
    else
        print_warning "Ollama may not be running properly"
    fi
    
    print_info "All tests passed!"
}

# Main installation flow
main() {
    clear
    echo "=========================================="
    echo "  Real-Time Translator Setup"
    echo "=========================================="
    echo ""
    
    check_os
    check_requirements
    install_python_deps
    setup_whisper
    setup_ollama
    test_installation
    
    print_step "Setup Complete!"
    echo ""
    print_info "You can now run the translator with:"
    echo "  python3 translator.py"
    echo ""
    print_info "Make sure Ollama is running:"
    echo "  ollama serve"
    echo ""
    print_info "For more information, see README.md"
}

# Run main installation
main
