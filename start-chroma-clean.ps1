# start-chroma-clean.ps1
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "REZ HIVE Memory Server" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

$pythonCode = @'
import chromadb
import time

print("Starting ChromaDB Memory Server...")
print(f"Version: {chromadb.__version__}")

# Create persistent client
client = chromadb.PersistentClient(path='./chroma_data')

# List existing collections
collections = client.list_collections()
print(f"Found {len(collections)} collections:")

for col in collections:
    print(f"  • {col.name}: {col.count()} vectors")

# Ensure main collection exists
collection = client.get_or_create_collection("rez_hive_memory")
print(f"Memory collection ready: {collection.count()} vectors")

print("\nServer running. Press Ctrl+C to stop")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\nShutting down...")
'@

# Execute the Python code
python -c "$pythonCode"