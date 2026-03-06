from fastapi import FastAPI
import uvicorn

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Test kernel working"}

if __name__ == "__main__":
    print("="*50)
    print("Test Kernel")
    print("="*50)
    uvicorn.run(app, host="0.0.0.0", port=8001)
