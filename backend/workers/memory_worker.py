"""
Memory Worker - Full PC search and persistent memory
Part of REZ HIVE sovereign AI system
"""

import os
import string
import asyncio
from pathlib import Path
from datetime import datetime
from typing import List, Dict, Any, Optional
import logging
import hashlib

logger = logging.getLogger(__name__)

class MemoryWorker:
    """
    Worker for PC-wide search and memory operations
    """
    
    def __init__(self):
        self.name = "files"  # Keep "files" for frontend compatibility
        self.description = "Full PC search and persistent memory"
        self.version = "1.0.0"
        self.chroma = None
        self.collection = None
        self.index_collection = None
        
        # Try to connect to ChromaDB
        try:
            import chromadb
            self.chroma = chromadb.HttpClient(host='localhost', port=8000)
            self.collection = self.chroma.get_or_create_collection("rez_hive_memory")
            # Try to get file index collection
            try:
                self.index_collection = self.chroma.get_collection("pc_file_index")
                logger.info("✅ MemoryWorker connected to ChromaDB + File Index available")
            except:
                logger.info("✅ MemoryWorker connected to ChromaDB (no file index yet)")
        except ImportError:
            logger.warning("⚠️ chromadb not installed - memory features disabled")
        except Exception as e:
            logger.warning(f"⚠️ MemoryWorker running without ChromaDB: {e}")

    async def search_entire_pc(self, query: str, max_results: int = 50) -> List[Dict]:
        """
        Search all drives for files matching query (fallback method)
        """
        results = []
        query_lower = query.lower()
        drives = []
        
        # Get all available drives on Windows
        if os.name == 'nt':
            for letter in string.ascii_uppercase:
                drive = f"{letter}:\\"
                if os.path.exists(drive):
                    drives.append(drive)
        else:
            drives = ['/']
        
        logger.info(f"🔍 Searching {len(drives)} drives for '{query}'")
        
        # Search each drive
        for drive in drives:
            try:
                for root, dirs, files in os.walk(drive):
                    # Skip system directories
                    if any(skip in root.lower() for skip in [
                        'windows', 'program files', '$recycle', 'system32', 
                        'node_modules', '.git', 'temp', 'tmp', 'cache', 
                        'appdata', 'winnt', 'msocache'
                    ]):
                        continue
                        
                    for file in files:
                        if query_lower in file.lower():
                            file_path = os.path.join(root, file)
                            try:
                                stat = os.stat(file_path)
                                results.append({
                                    'name': file,
                                    'path': file_path,
                                    'size': stat.st_size,
                                    'size_mb': stat.st_size / (1024 * 1024),
                                    'modified': datetime.fromtimestamp(stat.st_mtime).isoformat()[:10]
                                })
                                if len(results) >= max_results:
                                    return results
                            except:
                                continue
            except (PermissionError, OSError):
                continue
        
        return results[:max_results]

    async def search_index(self, query: str, max_results: int = 50) -> List[Dict]:
        """
        Search using pre-built ChromaDB index (instant)
        """
        if not self.chroma or not self.index_collection:
            return await self.search_entire_pc(query)
        
        try:
            results = self.index_collection.query(
                query_texts=[query],
                n_results=max_results
            )
            
            if results['metadatas'] and results['metadatas'][0]:
                return results['metadatas'][0]
        except Exception as e:
            logger.warning(f"Index search failed: {e}")
        
        return await self.search_entire_pc(query)

    async def list_drives(self) -> List[Dict]:
        """
        List all available drives with free space
        """
        drives = []
        if os.name == 'nt':
            import shutil
            for letter in string.ascii_uppercase:
                drive = f"{letter}:\\"
                if os.path.exists(drive):
                    try:
                        usage = shutil.disk_usage(drive)
                        drives.append({
                            'drive': drive,
                            'total_gb': round(usage.total / (1024**3), 1),
                            'used_gb': round(usage.used / (1024**3), 1),
                            'free_gb': round(usage.free / (1024**3), 1),
                            'used_percent': round((usage.used / usage.total) * 100, 1)
                        })
                    except:
                        drives.append({'drive': drive, 'error': 'Cannot read drive info'})
        else:
            # Linux/Mac
            try:
                import shutil
                usage = shutil.disk_usage('/')
                drives.append({
                    'drive': '/',
                    'total_gb': round(usage.total / (1024**3), 1),
                    'used_gb': round(usage.used / (1024**3), 1),
                    'free_gb': round(usage.free / (1024**3), 1),
                    'used_percent': round((usage.used / usage.total) * 100, 1)
                })
            except:
                drives.append({'drive': '/', 'note': 'Unix system'})
        
        return drives

    async def process(self, task: str, model: str = None) -> Dict[str, Any]:
        """
        Main entry point called by kernel.py
        """
        task_lower = task.lower().strip()
        
        # =========================================================
        # PC SEARCH COMMANDS - WITH INDEX SUPPORT
        # =========================================================
        if any(phrase in task_lower for phrase in [
            'search pc', 'search computer', 'find on pc', 'find file', 
            'locate file', 'search entire pc', 'find on computer',
            'find all', 'search for file'
        ]):
            # Extract search query
            query = task
            for phrase in ['search pc', 'search computer', 'find on pc', 'find file', 
                          'locate file', 'search entire pc', 'find on computer',
                          'find all', 'search for file', 'find', 'search', 'for']:
                query = query.lower().replace(phrase, '').strip()
            
            # Clean up extra words
            words_to_remove = ['named', 'called', 'with name', 'file', 'files']
            for word in words_to_remove:
                query = query.replace(word, '').strip()
            
            if not query or len(query) < 2:
                return {"content": """🔍 **What file are you looking for?**

**Examples:**
• `search pc budget.xlsx`
• `find invoice on computer`
• `locate report.docx`
• `search for python files`
• `find all .txt files`"""}

            # Use index if available, otherwise fallback to live search
            if self.index_collection:
                results = await self.search_index(query)
                search_method = "indexed"
            else:
                results = await self.search_entire_pc(query)
                search_method = "live"
            
            if results:
                response = f"🔍 **Found {len(results)} files matching '{query}'** ({search_method} search):\n\n"
                for i, r in enumerate(results[:15], 1):
                    # Format size appropriately
                    size_bytes = r.get('size', 0)
                    size_mb = r.get('size_mb', size_bytes / (1024 * 1024))
                    
                    if size_mb < 1:
                        size_str = f"{size_bytes / 1024:.1f} KB"
                    else:
                        size_str = f"{size_mb:.2f} MB"
                    
                    response += f"{i}. 📄 **{r['name']}**\n"
                    response += f"   📍 `{r['path']}`\n"
                    response += f"   📏 {size_str}\n"
                    response += f"   📅 Modified: {r.get('modified', 'unknown')}\n\n"
                
                if len(results) > 15:
                    response += f"*...and {len(results)-15} more files*\n"
                
                if search_method == "live":
                    response += "\n💡 *Tip: Run `python system_indexer.py` to build an index for instant searches*"
                
                return {"content": response}
            else:
                return {"content": f"❌ **No files found** matching '{query}'\n\nTry:\n• Using a shorter filename\n• Checking spelling\n• Searching for partial names (e.g., 'budget' instead of 'budget.xlsx')"}
        
        # =========================================================
        # LIST DRIVES
        # =========================================================
        elif any(phrase in task_lower for phrase in [
            'list drives', 'show drives', 'disk space', 'free space',
            'storage', 'drives', 'drive list'
        ]):
            drives = await self.list_drives()
            
            response = "💾 **Available Drives:**\n\n"
            total_free = 0
            total_size = 0
            
            for d in drives:
                if isinstance(d, dict):
                    if 'error' in d:
                        response += f"📁 **{d['drive']}** - {d['error']}\n\n"
                    elif 'note' in d:
                        response += f"📁 **{d['drive']}** - {d['note']}\n\n"
                    else:
                        response += f"📁 **{d['drive']}**\n"
                        response += f"   💾 {d['free_gb']} GB free of {d['total_gb']} GB\n"
                        response += f"   📊 {d['used_percent']}% used\n\n"
                        if isinstance(d['free_gb'], (int, float)):
                            total_free += d['free_gb']
                        if isinstance(d['total_gb'], (int, float)):
                            total_size += d['total_gb']
            
            if len(drives) > 1 and total_size > 0:
                response += f"**Total:** {total_free:.1f} GB free of {total_size:.1f} GB total"
            
            return {"content": response}
        
        # =========================================================
        # CHROMA DB MEMORY OPERATIONS
        # =========================================================
        elif task_lower.startswith("remember "):
            if not self.chroma:
                return {"content": "⚠️ **ChromaDB is offline.** Cannot store memories.\n\nStart it with:\n`chroma run --path ./chroma_data --port 8000`"}
            
            content = task[8:].strip()  # Remove "remember "
            if not content:
                return {"content": "What would you like me to remember?\n\nExample: `remember my server IP is 192.168.1.5`"}
            
            # Create a unique ID
            doc_id = f"mem_{hashlib.md5(content.encode()).hexdigest()[:12]}"
            
            # Store in ChromaDB
            self.collection.add(
                documents=[content],
                metadatas=[{
                    "timestamp": datetime.now().isoformat(),
                    "type": "user_memory",
                    "source": "chat"
                }],
                ids=[doc_id]
            )
            
            return {"content": f"💾 **Stored in persistent memory:**\n> {content}\n\n*Memory ID: `{doc_id}`*"}
        
        elif task_lower.startswith("recall ") or "search memory" in task_lower:
            if not self.chroma:
                return {"content": "⚠️ **ChromaDB is offline.** Cannot recall memories."}
            
            # Extract query
            query = task_lower.replace("recall", "").replace("search memory", "").strip()
            if not query:
                return {"content": "What would you like me to recall?\n\nExample: `recall API key`"}
            
            # Search ChromaDB
            results = self.collection.query(
                query_texts=[query],
                n_results=5
            )
            
            if results['documents'] and results['documents'][0]:
                formatted = "📚 **Found in memory:**\n\n"
                for i, doc in enumerate(results['documents'][0], 1):
                    formatted += f"{i}. {doc}\n"
                return {"content": formatted}
            else:
                return {"content": f"No memories found matching '{query}'"}
        
        # =========================================================
        # LIST FILES (Current Directory)
        # =========================================================
        elif task_lower == "list files" or task_lower == "/list_files":
            try:
                files = os.listdir(".")[:25]
                formatted = "📁 **Current Directory Contents:**\n\n"
                
                # Separate directories and files
                dirs = []
                file_list = []
                
                for f in files:
                    if os.path.isdir(f):
                        dirs.append(f)
                    else:
                        file_list.append(f)
                
                # Show directories first
                for d in sorted(dirs):
                    formatted += f"📂 `{d}/`\n"
                
                # Then files
                for f in sorted(file_list):
                    try:
                        size = os.path.getsize(f) / 1024
                        if size < 1:
                            size_str = f"{os.path.getsize(f)} bytes"
                        else:
                            size_str = f"{size:.1f} KB"
                        formatted += f"📄 `{f}` ({size_str})\n"
                    except:
                        formatted += f"📄 `{f}`\n"
                
                return {"content": formatted}
            except Exception as e:
                return {"content": f"File error: {e}"}
        
        # =========================================================
        # DEFAULT RESPONSE
        # =========================================================
        else:
            return {
                "content": """🧠 **Memory Worker Online**

**Available Commands:**

🔍 **PC SEARCH**
• `search pc [filename]` - Find files anywhere
• `find [name] on computer` - Alternative syntax
• `locate [filename]` - Search entire PC

💾 **DRIVE INFO**
• `list drives` - Show all drives with free space
• `disk space` - Check available storage

📚 **MEMORY** (requires ChromaDB)
• `remember [info]` - Store in memory
• `recall [topic]` - Search memory

📁 **CURRENT FOLDER**
• `/list_files` - View current directory

**Examples:**
• `search pc budget.xlsx`
• `find invoice on computer`
• `list drives`
• `remember my API key is 12345`
• `recall API key`

*Note: For online questions like "what is Python?" use the Brain Worker (default)*"""
            }

# For direct testing
if __name__ == "__main__":
    import asyncio
    
    async def test():
        worker = MemoryWorker()
        
        print("\n" + "="*60)
        print("🧠 Testing Memory Worker")
        print("="*60)
        
        # Test drives
        print("\n📁 Testing: list drives")
        result = await worker.process("list drives")
        print(result['content'][:500] + "...\n")
        
        # Test search
        print("\n🔍 Testing: search pc *.txt")
        result = await worker.process("search pc *.txt")
        print(result['content'][:500] + "...\n")
        
        print("="*60)
        print("✅ Test complete")
        print("="*60)
    
    asyncio.run(test())