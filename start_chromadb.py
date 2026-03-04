import chromadb
from chromadb.config import Settings

client = chromadb.PersistentClient(
    path="./chroma_data",
    settings=Settings(
        chroma_server_http_port=8000,
        chroma_server_host="localhost"
    )
)

print("✅ ChromaDB server running on http://localhost:8000")
print("Press Ctrl+C to stop")

# Keep the script running
import time
while True:
    time.sleep(1)
