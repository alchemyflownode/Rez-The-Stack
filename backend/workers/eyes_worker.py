import asyncio
import ollama
import logging
from ddgs import DDGS

logger = logging.getLogger(__name__)

class EyesWorker:
    def __init__(self):
        self.name = "search"
        self.description = "Network Analysis and Web Search"
        # We default to llama3.2 here for fast text summarization, 
        # but llava:7b is great if you ever add image analysis!
        self.default_model = "llama3.2:latest" 

    async def process(self, task: str, model: str = None) -> dict:
        active_model = model or self.default_model
        logger.info(f"🌐 Eyes Worker initiating web sweep for: {task}")
        
        try:
            # 1. Perform the Live Web Search
            search_results_text = ""
            
            # Run the synchronous DuckDuckGo search in a background thread to prevent blocking
            def fetch_search():
                with DDGS() as ddgs:
                    return list(ddgs.text(task, max_results=3))
                    
            results = await asyncio.to_thread(fetch_search)
            
            if not results:
                return {"content": "⚠️ Web search executed, but no results were found."}

            # Format the live data
            for idx, r in enumerate(results):
                search_results_text += f"[{idx+1}] {r['title']}\n{r['body']}\n\n"

            # 2. Feed the Live Data to the Local AI to summarize
            prompt = f"""You are the Eyes Worker of REZ HIVE. You just performed a live web search.
            Based ONLY on the following live internet data, answer the user's prompt directly and concisely. 
            Do NOT say "I don't have real-time access" because the data is provided below.
            
            User Task: {task}
            
            Live Web Data:
            {search_results_text}
            """
            
            response = await asyncio.to_thread(
                ollama.chat,
                model=active_model,
                messages=[{"role": "user", "content": prompt}],
                options={"temperature": 0.3}
            )
            
            final_answer = response['message']['content'].strip()
            
            # Format nicely for the UI
            formatted_output = f"🌐 **LIVE WEB TELEMETRY INJECTED**\n\n{final_answer}\n\n---\n*Sources scanned:* \n"
            for r in results:
                formatted_output += f"- [{r['title']}]({r['href']})\n"
                
            return {"content": formatted_output}
            
        except Exception as e:
            logger.error(f"Eyes Worker Web Error: {e}")
            return {"content": f"⚠️ **CONNECTION FAILED**\n\n[!] Web search unavailable: {str(e)}\nEnsure `duckduckgo-search` is installed."}