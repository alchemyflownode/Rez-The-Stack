# chroma_server.py - CORRECTED VERSION FOR RUNNING A SERVER
import chromadb
from chromadb.config import Settings
import uvicorn
import sys
import os

print("="*50)
print("REZ HIVE Memory Server")
print("="*50)

try:
    # 1. Define configuration
    # persist_directory ensures data is saved to disk
    settings = Settings(
        chroma_server_host="localhost",
        chroma_server_http_port=8000,
        persist_directory="./chroma_data",
        anonymized_telemetry=False
    )
    
    # 2. Import the FastAPI application wrapper
    # This creates the actual server app that listens on ports
    from chromadb.server.fastapi import FastAPI as ChromaFastAPI
    
    # 3. Initialize the app with settings
    app = ChromaFastAPI(settings)
    
    print(f"✅ ChromaDB version: {chromadb.__version__}")
    print(f"🌐 Server running on http://localhost:8000")
    print(f"💾 Persisting data to: {os.path.abspath('./chroma_data')}")
    print("\n" + "="*50)
    print("Press Ctrl+C to stop")
    print("="*50)
    
    # 4. Run the server with Uvicorn
    # This blocks and keeps the server running
    uvicorn.run(app, host="0.0.0.0", port=8000)
    
except KeyboardInterrupt:
    print("\n👋 Shutting down...")
    sys.exit(0)
except Exception as e:
    print(f"\n❌ Error: {e}")
    print("\n⚠️ NOTE: Make sure you have installed the server dependencies:")
    print("   pip install chromadb-server uvicorn")
    sys.exit(1)