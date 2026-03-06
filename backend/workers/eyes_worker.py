"""
Eyes Worker - Web search and network analysis
"""

import aiohttp
import asyncio
import logging

logger = logging.getLogger(__name__)

class EyesWorker:
    def __init__(self):
        self.name = "eyes"
        self.description = "Web search and network analysis"
    
    async def search_duckduckgo(self, query: str) -> str:
        """Search using DuckDuckGo API"""
        try:
            async with aiohttp.ClientSession() as session:
                params = {
                    'q': query,
                    'format': 'json',
                    'no_html': 1,
                    'skip_disambig': 1,
                    't': 'rez_hive'
                }
                async with session.get('https://api.duckduckgo.com/', params=params, timeout=8) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        results = []
                        
                        if data.get('AbstractText'):
                            results.append(f"## {data.get('AbstractTitle', 'Summary')}")
                            results.append(data['AbstractText'])
                        
                        if data.get('RelatedTopics'):
                            results.append("\n## Related")
                            for topic in data['RelatedTopics'][:5]:
                                if 'Text' in topic:
                                    results.append(f"• {topic['Text']}")
                        
                        return "\n\n".join(results) if results else "No results found"
            return "Search unavailable"
        except Exception as e:
            return f"Search error: {e}"
    
    async def process(self, task: str, model: str = None) -> dict:
        """Process search queries"""
        if "search" in task.lower() or "look up" in task.lower():
            results = await self.search_duckduckgo(task)
            return {"content": results}
        return {"content": "Eyes worker ready. Try 'search for...'"}
