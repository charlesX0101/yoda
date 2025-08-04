[[/CharlesX0101]](https://charlesx0101.com/) [[/About]](http://charlesx0101.com/about) [[/Labs]](https://charlesx0101.com/labs) [[/Projects]](https://charlesx0101.com/projects) [[/Contact]](https://charlesx0101.com/contact) 

# YODA-LLM
Your Offline Dialogue Assistant

YODA-LLM is a command-line assistant launcher that runs on Ollama. It offers a simple and portable way to interact with local large language models. This project has a small installation size and doesn’t require any graphical interface. It allows users to easily start, stop, and use LLMs from the terminal on Linux and macOS.

This tool shows more than just scripting ability. It provides full system support, which includes model setup, managing background services, configuring the shell, and handling installation across different platforms.

---

## Features:
yoda start    - Starts the Ollama service in the background
yoda stop     - Gracefully shuts down the Ollama service
yoda ask      - Launches a general-purpose LLM (LLaMA 3)
yoda code     - Launches a coding-focused LLM (DeepSeek Coder)
Installs to ~/.local/bin/yoda and works like any other CLI tool
Automatic model setup on first use

## Supported Platforms:
Linux (tested on most major distributions)
macOS (Intel and Apple Silicon)

Windows is not officially supported. WSL users might run the Linux script with some changes, but this is not guaranteed.

## Installation:

# Linux:
```
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/yoda-llm/main/install.sh | bash
```

# macOS:
```
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/yoda-llm/main/install_macos.sh | bash
```

## System Requirements:
- Ollama (automatically installed if missing)
- Homebrew for macOS (installed if missing)
- At least 8 GB RAM recommended
- Internet connection required to download models
- The yoda command is installed to ~/.local/bin

## Model Handling:

##Linux:
You will be asked if your system has an NVIDIA GPU. If you choose yes, high-performance models (llama3 and deepseek-coder) will be installed. If not, lightweight versions (llama3:8b and deepseek-coder:6.7b) will be used for better compatibility.

##macOS:
macOS systems do not support CUDA acceleration. The installer defaults to lightweight models (llama3:8b and deepseek-coder:6.7b) for performance and stability.

##Shell Configuration:
If ~/.local/bin is not in your PATH, the installer will offer to add it.
- On Linux, this updates ~/.bashrc
- On macOS, this updates ~/.zshrc
You must restart your terminal or manually run 'source' for the changes to take effect.

##Uninstallation:
To uninstall, simply re-run the install script and select the "Uninstall" option. This removes the yoda launcher script but does not remove Ollama or any downloaded models.

##Warning:
Running local LLMs is resource-intensive. High-performance models may consume multiple gigabytes of RAM. This project assumes you understand the performance and power implications of using large models. Use lightweight models on laptops or low-memory systems.

##License:
MIT License

#Author:
Built by charlesx0101 (https://github.com/charlesx0101) as part of a growing portfolio of focused, CLI-based tooling for system automation, scripting, and local AI workflows.
