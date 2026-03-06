"""
System Indexer - Pre-scans your entire PC into ChromaDB for instant search
Run this once to build the index, then searches are instantaneous
"""

import os
import sys
import asyncio
import hashlib
import argparse
from datetime import datetime
from pathlib import Path
import logging

# Set up logging
logging.basicConfig(
    level=logging.INFO, 
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

try:
    import chromadb
    from chromadb.config import Settings
except ImportError:
    logger.error("❌ chromadb not installed. Run: pip install chromadb")
    sys.exit(1)

class SystemIndexer:
    """
    Indexes your entire PC into ChromaDB for instant search
    """
    
    def __init__(self, reset=False):
        self.chroma = None
        self.collection = None
        self.total_files = 0
        self.indexed_files = 0
        self.skipped_dirs = [
            'windows', 'program files', '$recycle', 'system32', 
            'node_modules', '.git', 'cache', 'temp', 'tmp',
            'appdata', 'winnt', 'msocache', 'config.msi',
            'programdata', 'perflogs', 'recovery'
        ]
        
        # Connect to ChromaDB
        try:
            self.chroma = chromadb.HttpClient(
                host='localhost', 
                port=8000,
                settings=Settings(anonymized_telemetry=False)
            )
            
            # Delete existing collection if reset
            if reset:
                try:
                    self.chroma.delete_collection("pc_file_index")
                    logger.info("🗑️ Deleted existing index")
                except Exception as e:
                    logger.warning(f"Could not delete existing index: {e}")
            
            # Create or get collection
            self.collection = self.chroma.get_or_create_collection(
                name="pc_file_index",
                metadata={"hnsw:space": "cosine"}
            )
            logger.info("✅ Connected to ChromaDB")
            
        except Exception as e:
            logger.error(f"❌ Failed to connect to ChromaDB: {e}")
            logger.error("Make sure ChromaDB is running: chroma run --path ./chroma_data --port 8000")
            sys.exit(1)
    
    def get_drives(self):
        """Get all available drives"""
        drives = []
        if os.name == 'nt':
            import string
            for letter in string.ascii_uppercase:
                drive = f"{letter}:\\"
                if os.path.exists(drive):
                    drives.append(drive)
        else:
            drives = ['/']
        return drives
    
    def should_skip_path(self, path):
        """Check if path should be skipped"""
        path_lower = path.lower()
        for skip in self.skipped_dirs:
            if skip in path_lower:
                return True
        return False
    
    def index_file(self, file_path):
        """Index a single file in ChromaDB"""
        try:
            stat = os.stat(file_path)
            
            # Create a unique ID based on path
            file_id = hashlib.md5(file_path.encode()).hexdigest()[:16]
            
            # Prepare metadata
            metadata = {
                'name': os.path.basename(file_path),
                'path': file_path,
                'size': stat.st_size,
                'size_mb': round(stat.st_size / (1024 * 1024), 2),
                'modified': datetime.fromtimestamp(stat.st_mtime).isoformat()[:19],
                'extension': os.path.splitext(file_path)[1].lower(),
                'parent': os.path.dirname(file_path)
            }
            
            # Add to ChromaDB (document is the filename for search)
            self.collection.add(
                documents=[os.path.basename(file_path)],
                metadatas=[metadata],
                ids=[file_id]
            )
            
            self.indexed_files += 1
            if self.indexed_files % 1000 == 0:
                logger.info(f"   Indexed {self.indexed_files:,} files...")
                
        except Exception as e:
            # Skip files we can't access
            pass
    
    async def scan_drive(self, drive):
        """Scan a single drive and index files"""
        logger.info(f"📁 Scanning {drive}...")
        
        for root, dirs, files in os.walk(drive, topdown=True):
            # Filter system directories
            dirs[:] = [d for d in dirs if not self.should_skip_path(os.path.join(root, d))]
            
            # Check if we should skip this path
            if self.should_skip_path(root):
                continue
            
            for file in files:
                file_path = os.path.join(root, file)
                self.total_files += 1
                
                # Index the file
                self.index_file(file_path)
                
                # Small delay every 5000 files to prevent overwhelming the system
                if self.total_files % 5000 == 0:
                    await asyncio.sleep(0.01)
    
    async def run(self, quick=False):
        """Run the full indexing process"""
        start_time = datetime.now()
        logger.info("=" * 60)
        logger.info("🔍 REZ HIVE System Indexer")
        logger.info("=" * 60)
        
        # Get drives
        drives = self.get_drives()
        logger.info(f"Found {len(drives)} drives: {', '.join(drives)}")
        
        if quick:
            # Quick mode - only index user folders
            if os.name == 'nt':
                try:
                    user = os.getlogin()
                    user_profile = os.path.expanduser("~")
                    drives = [
                        os.path.join(user_profile, "Documents"),
                        os.path.join(user_profile, "Desktop"),
                        os.path.join(user_profile, "Downloads"),
                        os.path.join(user_profile, "Pictures"),
                    ]
                    # Only include folders that exist
                    drives = [d for d in drives if os.path.exists(d)]
                    logger.info(f"Quick mode: Scanning user folders only")
                except Exception as e:
                    logger.warning(f"Could not get user folders: {e}")
        
        # Scan each drive/folder
        for drive in drives:
            if os.path.exists(drive):
                try:
                    await self.scan_drive(drive)
                except Exception as e:
                    logger.warning(f"Error scanning {drive}: {e}")
            else:
                logger.warning(f"Drive not found: {drive}")
        
        # Get collection stats
        try:
            count = self.collection.count()
        except:
            count = self.indexed_files
        
        elapsed = (datetime.now() - start_time).total_seconds()
        
        logger.info("=" * 60)
        logger.info(f"✅ Indexing complete!")
        logger.info(f"   Files processed: {self.total_files:,}")
        logger.info(f"   Files indexed: {self.indexed_files:,}")
        logger.info(f"   Collection size: {count:,} entries")
        logger.info(f"   Time elapsed: {elapsed:.1f} seconds")
        logger.info("=" * 60)
        
        return count

async def main():
    parser = argparse.ArgumentParser(description='Index your PC for instant search')
    parser.add_argument('--quick', action='store_true', help='Quick mode - only user folders')
    parser.add_argument('--reset', action='store_true', help='Reset existing index')
    args = parser.parse_args()
    
    logger.info("🚀 Starting System Indexer...")
    
    # Check if ChromaDB is running
    import socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    result = sock.connect_ex(('127.0.0.1', 8000))
    sock.close()
    
    if result != 0:
        logger.error("❌ ChromaDB is not running on port 8000")
        logger.error("   Start it with: chroma run --path ./chroma_data --port 8000")
        return
    
    # Run indexer
    indexer = SystemIndexer(reset=args.reset)
    await indexer.run(quick=args.quick)

if __name__ == "__main__":
    asyncio.run(main())