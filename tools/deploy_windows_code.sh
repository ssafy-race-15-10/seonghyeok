#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/aws-windows-t3"
KEY_PATH="${AWS_WINDOWS_KEY:-$HOME/.ssh/aws-windows}"
REMOTE_DIR="C:/ssafy-race/Bot_Java"

if [[ ! -f "$KEY_PATH" ]]; then
  echo "missing SSH key: $KEY_PATH" >&2
  exit 1
fi

PUBLIC_IP="$(terraform -chdir="$TF_DIR" output -raw public_ip)"
SSH_TARGET="Administrator@$PUBLIC_IP"
SSH_OPTS=(-i "$KEY_PATH" -o StrictHostKeyChecking=accept-new -o ServerAliveInterval=15)

ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "powershell -NoProfile -Command \"New-Item -ItemType Directory -Force '$REMOTE_DIR' | Out-Null\""

scp "${SSH_OPTS[@]}" \
  "$ROOT_DIR/Bot_Java/MyCar.java" \
  "$ROOT_DIR/Bot_Java/TestRunner.java" \
  "$SSH_TARGET:$REMOTE_DIR/"

scp "${SSH_OPTS[@]}" -r \
  "$ROOT_DIR/Bot_Java/DrivingInterface" \
  "$SSH_TARGET:$REMOTE_DIR/"

ssh "${SSH_OPTS[@]}" "$SSH_TARGET" "powershell -NoProfile -Command \"cd '$REMOTE_DIR'; if (Get-Command javac -ErrorAction SilentlyContinue) { javac MyCar.java TestRunner.java; Write-Host 'Java compile OK' } else { Write-Host 'javac not found; copied files only' }\""

echo "Deployed local Bot_Java sources to $SSH_TARGET:$REMOTE_DIR"
