// src/workers/memory-worker.ts
import { ChromaClient } from 'chromadb';
import { spawn } from 'child_process';
import path from 'path';

export class MemoryWorker {
  private client: ChromaClient;
  private collection: any;
  private initialized: boolean = false;
  
  constructor() {
    this.client = new ChromaClient({
      path: "http://localhost:8000"  // Connect to running ChromaDB
    });
    this.initCollection();
  }
  
  async initCollection() {
    try {
      // Try to get or create the REZ HIVE memory collection
      this.collection = await this.client.getOrCreateCollection({
        name: "rez_hive_memory",
        metadata: { 
          "hnsw:space": "cosine",
          "description": "REZ HIVE Sovereign Memory"
        }
      });
      this.initialized = true;
      console.log('✅ Memory Worker connected to ChromaDB');
      
      // Check how many memories we have
      const count = await this.collection.count();
      console.log(`📊 Total memories: ${count}`);
      
    } catch (error) {
      console.error('❌ Failed to connect to ChromaDB:', error.message);
      console.log('⚠️  Running in fallback mode');
      this.initialized = false;
    }
  }
  
  async remember(content: string, metadata: any = {}) {
    const timestamp = Date.now();
    const id = `mem_${timestamp}`;
    
    // Generate embedding using sentence-transformers
    const embedding = await this.generateEmbedding(content);
    
    try {
      if (this.initialized && this.collection) {
        // Store in ChromaDB
        await this.collection.add({
          ids: [id],
          embeddings: [embedding],
          documents: [content],
          metadatas: [{
            ...metadata,
            timestamp,
            type: metadata.type || 'memory'
          }]
        });
        
        const count = await this.collection.count();
        return {
          success: true,
          id,
          count,
          content: `✅ Memory stored (ID: ${id})`
        };
      } else {
        // Fallback mode
        return {
          success: true,
          id,
          fallback: true,
          content: `📝 Memory noted (would store in ChromaDB if running)`
        };
      }
    } catch (error) {
      console.error('Failed to store memory:', error);
      return {
        success: false,
        error: error.message,
        content: `❌ Failed to store memory: ${error.message}`
      };
    }
  }
  
  async recall(query: string, nResults: number = 5) {
    try {
      if (!this.initialized || !this.collection) {
        return {
          success: true,
          fallback: true,
          memories: [],
          content: "💭 ChromaDB not running. Start it with: python -m chromadb run --path ./chroma_data --port 8000"
        };
      }
      
      // Generate embedding for query
      const queryEmbedding = await this.generateEmbedding(query);
      
      // Search similar memories
      const results = await this.collection.query({
        queryEmbeddings: [queryEmbedding],
        nResults: nResults,
        include: ["documents", "metadatas", "distances"]
      });
      
      const memories = results.documents[0] || [];
      const distances = results.distances[0] || [];
      const metadatas = results.metadatas[0] || [];
      
      // Format memories with relevance scores
      const formatted = memories.map((mem: string, i: number) => ({
        content: mem,
        relevance: Math.round((1 - distances[i]) * 100),
        timestamp: metadatas[i]?.timestamp || 'unknown',
        id: results.ids[0]?.[i] || 'unknown'
      }));
      
      return {
        success: true,
        memories: formatted,
        count: formatted.length,
        content: formatted.length > 0 
          ? `🔍 Found ${formatted.length} relevant memories`
          : "🤔 No relevant memories found"
      };
      
    } catch (error) {
      console.error('Failed to recall memories:', error);
      return {
        success: false,
        error: error.message,
        memories: [],
        content: `❌ Failed to recall: ${error.message}`
      };
    }
  }
  
  private generateEmbedding(text: string): Promise<number[]> {
    return new Promise((resolve, reject) => {
      const pythonProcess = spawn('python', [
        path.join(__dirname, 'embed.py'),
        text
      ]);
      
      let output = '';
      let errorOutput = '';
      
      pythonProcess.stdout.on('data', (data) => {
        output += data.toString();
      });
      
      pythonProcess.stderr.on('data', (data) => {
        errorOutput += data.toString();
      });
      
      pythonProcess.on('close', (code) => {
        if (code === 0 && output) {
          try {
            const embedding = JSON.parse(output.trim());
            resolve(embedding);
          } catch (e) {
            reject(new Error('Failed to parse embedding'));
          }
        } else {
          reject(new Error(`Embedding failed: ${errorOutput}`));
        }
      });
    });
  }
  
  async getStats() {
    try {
      if (!this.initialized || !this.collection) {
        return {
          initialized: false,
          totalMemories: 0,
          collections: []
        };
      }
      
      const count = await this.collection.count();
      const collections = await this.client.listCollections();
      
      return {
        initialized: true,
        totalMemories: count,
        collections: collections.map(c => ({
          name: c.name,
          count: c.count
        }))
      };
      
    } catch (error) {
      return {
        initialized: false,
        error: error.message,
        totalMemories: 0
      };
    }
  }
}