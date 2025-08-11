#!/bin/bash
#==================================================
# YODA-LLM INSTALLER (Linux)
# Your Offline Dialogue Assistant
#==================================================

set -euo pipefail

# Ensure interactive prompts work even when run via: curl ... | bash
if [ ! -t 0 ]; then
  exec </dev/tty
fi

prompt() {
  # usage: var=$(prompt "Message: ")
  local __ans
  read -r -p "$1" __ans
  printf '%s' "$__ans"
}

INSTALL_DIR="$HOME/.local/bin"
TARGET="$INSTALL_DIR/yoda"
PID_FILE="/tmp/ollama_pid"

mkdir -p "$INSTALL_DIR"

echo "============================================="
echo "     Welcome to YODA-LLM!"
echo "  Your Offline Dialogue Assistant"
echo "============================================="
echo
echo "1) Install YODA-LLM"
echo "2) Uninstall YODA-LLM"
echo "3) Quit"
echo

CHOICE="$(prompt 'Choose an option [1-3]: ')"

case "$CHOICE" in
  2)
    echo "[info] Uninstalling YODA-LLM..."
    if [[ -f "$TARGET" ]]; then
      rm -f "$TARGET"
      echo "[✓] Removed $TARGET"
    else
      echo "[!] No YODA script found at $TARGET"
    fi
    exit 0
    ;;
  3)
    echo "Goodbye."
    exit 0
    ;;
  1)
    ;;
  *)
    echo "[!] Invalid selection"
    exit 1
    ;;
esac

echo "[info] Checking for Ollama..."
if ! command -v ollama >/dev/null 2>&1; then
  echo "[warn] Ollama is not installed."
  INSTALL_OLLAMA="$(prompt 'Install it now? (Y/n): ')"
  if [[ "$INSTALL_OLLAMA" =~ ^([Yy]|)$ ]]; then
    # Official Linux installer
    curl -fsSL https://ollama.com/install.sh | sh
  else
    echo "Please install Ollama manually and re-run this script."
    exit 1
  fi
fi

# Start Ollama service if not running
if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
  echo "[info] Starting Ollama service..."
  nohup ollama serve >/dev/null 2>&1 &
  # give it a moment
  sleep 2
fi

echo
HAS_GPU="$(prompt 'Do you have an NVIDIA GPU? (Y/n): ')"
if [[ "$HAS_GPU" =~ ^[Yy]$ ]]; then
  echo "[note] High-performance models use more VRAM and power."
  USE_HEAVY="$(prompt 'Use high-performance models? (Y/n): ')"
  if [[ "$USE_HEAVY" =~ ^([Yy]|)$ ]]; then
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

echo "[info] Ensuring models are available..."
if ! ollama list | awk '{print $1}' | grep -qx "$ASK_MODEL"; then
  echo "[+] Pulling $ASK_MODEL..."
  ollama pull "$ASK_MODEL"
fi

if ! ollama list | awk '{print $1}' | grep -qx "$CODE_MODEL"; then
  echo "[+] Pulling $CODE_MODEL..."
  ollama pull "$CODE_MODEL"
fi

# Write launcher
cat > "$TARGET" <<EOF
#!/bin/bash
set -euo pipefail

PID_FILE="/tmp/ollama_pid"

start_ollama() {
  if pgrep -f "ollama serve" >/dev/null 2>&1; then
    echo "Serve Ollama already does. No need, there is."
  else
    echo "Waking up... your assistant is."
    nohup ollama serve >/dev/null 2>&1 &
    echo \$! > "\$PID_FILE" || true
    if [[ -f "\$PID_FILE" ]]; then
      echo "Started, it has. PID: \$(cat "\$PID_FILE")"
    else
      echo "Started, it has."
    fi
  fi
}

stop_ollama() {
  if [[ -f "\$PID_FILE" ]]; then
    PID=\$(cat "\$PID_FILE")
    echo "Sleep now... the force shall rest."
    kill "\$PID" 2>/dev/null || true
    rm -f "\$PID_FILE"
    echo "Dreamless, the silence is."
  else
    echo "Mmm. No PID file. Hunt the phantom process, we must..."
    pkill -f "ollama serve" >/dev/null 2>&1 && echo "Banished, the daemon is." || echo "No daemon found."
  fi
}

case "\${1:-}" in
  start) start_ollama ;;
  stop)  stop_ollama ;;
  ask)
    echo "Speak your thoughts. The Master listens..."
    exec ollama run $ASK_MODEL
    ;;
  code)
    echo "Ah, code we must. Clever, you are..."
    exec ollama run $CODE_MODEL
    ;;
  *)
    echo "Usage: yoda [start|stop|ask|code]"
    exit 1
    ;;
esac
EOF

chmod +x "$TARGET"

# PATH handling
ensure_path_line='export PATH="$HOME/.local/bin:$PATH"'
PATH_OK=0
case ":$PATH:" in
  *":$HOME/.local/bin:"*) PATH_OK=1 ;;
esac

if [[ $PATH_OK -ne 1 ]]; then
  echo
  echo "[warn] ~/.local/bin is not in your PATH."
  if [[ -f "$HOME/.bashrc" ]] || [[ -f "$HOME/.zshrc" ]]; then
    ADD_PATH="$(prompt 'Add it to your shell config now? (Y/n): ')"
    if [[ "$ADD_PATH" =~ ^([Yy]|)$ ]]; then
      if [[ -f "$HOME/.bashrc" ]]; then
        grep -qxF "$ensure_path_line" "$HOME/.bashrc" || echo "$ensure_path_line" >> "$HOME/.bashrc"
        echo "[✓] Added to .bashrc"
      fi
      if [[ -f "$HOME/.zshrc" ]]; then
        grep -qxF "$ensure_path_line" "$HOME/.zshrc" || echo "$ensure_path_line" >> "$HOME/.zshrc"
        echo "[✓] Added to .zshrc"
      fi
      echo "[i] Open a new terminal or run: source ~/.bashrc  or  source ~/.zshrc"
    fi
  else
    echo "[warn] No shell config found. Add to PATH manually:"
    echo "      $ensure_path_line"
  fi
fi

echo
echo "[✓] YODA-LLM installed to: $TARGET"
echo "Try: yoda start   | yoda ask   | yoda code   | yoda stop"
echo "Uninstall: re-run this installer and choose option 2"

