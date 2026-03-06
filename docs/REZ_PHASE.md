# REZ PHASE MANIFEST

## Current Phase: 4 (Execution)
**Status:** Active Development
**Focus:** Bridging thought to action via Python workers.

### Locked Decisions (Do Not Change)
1. **Structured Output Only:** All workers must return JSON. No free-text streams.
2. **Local Sovereignty:** All primary processing happens locally via Ollama/Python.
3. **No Unverified Kills:** `allow_process_kill` defaults to `false` in config.

### Pending Validations
- [ ] Verify `system_agent.py` stability under heavy load.
- [ ] Confirm `search_harvester.py` image sanitization (prevent broken images in UI).
- [ ] Test `rez.config.json` hot-reloading (future feature).

### Architectural Rationale
- **Why 4 images?** Balanced for mobile-view grid (2x2) without clutter.
- **Why DuckDuckGo?** No API keys required; preserves sovereignty.
- **Why `psutil`?** Cross-platform standard for system vitals.

### Known Constraints
- Windows-only for process management (expand later)
- Requires Python 3.8+
- Ollama must be running for AI features
