# Claude Tools Setup — What's Installed, Why, and How to Save Tokens

## What's Installed

| Tool | Version | Purpose |
|------|---------|---------|
| Claude Code CLI | 2.1.150 | Interactive AI coding assistant in terminal |
| Anthropic Python SDK | 0.104.1 | Build Claude-powered Python apps |
| Anthropic Node SDK | latest | Build Claude-powered Node/TS apps |
| CLAUDE.md | — | Workspace context file (saves tokens) |
| settings.json | — | Permissions allowlist (fewer prompts) |
| Memory system | — | Persistent knowledge across sessions |

---

## Token-Saving Strategies

### 1. CLAUDE.md (Biggest Token Saver)

**What:** A markdown file at the root of your workspace that Claude Code reads automatically at the start of every conversation.

**Why it saves tokens:** Without it, you'd re-explain your setup, conventions, and project structure every session. CLAUDE.md gives Claude instant context — no back-and-forth questions.

**Location:** `~/coding/CLAUDE.md`

**What's in ours:**
- Your identity and skills
- Machine setup (mise, chezmoi, tools)
- Repo locations
- Key commands and conventions
- Theme preferences

**How to maintain it:**
```bash
# Edit directly
v ~/coding/CLAUDE.md

# Or via chezmoi if you want it tracked
chezmoi add ~/coding/CLAUDE.md
```

**Pro tip:** Keep it under 100 lines. Long CLAUDE.md files waste tokens being loaded every turn. Put details in linked files or memory instead.

---

### 2. Permissions Allowlist (Fewer Interruptions = Fewer Tokens)

**What:** Pre-approved commands that Claude Code can run without asking you.

**Why it saves tokens:** Every permission prompt requires a round-trip (Claude asks, you approve, Claude continues). The allowlist eliminates prompts for safe read-only commands.

**Location:** `~/.claude/settings.json`

**What we've allowed:**
```
Read-only commands:
  git status, git diff, git log, git branch, git show
  ls, find, grep, cat, head, tail, wc, which, echo, pwd, du, df
  
Tool-specific:
  mise *, chezmoi *
  gh auth status, gh repo list, gh pr list
  python3 --version, node --version, go version
  npm list, pip show, pip list
  
All file reads:
  Read (the dedicated read tool)
```

**How to add more:**
```bash
v ~/.claude/settings.json
# Add to the "allow" array:
# "Bash(npm test*)"        — allow test runs
# "Bash(docker ps*)"       — allow docker status checks
# "Bash(pytest*)"          — allow pytest
```

---

### 3. Memory System (Don't Repeat Yourself)

**What:** Persistent files that Claude reads in future conversations to remember who you are, your preferences, and project context.

**Why it saves tokens:** Instead of re-explaining "I prefer Catppuccin Mocha" or "my repos are at ~/coding/SathishKumarAI/" every session, Claude already knows.

**Location:** `~/.claude/projects/-home-deva-coding/memory/`

**Current memories:**
- `user_github_profile.md` — Your GitHub profile, repo landscape, tech stack

**How to add memories:**
```
# In any Claude Code conversation, just say:
"Remember that I prefer single PRs over many small ones"
"Remember that RAG project uses ChromaDB not FAISS"

# Claude saves it automatically to the memory directory
```

**How to check/edit memories:**
```bash
ls ~/.claude/projects/-home-deva-coding/memory/
cat ~/.claude/projects/-home-deva-coding/memory/MEMORY.md
```

---

### 4. Per-Project CLAUDE.md Files

**What:** You can put a CLAUDE.md in any project directory for project-specific context.

**Why:** When you `cd` into a project and start Claude Code, it reads that project's CLAUDE.md automatically. The project CLAUDE.md layers on top of the workspace one.

**Example for your RAG project:**
```bash
cat > ~/coding/SathishKumarAI/RAG/CLAUDE.md << 'EOF'
# RAG Project Context
- Uses LangChain + ChromaDB for vector storage
- Python 3.12, managed by mise
- Tests: pytest
- Run: python -m src.main
EOF
```

---

### 5. Compact Conversations

**Tips to use fewer tokens per session:**

| Do | Don't |
|----|-------|
| Give specific file paths | Say "find the config file" |
| Say "edit line 42 of src/main.py" | Say "change that function we talked about" |
| Use `/clear` between unrelated tasks | Let context grow unbounded |
| Use short prompts for simple tasks | Write paragraphs for one-line fixes |
| Reference CLAUDE.md conventions | Re-explain your preferences |

---

## Anthropic Python SDK

**Why installed:** Build Claude-powered Python apps. Used in your RAG, LLM, and AI projects.

**Quick test:**
```python
import anthropic

client = anthropic.Anthropic()  # reads ANTHROPIC_API_KEY env var

message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello!"}]
)
print(message.content[0].text)
```

**With prompt caching (saves tokens on repeated context):**
```python
message = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1024,
    system=[{
        "type": "text",
        "text": "You are a medical research assistant...",
        "cache_control": {"type": "ephemeral"}  # cache this
    }],
    messages=[{"role": "user", "content": "Summarize this paper..."}]
)
```

**Set your API key:**
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
# Or add to ~/.bashrc:
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
```

---

## Anthropic Node SDK

**Why installed:** Build Claude-powered TypeScript/Node apps. Used in your web projects.

**Quick test:**
```typescript
import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();  // reads ANTHROPIC_API_KEY env var

const message = await client.messages.create({
  model: "claude-sonnet-4-6",
  max_tokens: 1024,
  messages: [{ role: "user", content: "Hello!" }],
});
console.log(message.content[0].text);
```

---

## Claude Code CLI — Key Commands

| Command | What | Saves Tokens? |
|---------|------|---------------|
| `/clear` | Clear conversation context | Yes — reset token count |
| `/compact` | Summarize conversation to save context | Yes — compresses history |
| `/cost` | Show token usage for this session | Monitor spending |
| `/help` | Show all commands | — |
| `/init` | Create CLAUDE.md for current project | Yes — future context |
| `/review` | Review a PR | — |
| `/fast` | Toggle fast mode (same model, faster output) | Same tokens, faster |
| `claude --resume` | Resume last conversation | Reuses context |
| `claude -p "prompt"` | One-shot prompt (no interactive session) | Minimal tokens |

---

## MCP Servers (Available)

Your Claude Code has these MCP integrations available (need auth):

| Server | Status | Purpose |
|--------|--------|---------|
| Gmail | Needs auth | Read/send email from Claude |
| Google Calendar | Needs auth | Check/create calendar events |
| Google Drive | Needs auth | Read/search Drive files |

To authenticate:
```
# In Claude Code conversation:
"Connect to my Gmail"
"Set up Google Calendar access"
```

---

## File Locations Summary

```
~/.claude/
├── settings.json              # Permissions, theme
├── .credentials.json          # Auth (don't touch)
├── history.jsonl              # Command history
├── mcp-needs-auth-cache.json  # MCP server state
└── projects/
    └── -home-deva-coding/
        └── memory/
            ├── MEMORY.md                # Memory index
            └── user_github_profile.md   # Your profile

~/coding/
├── CLAUDE.md                  # Workspace context (auto-loaded)
└── rocky-dev-setup/
    └── CLAUDE_TOOLS_GUIDE.md  # This file
```
