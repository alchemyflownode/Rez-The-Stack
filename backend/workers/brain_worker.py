"""
Brain Worker - General reasoning with Llama 3.2
"""

import ollama
import asyncio
import aiohttp
import logging

logger = logging.getLogger(__name__)

class BrainWorker:
    def __init__(self):
        self.name = "brain"
        self.description = "General reasoning and chat with online search"
        self.model = "llama3.2:latest"
    
    async def search_online(self, query: str) -> str:
        """Search online for factual grounding via DuckDuckGo"""
        try:
            async with aiohttp.ClientSession() as session:
                params = {
                    'q': query, 
                    'format': 'json', 
                    'no_html': 1, 
                    'skip_disambig': 1,
                    't': 'rez_hive'
                }
                async with session.get('https://api.duckduckgo.com/', params=params, timeout=5) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        results = []
                        
                        if data.get('AbstractText'):
                            results.append(f"**{data.get('AbstractTitle', 'Summary')}**\n{data['AbstractText']}")
                        
                        if data.get('RelatedTopics'):
                            results.append("\n**Related Information:**")
                            for topic in data['RelatedTopics'][:3]:
                                if 'Text' in topic:
                                    results.append(f"• {topic['Text'][:200]}")
                        
                        if results:
                            return "\n\n".join(results)
            return ""
        except Exception as e:
            logger.warning(f"Search error: {e}")
            return ""
    
    async def process(self, task: str, model: str = None) -> dict:
        """Process with automatic online grounding"""
        model_to_use = model or self.model
        task_lower = task.lower()
        
        # Auto-detect if search is needed
        needs_search = any([
            'search for' in task_lower, 'look up' in task_lower,
            'what is' in task_lower and '?' in task,
            'who is' in task_lower, 'latest' in task_lower,
            'news' in task_lower, 'current' in task_lower
        ])
        
        if needs_search:
            search_results = await self.search_online(task)
            if search_results:
                grounded_prompt = f"""Use these search results to answer:
{search_results}

Question: {task}
Answer:"""
                response = ollama.chat(
                    model=model_to_use,
                    messages=[{"role": "user", "content": grounded_prompt}],
                    stream=False,
                )
                return {
                    "content": f"{response['message']['content']}\n\n*🔍 Sourced from DuckDuckGo*"
                }
        
        # Standard response
        response = ollama.chat(
            model=model_to_use,
            messages=[{"role": "user", "content": task}],
            stream=False,
        )
        return {"content": response["message"]["content"]}
