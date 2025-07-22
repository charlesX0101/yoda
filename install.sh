#!/bin/bash

#==================================================
# YODA-LLM INSTALLER (Linux)
# Your Offline Dialogue Assistant
#==================================================

set -e

INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/yoda"
PID_FILE="/tmp/ollama_pid"

mkdir -p "$INSTALL_DIR"

#--- Welcome ---#
echo "============================================="
echo "     Welcome to YODA-LLM!"
echo "  Your Offline Dialogue Assistant"
echo "============================================="
echo
echo "1) Install YODA-LLM"
echo "2) Uninstall YODA-LLM"
echo "3) Quit"
echo
read -p "Choose an option [1-3]: " CHOICE

#--- Uninstall ---#
if [[ "$CHOICE" == "2" ]]; then
  echo "[info] Uninstalling YODA-LLM..."
  if [[ -f "$TARGET" ]]; then
    rm "$TARGET"
    echo "[✓] Removed $TARGET"
  else
    echo "[!] No YODA script found at $TARGET"
  fi
  exit 0
elif [[ "$CHOICE" == "3" ]]; then
  echo "Goodbye."
  exit 0
elif [[ "$CHOICE" != "1" ]]; then
  echo "[!] Invalid selection"
  exit 1
fi

#--- Check for Ollama ---#
echo "[info] Checking for Ollama..."
if ! command -v ollama &>/dev/null; then
  echo "[warn] Ollama is not installed."
  read -p "Install it now? (Y/n): " INSTALL_OLLAMA
  if [[ "$INSTALL_OLLAMA" =~ ^[Yy]?$ ]]; then
    curl -fsSL https://ollama.com/install.sh | sh
  else
    echo "Please install Ollama manually and re-run this script."
    exit 1
  fi
fi

#--- Start Ollama Service (once) ---#
if ! pgrep -f "ollama serve" > /dev/null; then
  echo "[info] Starting Ollama service..."
  nohup ollama serve >/dev/null 2>&1 &
  sleep 2
fi

#--- Model Selection ---#
echo
read -p "Do you have an NVIDIA GPU? (Y/n): " HAS_GPU
if [[ "$HAS_GPU" =~ ^[Yy]$ ]]; then
  echo "[note] High-performance models use more VRAM and power."
  read -p "Use high-performance models? (Y/n): " USE_HEAVY
  if [[ "$USE_HEAVY" =~ ^[Yy]$ ]]; then
    ASK_MODEL="llama3"
    CODE_MODEL="deepseek-coder"
  else
    ASK_MODEL="llama3:8b"
    CODE_MODEL="deepseek-coder:6.7b"
  fi
else
  ASK_MODEL="llama3:8b"
  CODE_MODEL="deepseek-coder:6.7b"
fi

#--- Pull Models ---#
echo "[info] Ensuring models are available..."
if ! ollama list | grep -q "$ASK_MODEL"; then
  echo "[+] Pulling $ASK_MODEL..."
  ollama run "$ASK_MODEL" <<< "Hello" || {
    echo "[error] Failed to load $ASK_MODEL"
    exit 1
  }
fi

if ! ollama list | grep -q "$CODE_MODEL"; then
  echo "[+] Pulling $CODE_MODEL..."
  ollama run "$CODE_MODEL" <<< "Hello" || {
    echo "[error] Failed to load $CODE_MODEL"
    exit 1
  }
fi

#--- Deploy Full Yoda Script ---#
cat > "$TARGET" <<EOF
#!/bin/bash

PID_FILE="/tmp/ollama_pid"

start_ollama() {
  if pgrep -f "ollama serve" > /dev/null; then
    echo "Serve Ollama already does. No need, there is."
  else
    echo "Waking up... your assistant is."
    nohup ollama serve >/dev/null 2>&1 &
    echo \$! > "\$PID_FILE"
    echo "Started, it has. PID: \$(cat \$PID_FILE)"
  fi
}

stop_ollama() {
  if [[ -f "\$PID_FILE" ]]; then
    PID=\$(cat "\$PID_FILE")
    echo "Sleep now... the force shall rest."
    kill "\$PID" && rm "\$PID_FILE"
    echo "Dreamless, the silence is."
  else
    echo "Mmm. No PID file. Hunt the phantom process, we must..."
    pkill -f "ollama serve" && echo "Banished, the daemon is."
  fi
}

case "\$1" in
  start)
    start_ollama
    ;;
  stop)
    stop_ollama
    ;;
  ask)
    echo "Speak your thoughts. The Master listens..."
    ollama run $ASK_MODEL
    ;;
  code)
    echo "Ah, code we must. Clever, you are..."
    ollama run $CODE_MODEL
    ;;
  *)
    echo "Hmm. Use wisely: yoda [start|stop|ask|code]"
    ;;
esac
EOF

chmod +x "$TARGET"

#--- PATH Check ---#
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo
  echo "[warn] ~/.local/bin is not in your PATH."
  if [[ -f "$HOME/.bashrc" ]]; then
    read -p "Add it to PATH in .bashrc? (Y/n): " ADD_PATH
    if [[ "$ADD_PATH" =~ ^[Yy]?$ ]]; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
      echo "[✓] Added to PATH. Restart your terminal to use 'yoda'."
    fi
  else
    echo "[warn] Could not detect your shell config file. Please add ~/.local/bin to PATH manually."
  fi
fi

#--- Done ---#
echo
echo "[✓] YODA-LLM installed to: $TARGET"
echo "Try: yoda start | yoda ask | yoda code | yoda stop"
echo "Uninstall anytime: ./install.sh and select option 2"
