# Cognitive Kernel Setup Guide

## Quick Start

### 1. Start Ollama
```bash
ollama serve
```

### 2. Create the Root-Seeker Model (Optional - for baked-in constitution)
```bash
cd /home/z/my-project/download
ollama create rootseeker -f Modelfile
```

### 3. Run the App
The Next.js app is already running at `localhost:3000`

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    COGNITIVE KERNEL                              │
│                                                                  │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐    │
│  │   EPISTEMIC    │  │  REFLECTION    │  │    PATTERN     │    │
│  │    PROMPTS     │→ │     LOOPS      │→ │    MEMORY      │    │
│  │                │  │                │  │     (RAG)      │    │
│  │ "Think in      │  │ "Self-check    │  │ "Store &       │    │
│  │  layers"       │  │  reasoning"    │  │  retrieve"     │    │
│  └────────────────┘  └────────────────┘  └────────────────┘    │
│           │                  │                   │              │
│           └──────────────────┼───────────────────┘              │
│                              │                                  │
│                              ▼                                  │
│                    ┌────────────────┐                          │
│                    │ TRIGGER CHAIN  │                          │
│                    │                │                          │
│                    │ Loop until:    │                          │
│                    │ • Root found   │                          │
│                    │ • Confidence   │                          │
│                    │   >= 0.8       │                          │
│                    │ • Or max iter  │                          │
│                    └────────────────┘                          │
│                              │                                  │
│                              ▼                                  │
│                    ┌────────────────┐                          │
│                    │    OLLAMA      │                          │
│                    │  (Local LLM)   │                          │
│                    └────────────────┘                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## The Chaining Loop

```
TASK INPUT
    │
    ▼
┌─────────────┐
│   THINK     │ ◄── Generate thought using epistemic framework
└─────────────┘
    │
    ▼
┌─────────────┐
│  REFLECT    │ ◄── Self-evaluate: Which layer? Done?
└─────────────┘
    │
    ▼
┌─────────────┐
│   CHAIN?    │ ◄── Continue or stop?
└─────────────┘
    │
    ├── NO ──► DONE (Extract patterns)
    │
    ▼ YES
    │
    └──────► Loop back to THINK
```

---

## Key Files

| File | Purpose |
|------|---------|
| `src/lib/cognitive-kernel.ts` | Epistemic prompts, constitution, types |
| `src/app/api/kernel/route.ts` | Ollama connector + chaining loop |
| `src/app/page.tsx` | UI for running chains |
| `download/Modelfile` | Ollama model with baked-in constitution |

---

## Environment Variables

```bash
# In .env
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2
```

---

## What Makes This Different

### Traditional AI Chat:
```
User asks → AI answers → Done
```

### Cognitive Kernel:
```
User asks → AI thinks → AI reflects → AI decides → Loop until truly done
                                              │
                                              ▼
                                    Pattern extracted for future use
```

The key difference: **Self-reflection and chaining** until the task is actually complete at the root level.

---

## Pattern Memory

Every chain run:
1. Extracts transferable patterns
2. Stores in database
3. Future chains can reference these patterns

This enables **ever-deductive learning** — each run makes the kernel smarter.

---

## Testing

1. Open `localhost:3000`
2. Make sure Ollama status shows "connected"
3. Enter a task like: "What's the root of effective learning?"
4. Click "Run Chain"
5. Watch the kernel think, reflect, and chain until it finds the root
