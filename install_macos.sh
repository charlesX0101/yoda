#!/bin/bash

#==================================================
# YODA-LLM INSTALLER (macOS)
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

#--- Welcome ---#
echo "============================================="
echo "     Welcome to YODA-LLM!"
echo "  Your Offline Dialogue Assistant (macOS)"
echo "============================================="
echo
echo "1) Install YODA-LLM"
echo "2) Uninstall YODA-LLM"
echo "3) Quit"
echo
CHOICE="$(prompt 'Choose an option [1-3]: ')"

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

#--- Check for Homebrew ---#
if ! command -v brew &>/dev/null; then
  echo "[warn] Homebrew is not installed."
  INSTALL_BREW="$(prompt 'Install Homebrew now? (Y/n): ')"
  if [[ "$INSTALL_BREW" =~ ^([Yy]|)$ ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Please install Homebrew manually and re-run this script."
    exit 1
  fi
fi

#--- Check for Ollama ---#
if ! command -v ollama &>/dev/null; then
  echo "[info] Installing Ollama with Homebrew..."
  brew install ollama
fi

#--- Start Ollama Service ---#
if ! pgrep -f "ollama serve" > /dev/null; then
  echo "[info] Starting Ollama service..."
  nohup ollama serve >/dev/null 2>&1 &
  sleep 2
fi

#--- Use Lightweight Models by Default ---#
ASK_MODEL="llama3:8b"
CODE_MODEL="deepseek-coder:6.7b"
echo "[info] Using lightweight models optimized for macOS:"
echo "       ASK_MODEL = $ASK_MODEL"
echo "       CODE_MODEL = $CODE_MODEL"

#--- Pull Models ---#
echo "[info] Ensuring models are available..."
if ! ollama list | awk '{print $1}' | grep -qx "$ASK_MODEL"; then
  echo "[+] Pulling $ASK_MODEL..."
  # keep original behavior: trigger download by running once
  ollama run "$ASK_MODEL" <<< "Hello" || {
    echo "[error] Failed to load $ASK_MODEL"
    exit 1
  }
fi

if ! ollama list | awk '{print $1}' | grep -qx "$CODE_MODEL"; then
  echo "[+] Pulling $CODE_MODEL..."
  # keep original behavior: trigger download by running once
  ollama run "$CODE_MODEL" <<< "Hello" || {
    echo "[error] Failed to load $CODE_MODEL"
    exit 1
  }
fi

#--- Deploy Yoda Script ---#
cat > "$TARGET" <<EOF
#!/bin/bash
set -euo pipefail

PID_FILE="/tmp/ollama_pid"

start_ollama() {
  if pgrep -f "ollama serve" > /dev/null; then
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
  start)
    start_ollama
    ;;
  stop)
    stop_ollama
    ;;
  ask)
    echo "Speak your thoughts. The Master listens..."
    exec ollama run $ASK_MODEL
    ;;
  code)
    echo "Ah, code we must. Clever, you are..."
    exec ollama run $CODE_MODEL
    ;;
  *)
    echo "Hmm. Use wisely: yoda [start|stop|ask|code]"
    exit 1
    ;;
esac
EOF

chmod +x "$TARGET"

#--- Zsh PATH Handling ---#
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
  echo
  echo "[warn] ~/.local/bin is not in your PATH."
  if [[ -f "$HOME/.zshrc" ]]; then
    ADD_PATH="$(prompt 'Add it to PATH in .zshrc? (Y/n): ')"
    if [[ "$ADD_PATH" =~ ^([Yy]|)$ ]]; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
      echo "[✓] Added to ~/.zshrc"
      echo "Restart your terminal or run: source ~/.zshrc"
    fi
  else
    echo "[info] Creating ~/.zshrc and adding PATH..."
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    echo "[✓] Created and updated ~/.zshrc"
    echo "Restart your terminal or run: source ~/.zshrc"
  fi
fi

#--- Done ---#
echo
echo "[✓] YODA-LLM installed to: $TARGET"
echo "Try it: yoda start | yoda ask | yoda code | yoda stop"
echo "Uninstall anytime: ./install_macos.sh and select option 2"

