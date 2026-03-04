# src/workers/embed.py
from sentence_transformers import SentenceTransformer
import sys
import json

# Load model once (this is cached)
model = SentenceTransformer('all-MiniLM-L6-v2')

def generate_embedding(text):
    embedding = model.encode(text).tolist()
    print(json.dumps(embedding))

if __name__ == "__main__":
    text = sys.argv[1]
    generate_embedding(text)
