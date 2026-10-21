#!/bin/zsh
set -eu
cd "$(dirname "$0")"
if [[ ! -x .venv/bin/python ]]; then
  python3 -m venv .venv
fi
.venv/bin/python -m pip install -q -r requirements.txt
if [[ ! -f .env ]]; then
  cp .env.example .env
  chmod 600 .env
fi
.venv/bin/python scripts/serve.py
