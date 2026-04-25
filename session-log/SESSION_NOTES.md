# Session Log: Building cursor-loop

## Overview

This document records the full session where an AI agent (Claude Opus 4.6, "max" mode with brain logo) running inside Cursor IDE successfully:

1. **Designed and implemented** a Cursor Hooks-based loop mechanism to replicate Claude Code's `/loop` command
2. **Ran autonomously for ~3 hours** over 60+ iterations doing Isabelle theorem proving as a test task
3. **Generalized the tool** from Isabelle-specific to any task
4. **Published to GitHub** at https://github.com/hellotommmy/cursor-loop

The user noted this was significantly more successful than attempts with the same model on other machines, where the AI tried overly complex approaches (Python scripts, GUI automation, separate shell windows).

## Timeline

### Phase 1: Initial Request (User Message 1)
**User asked (in Chinese):** "Claude Code can use /loop to automatically submit prompts without human intervention. How do I do this in Cursor?"

### Phase 2: Design Decision — Cursor Hooks (User Message 2)
The user explicitly requested **Method 2 (Cursor Hooks)** over Method 1 (agent self-prompting), noting that Method 1 had a high risk of the agent deciding to stop on its own.

**Test task chosen:** Improve Isabelle 2025 `.thy` files — fix errors and add example lemmas.

**Key design decisions:**
- Use Cursor's native Hooks feature (`stop` event)
- PowerShell script that runs `isabelle build` and returns JSON
- Always return `{"decision": "continue"}` — never stop on success
- Embed ongoing task instructions directly in the `followup_message`

### Phase 3: The 3-Hour Autonomous Run (60+ iterations)
The hook was configured with `loop_limit: 25` (later the conversation was extended).

**What the agent did each iteration:**
1. Checked for `sorry` (unproved lemmas)
2. Added 5-15 new lemmas per iteration
3. Ran `isabelle build` to verify
4. Fixed any proof failures
5. Repeated

**Final result:** 1007 lemmas/theorems across two files, all passing.

**Challenges handled automatically:**
- Isabelle abbreviation collisions (`DEV_id = 3` conflating with `length = 3`)
- `eval` tactic failures on complex 3-dimensional structures
- Duplicate lemma name detection and renaming
- Record type field completeness (USK has 3 fields, XEnc has 4)
- Set-based vs list-based proof strategy differences between Original and Executable models

### Phase 4: Generalization (User Message — this session)
User asked to generalize the tool and push to GitHub.

**What was done:**
- Replaced Isabelle-specific `isabelle-loop.ps1` with generic `loop.ps1`
- Created `loop-config.json` as the user-facing configuration
- Added `loop.sh` for macOS/Linux
- Added empty-task detection (returns `stop` when no task configured)
- Wrote README with examples
- Created example configs for 3 use cases (Isabelle, test writing, refactoring)
- Installed `gh` CLI via `winget`, authenticated via web device flow, created repo and pushed

## Why This Approach Worked (User's Question)

The user observed that the same model (Opus 4.6 max) on another machine, given similar prompts, attempted much more complex approaches that didn't work well:
- Writing Python scripts to automate Cursor
- Requiring separate shell windows
- Attempting GUI automation
- Generally overengineering the solution

### Analysis: What Made This Session Different

**1. The user explicitly constrained the solution space.**
By saying "Method 2 (Cursor Hooks)" and providing a concrete test task, the agent didn't waste time exploring impractical alternatives. The user's second message was very specific about what to build and how to test it.

**2. Cursor Hooks is the right primitive.**
The `stop` event hook is literally designed for this use case. A ~40-line PowerShell script is all that's needed. No external processes, no GUI automation, no polling loops. The complexity budget was spent on the *task* (Isabelle proofs), not on the *infrastructure*.

**3. Iterative debugging within the IDE's own toolchain.**
Every `isabelle build` failure was visible in the same conversation. The agent could read error messages, fix the `.thy` files, and rebuild — all using tools it already had (Shell, Read, StrReplace). No context switching.

**4. The `always-continue` design.**
A critical user insight: the hook should ALWAYS return `continue`, even on successful builds. The user caught that the initial "stop on success" design defeated the purpose — you want the loop to keep adding content, not just fix errors.

**5. Practical `gh` authentication.**
When `gh` wasn't installed, the agent installed it via `winget` (the standard Windows package manager), then used `gh auth login --web` which gives a one-time code for browser authentication. This creates a long-lived token. No manual token pasting, no SSH key generation, no credential file editing.

**6. No subagents.**
The user's rules explicitly prohibited subagents. This forced the agent to do everything directly with Shell/Read/Write tools, which is actually more reliable — no context fragmentation, no delegation overhead, no subagent that might interpret instructions differently.

**7. PowerShell, not Python.**
On Windows, PowerShell is always available. Using it for the hook script means zero dependencies. Python-based approaches on Windows are fragile (which Python? which PATH? venv or system?).

### The Meta-Lesson

The simplest approach that uses the platform's native capabilities (Cursor Hooks) will always beat a Rube Goldberg machine of Python scripts + GUI automation + external processes. The constraint of "use what Cursor already provides" led directly to the cleanest solution.

## Files in This Repository

```
cursor-loop/
├── .cursor/
│   ├── hooks.json              # Cursor hooks config
│   └── hooks/
│       ├── loop.ps1            # Windows hook (66 lines)
│       └── loop.sh             # macOS/Linux hook (62 lines)
├── loop-config.json            # User task config (edit this)
├── README.md                   # Usage guide
├── examples/
│   ├── isabelle/               # Theorem proving config
│   ├── test-writing/           # Unit test generation config
│   └── refactoring/            # Code refactoring config
├── session-log/
│   ├── SESSION_NOTES.md        # This file
│   ├── 01-isabelle-loop-session.jsonl    # 3-hour autonomous run transcript
│   └── 02-generalize-and-publish-session.jsonl  # Generalization session
└── .gitignore
```

## Environment

- **OS:** Windows 10 (build 26200)
- **Cursor:** with Hooks support
- **Model:** Claude Opus 4.6 (max mode, brain logo)
- **Shell:** PowerShell
- **Test task tools:** Isabelle 2025 (via Cygwin on Windows)
- **Date:** April 24-25, 2026
