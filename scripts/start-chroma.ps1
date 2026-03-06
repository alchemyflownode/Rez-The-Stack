# start-chroma.ps1
Write-Host "🏛️ Starting ChromaDB Memory Server..." -ForegroundColor Cyan
$pythonPath = "C:\Users\Zphoenix\AppData\Local\Programs\Python\Python310\python.exe"
& $pythonPath -c @"
import chromadb
import time
print('ChromaDB version:', chromadb.__version__)
client = chromadb.PersistentClient(path='./chroma_data')
print('Memory server ready')
print('Press Ctrl+C to stop')
try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print('\nShutting down...')
"@
