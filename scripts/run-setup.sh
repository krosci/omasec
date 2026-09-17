#!/bin/bash

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG="$PROJECT_DIR/setup.log"

echo "Log in corso: $LOG"
echo ""

sudo bash "$SCRIPT_DIR/setup.sh"
