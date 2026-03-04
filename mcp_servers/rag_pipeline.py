# rag_pipeline.py
import sys
import json
import os
from pathlib import Path
from typing import List, Dict, Any
import chromadb
from sentence_transformers import SentenceTransformer
import pypdf
import docx
import markdown

class RAGPipeline:
    def __init__(self):
        self.chroma_client = chromadb.PersistentClient(path="./chroma_data")
        self.embedder = SentenceTransformer('all-MiniLM-L6-v2')
        self.collection = self.chroma_client.get_or_create_collection(
            name="documents",
            metadata={"hnsw:space": "cosine"}
        )
        self.doc_path = Path("./documents")
        self.doc_path.mkdir(exist_ok=True)
    
    def extract_text(self, file_path: Path) -> str:
        if file_path.suffix.lower() == '.pdf':
            reader = pypdf.PdfReader(file_path)
            return '\n'.join([page.extract_text() for page in reader.pages])
        elif file_path.suffix.lower() == '.docx':
            doc = docx.Document(file_path)
            return '\n'.join([para.text for para in doc.paragraphs])
        elif file_path.suffix.lower() == '.md':
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
        else:
            with open(file_path, 'r', encoding='utf-8') as f:
                return f.read()
    
    def index_document(self, file_path: str, chunk_size: int = 500):
        path = Path(file_path)
        if not path.exists():
            return {"error": "File not found"}
        
        text = self.extract_text(path)
        chunks = [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]
        
        ids = []
        embeddings = []
        documents = []
        metadatas = []
        
        for i, chunk in enumerate(chunks):
            chunk_id = f"{path.stem}_{i}"
            ids.append(chunk_id)
            documents.append(chunk)
            metadatas.append({
                "source": path.name,
                "chunk": i,
                "total_chunks": len(chunks)
            })
            embeddings.append(self.embedder.encode(chunk).tolist())
        
        self.collection.add(
            ids=ids,
            embeddings=embeddings,
            documents=documents,
            metadatas=metadatas
        )
        
        return {
            "success": True,
            "chunks": len(chunks),
            "file": path.name
        }
    
    def query(self, question: str, n_results: int = 3) -> Dict[str, Any]:
        query_embedding = self.embedder.encode(question).tolist()
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results
        )
        
        contexts = []
        if results['documents']:
            for doc in results['documents'][0]:
                contexts.append(doc[:500])
        
        return {
            "success": True,
            "contexts": contexts,
            "count": len(contexts)
        }
    
    def list_documents(self) -> List[str]:
        return [str(f) for f in self.doc_path.iterdir() if f.is_file()]

rag = RAGPipeline()

def handle_request(request):
    method = request.get('method', '')
    params = request.get('params', {})
    
    if method == 'index_document':
        return rag.index_document(params.get('file_path', ''))
    elif method == 'query':
        return rag.query(params.get('question', ''), params.get('n_results', 3))
    elif method == 'list_documents':
        return {'documents': rag.list_documents()}
    
    return {'error': f'Unknown method: {method}'}

if __name__ == '__main__':
    sys.stderr.write("RAG Pipeline Server Running\n")
    while True:
        try:
            line = sys.stdin.readline()
            if not line: break
            request = json.loads(line)
            response = handle_request(request)
            sys.stdout.write(json.dumps(response) + '\n')
            sys.stdout.flush()
        except Exception as e:
            sys.stdout.write(json.dumps({'error': str(e)}) + '\n')
            sys.stdout.flush()
