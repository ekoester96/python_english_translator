# Real-Time English to Spanish Translator

A Python application that provides real-time voice translation from English to Spanish using Whisper.cpp for speech recognition and Ollama for translation.

## Overview

This tool listens to your microphone, transcribes English speech in real-time using Whisper.cpp, and translates it to Spanish using a local LLM (Ollama). All processing happens locally on your machine - no cloud services required!

## Features

- **Real-time transcription** using Whisper.cpp (fast, local speech-to-text)
- **Local translation** using Ollama (privacy-friendly, no API costs)
- **2-second audio chunks** for responsive feedback
- **Automatic audio resampling** to Whisper's required 16kHz
- **Simple keyboard controls** (Space to start, Q to quit)
- **Customizable language** (currently configured for Spanish)
- **Text wrapping** for readable output

## Demo
```
Real-time translation started (English → Spanish)
Start speaking... Press 'q' to quit

================================================================================
 Hola, ¿cómo estás hoy?
 Me gustaría aprender más sobre inteligencia artificial.
 Este es un programa realmente útil para practicar idiomas.
```

## Prerequisites

- Python 3.8 or higher
- A working microphone
- At least 8GB RAM (for running Whisper and Ollama)
- Linux, macOS, or Windows with WSL

## Installation

### Method 1: Automated Setup (Recommended)

Run the automated setup script that handles everything:
```bash
# Clone the repository
git clone https://github.com/ekoester96/python_english_translator
cd python_english_translator

# Run the setup script
chmod +x setup.sh
./setup.sh
```

The setup script will:
1. Install Python dependencies
2. Download and build Whisper.cpp
3. Download the Whisper model (base.en by default)
4. Install Ollama (if not already installed)
5. Pull the translation model (gemma2:2b by default)

### Method 2: Manual Installation

#### Step 1: Install Python Dependencies
```bash
pip install -r requirements.txt
```

#### Step 2: Install Whisper.cpp
```bash
# Clone whisper.cpp repository
git clone https://github.com/ggerganov/whisper.cpp.git
cd whisper.cpp

# Build whisper.cpp
make

# Download a Whisper model (choose one):
bash ./models/download-ggml-model.sh base.en    # Recommended: Fast, English-only
# bash ./models/download-ggml-model.sh small.en  # More accurate, slower
# bash ./models/download-ggml-model.sh medium.en # Best accuracy, slowest

cd ..
```

#### Step 3: Install Ollama

**Linux:**
```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**macOS:**
```bash
brew install ollama
```

**Windows:**
Download from [https://ollama.com/download](https://ollama.com/download)

#### Step 4: Pull Translation Model
```bash
# Start Ollama service
ollama serve &

# Pull the translation model (choose one):
ollama pull gemma2:2b      # Recommended: Fast, good quality
# ollama pull llama3.2:3b  # Alternative: Slightly larger, good quality
# ollama pull gemma3:4b    # Larger: Better quality, slower
```

#### Step 5: Configure the Script

Edit `translator.py` and update these paths:
```python
MODEL_PATH = "/path/to/whisper.cpp/models/ggml-base.en.bin"
LLM_MODEL = "gemma2:2b"  # Or your chosen model
LANGUAGE = "Spanish"     # Target language
```

## Usage

### Starting the Translator

1. **Start Ollama** (if not already running):
```bash
   ollama serve
```

2. **Run the translator**:
```bash
   python translator.py
```

3. **Controls**:
   - Press **SPACE** to start listening
   - Start speaking in English
   - Press **Q** to quit

### Changing Target Language

Edit the `LANGUAGE` variable in `translator.py`:
```python
LANGUAGE = "French"   # or "German", "Italian", "Portuguese", etc.
```

Then update the translation prompt to match your target language.

### Choosing Different Models

**Whisper Models** (accuracy vs speed):
- `tiny.en` - Fastest, least accurate (~75MB)
- `base.en` - **Recommended balance** (~142MB)
- `small.en` - More accurate (~466MB)
- `medium.en` - Best accuracy, slower (~1.5GB)

**Ollama Models** (quality vs speed):
- `gemma2:2b` - **Recommended** - Fast, good quality
- `llama3.2:3b` - Good balance
- `gemma3:4b` - Better quality, slower
- `llama3.1:8b` - Best quality, needs more RAM

## Configuration

### Audio Settings

Adjust these in the `RealtimeTranslator` class:
```python
self.sample_rate = 44100          # Microphone sample rate
self.target_sample_rate = 16000   # Whisper requires 16kHz
self.chunk_duration = 2           # Seconds per transcription chunk
```

### Translation Prompt

Customize the translation prompt in `_translate_text()`:
```python
prompt = f"""
You are a professional translator. Translate to {LANGUAGE}.
Keep it natural and conversational.
Only output the translation, nothing else.

English: {text}

{LANGUAGE}:
"""
```

## Troubleshooting

### "Binary not found" Error
```bash
# Rebuild whisper.cpp
cd whisper.cpp
make clean
make
```

Update `MODEL_PATH` in `translator.py` to point to your whisper.cpp installation.

### "Model not found" Error
```bash
# Download the model
cd whisper.cpp
bash ./models/download-ggml-model.sh base.en
```

### No Audio Input

**Linux:**
```bash
# Check audio devices
python -c "import sounddevice as sd; print(sd.query_devices())"

# Install PortAudio if needed
sudo apt-get install portaudio19-dev
```

**macOS:**
Grant microphone permissions in System Preferences → Security & Privacy → Microphone

### Ollama Connection Error
```bash
# Check if Ollama is running
curl http://localhost:11434/api/version

# If not running, start it:
ollama serve
```

### Slow Translation

- Use a smaller LLM model: `ollama pull gemma2:2b`
- Use a smaller Whisper model: `base.en` or `tiny.en`
- Reduce chunk duration (but may affect accuracy)
- Close other resource-intensive applications

### Poor Transcription Quality

- Speak clearly and at a moderate pace
- Reduce background noise
- Use a better microphone
- Try a larger Whisper model: `small.en` or `medium.en`
- Increase `chunk_duration` to 3-4 seconds

## System Requirements

### Minimum
- CPU: Dual-core processor
- RAM: 8GB
- Storage: 2GB free space
- Microphone: Any USB or built-in mic

### Recommended
- CPU: Quad-core processor or better
- RAM: 16GB
- Storage: 5GB free space (for larger models)
- Microphone: USB microphone with noise cancellation
- GPU: Apple M1-M5, NVIDIA GPU

## Performance Tips

1. **Use English-only Whisper models** (`.en` suffix) - they're faster
2. **Choose appropriate model sizes** based on your hardware
3. **Close unnecessary applications** to free up RAM
4. **Use a good microphone** in a quiet environment
5. **Adjust chunk duration** - shorter chunks = faster feedback, but may affect accuracy

## Advanced Configuration

### Using GPU Acceleration (NVIDIA)

For Whisper.cpp with CUDA:
```bash
cd whisper.cpp
make clean
WHISPER_CUDA=1 make
```

For Ollama with GPU:
Ollama automatically uses GPU if available - no configuration needed!

### Running as a Service

Create a systemd service on Linux:
```bash
sudo nano /etc/systemd/system/translator.service
```
```ini
[Unit]
Description=Real-time Translator
After=network.target

[Service]
Type=simple
User=yourusername
WorkingDirectory=/path/to/realtime-translator
ExecStart=/usr/bin/python3 translator.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl enable translator
sudo systemctl start translator
```

## File Structure
```
realtime-translator/
├── translator.py          # Main application
├── requirements.txt       # Python dependencies
├── setup.sh              # Automated setup script
├── setup_whisper.sh      # Whisper.cpp setup
├── setup_ollama.sh       # Ollama setup
├── README.md             # This file
└── whisper.cpp/          # Whisper.cpp (after setup)
    ├── build/
    ├── models/
    └── ...
```

## How It Works

1. **Audio Capture**: Records 2-second audio chunks from your microphone
2. **Resampling**: Converts audio from 44.1kHz to 16kHz (Whisper requirement)
3. **Transcription**: Whisper.cpp transcribes English speech to text
4. **Translation**: Ollama translates the text to Spanish
5. **Output**: Displays translated text in the terminal

## Privacy & Security

- **100% Local Processing**: No data sent to external servers
- **No Internet Required**: After initial setup, runs completely offline
- **Your Voice, Your Data**: All audio processing stays on your machine

## Limitations

- English input only (can be modified for other languages)
- Requires decent hardware for real-time processing
- Translation quality depends on the LLM model chosen
- May have slight delay (2-5 seconds) based on hardware

## Contributing

Contributions are welcome! Areas for improvement:

- Support for more languages
- Better error handling and recovery
- GUI interface
- Voice activity detection (to avoid processing silence)
- Custom vocabulary/terminology support
- Export translations to file

## License

[MIT]

## Credits

- **Whisper.cpp**: [ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp)
- **Ollama**: [ollama.com](https://ollama.com)
- **OpenAI Whisper**: Original model by OpenAI

## Support

For issues or questions:
- Open an issue on GitHub
- Check the troubleshooting section
- Review Whisper.cpp documentation
- Review Ollama documentation

## Changelog

### Version 1.0.0
- Initial release
- Real-time English to Spanish translation
- Whisper.cpp integration
- Ollama integration
- Keyboard controls
