#!/usr/bin/env python3
"""Start the same-origin phone UI + Python API on the local network."""
import os
from pathlib import Path
import socket
import sys
import uvicorn
from dotenv import load_dotenv
ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(ROOT))
load_dotenv(ROOT/'.env')
port=int(os.getenv('APP_PORT','8000'))
print(f'Computer preview: http://127.0.0.1:{port}')
try:
    sock=socket.socket(socket.AF_INET,socket.SOCK_DGRAM)
    sock.connect(('192.0.2.1',80))
    address=sock.getsockname()[0]
    sock.close()
    print(f'Phone (same Wi-Fi): http://{address}:{port}')
except OSError:
    print('Find your Wi-Fi IPv4 address in System Settings → Wi-Fi → Details → TCP/IP.')
print('Local coursework demo only. No login. Use fictional data and a trusted network.')
uvicorn.run('app.main:app',host='0.0.0.0',port=port)
